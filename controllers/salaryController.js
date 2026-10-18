const Staff = require('../models/Staff');
const Salary = require('../models/Salary');

// GET /api/salaries - Fetch salary records linked to real staff
const getSalaries = async (req, res) => {
  try {
    const staffList = await Staff.find().lean();
    const salaries = await Salary.find().sort({ createdAt: -1 }).lean();

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    const formatted = salaries.map((s) => {
      // ✅ FIX: Sirf staffId se proper match karein — koi guesswork/hardcoded naam nahi
      let matchedStaff = null;
      if (s.staffId) {
        const idStr = (typeof s.staffId === 'object' && s.staffId._id)
          ? s.staffId._id.toString()
          : s.staffId.toString();
        matchedStaff = staffList.find((st) => st._id.toString() === idStr);
      }

      // ✅ Agar match nahi mila, to "Unknown/Deleted Staff" dikhayein — galat data assign na karein
      const realName = matchedStaff ? matchedStaff.fullName : '[Deleted/Unknown Staff]';
      const realDesig = matchedStaff ? (matchedStaff.designation || 'Teacher') : 'N/A';
      const realStaffId = matchedStaff ? matchedStaff._id : s.staffId;

      const mNum = parseInt(s.month) || new Date().getMonth() + 1;
      const monthLabel = (mNum >= 1 && mNum <= 12) ? monthNames[mNum - 1] : monthNames[new Date().getMonth()];
      const yearVal = s.year || new Date().getFullYear();

      return {
        _id: s._id,
        staffId: realStaffId,
        staffName: realName,
        staffDesignation: realDesig,
        month: s.month || String(new Date().getMonth() + 1),
        year: yearVal,
        formattedDate: `${monthLabel} ${yearVal}`,
        baseSalary: Number(s.baseSalary || matchedStaff?.baseSalary || matchedStaff?.basicSalary || 0),
        bonus: Number(s.bonus || 0),
        deductions: Number(s.deductions || 0),
        netSalary: Number(s.netSalary || s.baseSalary || 0),
        status: s.status || 'Paid',
        paymentMethod: s.paymentMethod || 'Cash',
        createdAt: s.createdAt || new Date(),
      };
    });

    return res.status(200).json({
      success: true,
      data: formatted,
    });
  } catch (error) {
    console.error('Error in getSalaries:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// POST /api/salaries - Generate new salary slip
const generateSalary = async (req, res) => {
  try {
    const {
      staffId,
      month,
      year,
      baseSalary,
      bonus = 0,
      deductions = 0,
      status = 'Paid',
      paymentMethod = 'Cash',
      remarks,
    } = req.body;

    if (!staffId) {
      return res.status(400).json({ success: false, message: 'Staff ID is required' });
    }

    const staffObj = await Staff.findById(staffId);
    if (!staffObj) {
      return res.status(404).json({ success: false, message: 'Staff member not found' });
    }

    const base = Number(baseSalary || staffObj.baseSalary || staffObj.basicSalary || 0);
    const bon = Number(bonus || 0);
    const ded = Number(deductions || 0);
    const netSalary = base + bon - ded;

    const currentYear = year ? Number(year) : new Date().getFullYear();
    const formattedMonth = month ? month.toString() : (new Date().getMonth() + 1).toString();

    const newSalary = await Salary.create({
      staffId: staffObj._id,
      month: formattedMonth,
      year: currentYear,
      baseSalary: base,
      bonus: bon,
      deductions: ded,
      netSalary,
      status,
      paymentMethod,
      remarks: remarks || `Salary for ${formattedMonth}/${currentYear}`,
      paymentDate: status === 'Paid' ? new Date() : null,
    });

    return res.status(201).json({
      success: true,
      data: {
        ...newSalary.toObject(),
        staffName: staffObj.fullName,
        staffDesignation: staffObj.designation,
      },
    });
  } catch (error) {
    console.error('Error in generateSalary:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/salaries/:id
const getSalaryById = async (req, res) => {
  try {
    const salary = await Salary.findById(req.params.id).lean();
    if (!salary) {
      return res.status(404).json({ success: false, message: 'Salary record not found' });
    }
    return res.status(200).json({ success: true, data: salary });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/salaries/:id
const deleteSalary = async (req, res) => {
  try {
    const salary = await Salary.findByIdAndDelete(req.params.id);
    if (!salary) {
      return res.status(404).json({ success: false, message: 'Salary record not found' });
    }
    return res.status(200).json({ success: true, message: 'Salary record deleted' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getSalaries,
  generateSalary,
  getSalaryById,
  deleteSalary,
};