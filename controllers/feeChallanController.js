const FeeChallan = require('../models/FeeChallan');
const Student = require('../models/Student');
const Family = require('../models/Family');
const { generateChallanPDF, generateReceiptPDF } = require('../utils/pdfGenerator');

const canAccessChallan = (req, challan) => {
  if (req.role === 'admin') return true;
  if (req.role === 'parent') {
    const familyIdStr = challan.familyId && challan.familyId._id
      ? challan.familyId._id.toString()
      : challan.familyId.toString();
    return familyIdStr === req.user._id.toString();
  }
  return false;
};

exports.createChallan = async (req, res) => {
  try {
    const { studentId, month, year, otherCharges = [], dueDate } = req.body;

    const student = await Student.findById(studentId);
    if (!student) {
      return res.status(404).json({ success: false, message: 'Student not found' });
    }

    const existingChallan = await FeeChallan.findOne({ studentId, month, year });
    if (existingChallan) {
      return res.status(400).json({
        success: false,
        message: `Challan already exists for this student for month ${month}/${year}`,
      });
    }

    const tuitionFee = student.monthlyTuitionFee || 0;
    const discountPercentage = student.discountPercentage || 0;
    const discountAmount = (tuitionFee * discountPercentage) / 100;
    const otherChargesTotal = otherCharges.reduce((sum, c) => sum + (Number(c.amount) || 0), 0);
    const totalPayable = tuitionFee - discountAmount + otherChargesTotal;

    const isPastDue = dueDate && new Date(dueDate) < new Date();
    const initialStatus = isPastDue ? 'Overdue' : 'Pending';

    const challan = await FeeChallan.create({
      studentId,
      familyId: student.familyId,
      month,
      year,
      tuitionFee,
      otherCharges,
      discountPercentage,
      discountAmount,
      totalPayable,
      dueDate,
      status: initialStatus,
    });

    res.status(201).json({ success: true, data: challan });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.generateBulkChallans = async (req, res) => {
  try {
    const { month, year, dueDate, familyId } = req.body;

    const filter = { status: 'active' };
    if (familyId) filter.familyId = familyId;

    const activeStudents = await Student.find(filter);
    if (activeStudents.length === 0) {
      return res.status(404).json({ success: false, message: 'No active students found' });
    }

    const createdChallans = [];
    const skippedStudents = [];

    for (const student of activeStudents) {
      const exists = await FeeChallan.findOne({ studentId: student._id, month, year });
      if (exists) {
        skippedStudents.push(student.fullName);
        continue;
      }

      const tuitionFee = student.monthlyTuitionFee || 0;
      const discountPercentage = student.discountPercentage || 0;
      const discountAmount = (tuitionFee * discountPercentage) / 100;
      const totalPayable = tuitionFee - discountAmount;

      const challan = await FeeChallan.create({
        studentId: student._id,
        familyId: student.familyId,
        month,
        year,
        tuitionFee,
        discountPercentage,
        discountAmount,
        totalPayable,
        dueDate,
        status: 'Pending',
      });

      createdChallans.push(challan);
    }

    res.status(201).json({
      success: true,
      message: `Generated ${createdChallans.length} challans successfully.`,
      skipped: skippedStudents,
      data: createdChallans,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.autoGenerateMonthlyChallans = async (req, res) => {
  try {
    const now = new Date();
    const month = now.getMonth() + 1;
    const year = now.getFullYear();
    const dueDate = new Date(year, month - 1, 25);

    const students = await Student.find({ status: 'active' });
    if (students.length === 0) {
      return res.status(404).json({ success: false, message: 'No active students found' });
    }

    let created = 0;
    let skipped = 0;
    const createdChallans = [];

    for (const student of students) {
      const exists = await FeeChallan.findOne({ studentId: student._id, month, year });
      if (exists) {
        skipped++;
        continue;
      }

      const tuitionFee = student.monthlyTuitionFee || 0;
      const discountPercentage = student.discountPercentage || 0;
      const discountAmount = (tuitionFee * discountPercentage) / 100;
      const totalPayable = tuitionFee - discountAmount;

      const challan = await FeeChallan.create({
        studentId: student._id,
        familyId: student.familyId,
        month,
        year,
        tuitionFee,
        discountPercentage,
        discountAmount,
        totalPayable,
        dueDate,
        status: dueDate < now ? 'Overdue' : 'Pending',
        otherCharges: [],
      });

      created++;
      createdChallans.push(challan);
    }

    res.status(201).json({
      success: true,
      message: `${created} challans generated, ${skipped} already existed.`,
      created,
      skipped,
      data: createdChallans,
    });
  } catch (error) {
    console.error('autoGenerateMonthlyChallans error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getChallans = async (req, res) => {
  try {
    const { status, month, year, familyId, studentId } = req.query;
    const filter = {};

    if (status) filter.status = status;
    if (month) filter.month = Number(month);
    if (year) filter.year = Number(year);
    if (studentId) filter.studentId = studentId;

    if (req.role === 'parent') {
      filter.familyId = req.user._id;
    } else if (familyId) {
      filter.familyId = familyId;
    }

    const currentDate = new Date();
    await FeeChallan.updateMany(
      { status: 'Pending', dueDate: { $lt: currentDate } },
      { $set: { status: 'Overdue' } }
    );

    const challans = await FeeChallan.find(filter)
      .populate('studentId', 'fullName rollNumber className')
      .populate('familyId', 'familyName familyCode primaryPhone')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: challans.length, data: challans });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getChallanById = async (req, res) => {
  try {
    const challan = await FeeChallan.findById(req.params.id)
      .populate('studentId')
      .populate('familyId');

    if (!challan) {
      return res.status(404).json({ success: false, message: 'Challan not found' });
    }

    if (!canAccessChallan(req, challan)) {
      return res.status(403).json({ success: false, message: 'Access denied: not your challan' });
    }

    res.status(200).json({ success: true, data: challan });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.recordPayment = async (req, res) => {
  try {
    const { paidAmount, paymentMethod } = req.body;

    const challan = await FeeChallan.findById(req.params.id);
    if (!challan) {
      return res.status(404).json({ success: false, message: 'Challan not found' });
    }

    const newPaidAmount = (challan.paidAmount || 0) + Number(paidAmount);
    challan.paidAmount = newPaidAmount;
    challan.paymentMethod = paymentMethod || 'Cash';
    challan.paidDate = new Date();

    if (newPaidAmount >= challan.totalPayable) {
      challan.status = 'Paid';
    } else if (newPaidAmount > 0) {
      challan.status = 'Partial';
    }

    await challan.save();

    res.status(200).json({ success: true, data: challan });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.updateChallan = async (req, res) => {
  try {
    const { otherCharges, dueDate } = req.body;
    const challan = await FeeChallan.findById(req.params.id);

    if (!challan) {
      return res.status(404).json({ success: false, message: 'Challan not found' });
    }

    if (otherCharges) {
      challan.otherCharges = otherCharges;
      const otherChargesTotal = otherCharges.reduce((sum, c) => sum + (Number(c.amount) || 0), 0);
      challan.totalPayable = challan.tuitionFee - challan.discountAmount + otherChargesTotal;
    }

    if (dueDate) challan.dueDate = dueDate;

    await challan.save();
    res.status(200).json({ success: true, data: challan });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.deleteChallan = async (req, res) => {
  try {
    const challan = await FeeChallan.findByIdAndDelete(req.params.id);
    if (!challan) {
      return res.status(404).json({ success: false, message: 'Challan not found' });
    }
    res.status(200).json({ success: true, message: 'Challan deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.downloadChallanPDF = async (req, res) => {
  try {
    const challan = await FeeChallan.findById(req.params.id)
      .populate('studentId')
      .populate('familyId');

    if (!challan) {
      return res.status(404).json({ success: false, message: 'Challan not found' });
    }

    if (!canAccessChallan(req, challan)) {
      return res.status(403).json({ success: false, message: 'Access denied: not your challan' });
    }

    generateChallanPDF(res, {
      family: challan.familyId,
      student: challan.studentId,
      challan,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.downloadReceiptPDF = async (req, res) => {
  try {
    const challan = await FeeChallan.findById(req.params.id)
      .populate('studentId')
      .populate('familyId');

    if (!challan) {
      return res.status(404).json({ success: false, message: 'Challan not found' });
    }

    if (!canAccessChallan(req, challan)) {
      return res.status(403).json({ success: false, message: 'Access denied: not your challan' });
    }

    if (challan.status !== 'Paid' && challan.status !== 'Partial') {
      return res.status(400).json({ success: false, message: 'Challan is not paid yet' });
    }

    generateReceiptPDF(res, {
      family: challan.familyId,
      student: challan.studentId,
      challan,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.applyPenaltyOnOverdue = async (req, res) => {
  try {
    const { penaltyAmount = 500 } = req.body;
    const today = new Date();

    const overdueChallans = await FeeChallan.find({
      status: { $in: ['Pending', 'Overdue'] },
      dueDate: { $lt: today },
      penaltyApplied: { $ne: true },
    });

    let updatedCount = 0;
    for (const c of overdueChallans) {
      c.penaltyAmount = (c.penaltyAmount || 0) + penaltyAmount;
      c.totalPayable = c.totalPayable + penaltyAmount;
      c.status = 'Overdue';
      c.penaltyApplied = true;
      await c.save();
      updatedCount++;
    }

    res.status(200).json({
      success: true,
      message: `Penalty applied on ${updatedCount} challans.`,
      updatedCount,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getDashboardSummary = async (req, res) => {
  try {
    const challans = await FeeChallan.find();

    const summary = {
      totalChallans: challans.length,
      paid: challans.filter((c) => c.status === 'Paid').length,
      pending: challans.filter((c) => c.status === 'Pending').length,
      overdue: challans.filter((c) => c.status === 'Overdue').length,
      partial: challans.filter((c) => c.status === 'Partial').length,
      totalRevenue: challans.reduce((sum, c) => sum + (c.paidAmount || 0), 0),
      totalPendingAmount: challans
        .filter((c) => c.status !== 'Paid')
        .reduce((sum, c) => sum + (c.totalPayable - (c.paidAmount || 0)), 0),
    };

    res.status(200).json({ success: true, data: summary });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};