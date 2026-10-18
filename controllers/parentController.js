const Student = require('../models/Student');
const FeeChallan = require('../models/FeeChallan');
const Attendance = require('../models/Attendance');
const Result = require('../models/Result');
const Notification = require('../models/Notification');

const verifyOwnChild = async (studentId, familyId) => {
  return await Student.findOne({ _id: studentId, familyId });
};

exports.getMyProfile = async (req, res) => {
  res.status(200).json({ success: true, data: req.user });
};

exports.getMyChildren = async (req, res) => {
  try {
    const students = await Student.find({ familyId: req.user._id });
    res.status(200).json({ success: true, count: students.length, data: students });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getChildChallans = async (req, res) => {
  try {
    const student = await verifyOwnChild(req.params.studentId, req.user._id);
    if (!student) {
      return res.status(403).json({ success: false, message: 'This student does not belong to your family' });
    }

    const challans = await FeeChallan.find({ studentId: student._id }).sort({ year: -1, month: -1 });
    res.status(200).json({ success: true, count: challans.length, data: challans });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getChildAttendance = async (req, res) => {
  try {
    const student = await verifyOwnChild(req.params.studentId, req.user._id);
    if (!student) {
      return res.status(403).json({ success: false, message: 'This student does not belong to your family' });
    }

    const records = await Attendance.find({ type: 'student', refId: student._id }).sort({ date: -1 });
    res.status(200).json({ success: true, count: records.length, data: records });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getChildResults = async (req, res) => {
  try {
    const student = await verifyOwnChild(req.params.studentId, req.user._id);
    if (!student) {
      return res.status(403).json({ success: false, message: 'This student does not belong to your family' });
    }

    const results = await Result.find({ studentId: student._id })
      .populate('examId', 'examName examType examDate academicYear')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: results.length, data: results });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc Get notifications relevant to parents
// @route GET /api/parent/notifications
exports.getMyNotifications = async (req, res) => {
  try {
    // ✅ FIX: Model enum mein 'parents' nahi, 'families' hai
    const notifications = await Notification.find({
      $or: [{ audience: 'all' }, { audience: 'families' }],
    }).sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: notifications.length, data: notifications });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};