const Student = require('../models/Student');
const Family = require('../models/Family');
const FeeChallan = require('../models/FeeChallan');
const Staff = require('../models/Staff');

// GET /api/dashboard/summary
const getDashboardSummary = async (req, res) => {
  try {
    if (req.role === 'admin') {
      const totalStudents = await Student.countDocuments();
      const totalFamilies = await Family.countDocuments();
      const totalStaff = await Staff.countDocuments();

      const challans = await FeeChallan.find().lean();
      const today = new Date();

      let paidCount = 0;
      let pendingCount = 0;
      let overdueCount = 0;

      let paidAmount = 0;
      let pendingAmount = 0;
      let overdueAmount = 0;

      challans.forEach((c) => {
        // ✅ FIX: .lean() ki wajah se virtuals (netPayable/amount) kaam nahi karte,
        // isliye seedha 'totalPayable' (real schema field) use karein
        const net = Number(c.totalPayable ?? 0);
        const paid = Number(c.paidAmount ?? (c.status === 'Paid' ? net : 0));
        const status = (c.status || 'Pending').toString();

        if (status === 'Paid') {
          paidCount += 1;
          paidAmount += paid > 0 ? paid : net;
        } else if (status === 'Overdue' || (c.dueDate && new Date(c.dueDate) < today && status !== 'Paid')) {
          overdueCount += 1;
          const remaining = Math.max(net - paid, 0);
          overdueAmount += remaining > 0 ? remaining : net;
          pendingAmount += remaining > 0 ? remaining : net;
        } else {
          pendingCount += 1;
          const remaining = Math.max(net - paid, 0);
          pendingAmount += remaining > 0 ? remaining : net;
        }
      });

      const feeStatusSummary = {
        paid: { count: paidCount, amount: paidAmount },
        pending: { count: pendingCount, amount: pendingAmount - overdueAmount },
        overdue: { count: overdueCount, amount: overdueAmount },
      };

      const payload = {
        success: true,
        totalStudents,
        totalFamilies,
        totalStaff,
        totalRevenueCollected: paidAmount,
        totalPendingAmount: pendingAmount,
        feeStatusSummary,
        data: {
          totalStudents,
          totalFamilies,
          totalStaff,
          totalRevenueCollected: paidAmount,
          totalPendingAmount: pendingAmount,
          feeStatusSummary,
        },
      };

      return res.status(200).json(payload);
    }

    if (req.role === 'teacher') {
      const assignedClasses = req.user.assignedClasses || [];

      const totalStudents = await Student.countDocuments({ className: { $in: assignedClasses } });

      const classWiseBreakdown = {};
      for (const cls of assignedClasses) {
        classWiseBreakdown[cls] = await Student.countDocuments({ className: cls });
      }

      return res.status(200).json({
        success: true,
        totalStudents,
        totalFamilies: 0,
        totalStaff: 0,
        totalRevenueCollected: 0,
        totalPendingAmount: 0,
        data: {
          role: 'teacher',
          assignedClasses,
          totalStudents,
          classWiseBreakdown,
        },
      });
    }

    if (req.role === 'parent') {
      const children = await Student.find({ familyId: req.user._id });

      const challans = await FeeChallan.find({ familyId: req.user._id }).lean();

      let paidAmount = 0;
      let pendingAmount = 0;
      let overdueCount = 0;
      const today = new Date();

      challans.forEach((c) => {
        // ✅ FIX: same as above — totalPayable directly use karein
        const net = Number(c.totalPayable ?? 0);
        const paid = Number(c.paidAmount ?? (c.status === 'Paid' ? net : 0));
        const status = (c.status || 'Pending').toString();

        if (status === 'Paid') {
          paidAmount += paid > 0 ? paid : net;
        } else {
          const remaining = Math.max(net - paid, 0);
          pendingAmount += remaining;
          if (status === 'Overdue' || (c.dueDate && new Date(c.dueDate) < today)) {
            overdueCount += 1;
          }
        }
      });

      return res.status(200).json({
        success: true,
        totalStudents: children.length,
        totalFamilies: 1,
        totalStaff: 0,
        totalRevenueCollected: paidAmount,
        totalPendingAmount: pendingAmount,
        data: {
          role: 'parent',
          totalChildren: children.length,
          children: children.map((c) => ({ id: c._id, name: c.fullName, className: c.className })),
          totalPaidAmount: paidAmount,
          totalPendingAmount: pendingAmount,
          overdueChallanCount: overdueCount,
        },
      });
    }

    return res.status(403).json({ success: false, message: 'Invalid role' });
  } catch (error) {
    console.error('getDashboardSummary error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/dashboard/revenue-trend (Admin only)
const getRevenueTrend = async (req, res) => {
  try {
    const now = new Date();
    const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    const trend = [];

    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const monthNum = d.getMonth() + 1;
      const year = d.getFullYear();
      const monthName = monthNames[d.getMonth()];

      const start = new Date(year, d.getMonth(), 1);
      const end = new Date(year, d.getMonth() + 1, 0, 23, 59, 59, 999);

      const challans = await FeeChallan.find({
        $or: [
          { issueDate: { $gte: start, $lte: end } },
          { createdAt: { $gte: start, $lte: end } }
        ],
        status: 'Paid'
      }).lean();

      let amount = 0;
      challans.forEach((c) => {
        // ✅ FIX: totalPayable directly use karein (virtual bypass)
        amount += Number(c.paidAmount ?? c.totalPayable ?? 0);
      });

      trend.push({
        month: monthNum,
        monthName: monthName,
        year: year,
        amount: amount,
        label: `${monthName} ${year}`
      });
    }

    return res.status(200).json({
      success: true,
      data: trend
    });
  } catch (error) {
    console.error('getRevenueTrend error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// GET /api/dashboard/salary-summary (Admin only)
const getSalarySummary = async (req, res) => {
  try {
    const staffList = await Staff.find().lean();
    let totalBase = 0;
    staffList.forEach((s) => {
      totalBase += Number(s.baseSalary ?? s.basicSalary ?? 0);
    });

    return res.status(200).json({
      success: true,
      data: {
        totalStaff: staffList.length,
        totalMonthlySalaryBudget: totalBase,
      }
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getDashboardSummary,
  getRevenueTrend,
  getSalarySummary,
};