const Student = require('../models/Student');
const Exam = require('../models/Exam');
const Result = require('../models/Result');
const Attendance = require('../models/Attendance');
const { logAction } = require('../utils/auditLogger');
const { calculateGrade } = require('../utils/gradeCalculator');

const ensureOwnClass = (req, className) => {
  return req.user.assignedClasses && req.user.assignedClasses.includes(className);
};

// @desc Get logged-in teacher's profile
exports.getMyProfile = async (req, res) => {
  res.status(200).json({ success: true, data: req.user });
};

// @desc Get students in teacher's assigned classes
// @route GET /api/teacher/my-students?className=xxx
exports.getMyStudents = async (req, res) => {
  try {
    const assigned = req.user.assignedClasses || [];
    if (assigned.length === 0) {
      return res.status(200).json({
        success: true,
        count: 0,
        data: [],
        message: 'No classes assigned yet. Contact admin.',
      });
    }

    const filter = { className: { $in: assigned } };
    if (req.query.className) {
      if (!assigned.includes(req.query.className)) {
        return res.status(403).json({ success: false, message: 'You are not assigned to this class' });
      }
      filter.className = req.query.className;
    }

    const students = await Student.find(filter).sort({ className: 1, fullName: 1 });
    res.status(200).json({ success: true, count: students.length, data: students });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc Get exams for teacher's assigned classes
// @route GET /api/teacher/my-exams
exports.getMyExams = async (req, res) => {
  try {
    const assigned = req.user.assignedClasses || [];
    const exams = await Exam.find({ className: { $in: assigned } }).sort({ examDate: -1 });
    res.status(200).json({ success: true, count: exams.length, data: exams });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc Get results for an exam (only if it's teacher's own class)
// @route GET /api/teacher/exam-results/:examId
exports.getMyClassExamResults = async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.examId);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });

    if (!ensureOwnClass(req, exam.className)) {
      return res.status(403).json({ success: false, message: 'Not authorized for this class' });
    }

    const results = await Result.find({ examId: exam._id })
      .populate('studentId', 'fullName')
      .sort({ percentage: -1 });

    res.status(200).json({ success: true, count: results.length, data: results });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc Enter or update marks for a student (only own class)
// @route POST /api/teacher/enter-marks
exports.enterMarks = async (req, res) => {
  try {
    const { examId, studentId, subjects, remarks } = req.body;

    if (!examId || !studentId || !subjects || subjects.length === 0) {
      return res.status(400).json({ success: false, message: 'examId, studentId and subjects are required' });
    }

    const exam = await Exam.findById(examId);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });

    if (!ensureOwnClass(req, exam.className)) {
      return res.status(403).json({ success: false, message: 'You are not authorized for this class' });
    }

    const student = await Student.findById(studentId);
    if (!student || student.className !== exam.className) {
      return res.status(404).json({ success: false, message: 'Student not found in this class' });
    }

    let totalMarksObtained = 0;
    let totalMaxMarks = 0;
    const subjectsWithGrade = subjects.map((s) => {
      const subjPercentage = (s.marksObtained / s.totalMarks) * 100;
      const { grade } = calculateGrade(subjPercentage);
      totalMarksObtained += Number(s.marksObtained);
      totalMaxMarks += Number(s.totalMarks);
      return { ...s, grade };
    });

    const percentage = totalMaxMarks > 0 ? (totalMarksObtained / totalMaxMarks) * 100 : 0;
    const { grade: overallGrade, gpa, status } = calculateGrade(percentage);

    let result = await Result.findOne({ examId, studentId });

    if (result) {
      result.subjects = subjectsWithGrade;
      result.totalMarksObtained = totalMarksObtained;
      result.totalMaxMarks = totalMaxMarks;
      result.percentage = Math.round(percentage * 100) / 100;
      result.overallGrade = overallGrade;
      result.gpa = gpa;
      result.status = status;
      if (remarks) result.remarks = remarks;
      await result.save();
    } else {
      result = await Result.create({
        examId,
        studentId,
        familyId: student.familyId,
        className: exam.className,
        subjects: subjectsWithGrade,
        totalMarksObtained,
        totalMaxMarks,
        percentage: Math.round(percentage * 100) / 100,
        overallGrade,
        gpa,
        status,
        remarks: remarks || '',
      });
    }

    await logAction({
      admin: req.user,
      action: 'UPDATE',
      module: 'Result',
      description: `Teacher ${req.user.fullName} entered marks for ${student.fullName} in ${exam.examName}`,
      targetId: result._id,
      newData: result.toObject(),
      ipAddress: req.ip,
    });

    res.status(200).json({ success: true, message: 'Marks saved successfully', data: result });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// ==================== ✅ ATTENDANCE (New) ====================

// Helper: normalize date to midnight (ignore time component)
const normalizeDate = (dateStr) => {
  const d = dateStr ? new Date(dateStr) : new Date();
  d.setHours(0, 0, 0, 0);
  return d;
};

// @desc Mark/update attendance for a single student (only own class)
// @route POST /api/teacher/mark-attendance
// @body { studentId, date, status, remarks }
exports.markStudentAttendance = async (req, res) => {
  try {
    const { studentId, date, status, remarks } = req.body;

    if (!studentId || !status) {
      return res.status(400).json({ success: false, message: 'studentId and status are required' });
    }

    const student = await Student.findById(studentId);
    if (!student) {
      return res.status(404).json({ success: false, message: 'Student not found' });
    }

    if (!ensureOwnClass(req, student.className)) {
      return res.status(403).json({ success: false, message: 'You are not authorized for this student\'s class' });
    }

    const attendanceDate = normalizeDate(date);

    // Upsert: agar already mark ho chuka hai is din, update karein; nahi toh naya banayein
    const attendance = await Attendance.findOneAndUpdate(
      { refId: studentId, date: attendanceDate },
      {
        type: 'student',
        refId: studentId,
        refModel: 'Student',
        date: attendanceDate,
        status,
        remarks: remarks || '',
      },
      { new: true, upsert: true, runValidators: true }
    );

    await logAction({
      admin: req.user,
      action: 'UPDATE',
      module: 'Attendance',
      description: `Teacher ${req.user.fullName} marked ${student.fullName} as ${status} on ${attendanceDate.toDateString()}`,
      targetId: attendance._id,
      newData: attendance.toObject(),
      ipAddress: req.ip,
    });

    res.status(200).json({ success: true, message: 'Attendance marked successfully', data: attendance });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc Bulk mark attendance for multiple students (only own class)
// @route POST /api/teacher/bulk-mark-attendance
// @body { date, records: [{ studentId, status, remarks }] }
exports.bulkMarkStudentAttendance = async (req, res) => {
  try {
    const { date, records } = req.body;

    if (!Array.isArray(records) || records.length === 0) {
      return res.status(400).json({ success: false, message: 'records array is required' });
    }

    const attendanceDate = normalizeDate(date);
    const assigned = req.user.assignedClasses || [];

    const marked = [];
    const skipped = [];

    for (const entry of records) {
      try {
        const student = await Student.findById(entry.studentId);
        if (!student) {
          skipped.push({ studentId: entry.studentId, reason: 'Student not found' });
          continue;
        }

        if (!assigned.includes(student.className)) {
          skipped.push({ studentId: entry.studentId, reason: 'Not your assigned class' });
          continue;
        }

        const attendance = await Attendance.findOneAndUpdate(
          { refId: entry.studentId, date: attendanceDate },
          {
            type: 'student',
            refId: entry.studentId,
            refModel: 'Student',
            date: attendanceDate,
            status: entry.status || 'Present',
            remarks: entry.remarks || '',
          },
          { new: true, upsert: true, runValidators: true }
        );

        marked.push(attendance);
      } catch (err) {
        skipped.push({ studentId: entry.studentId, reason: err.message });
      }
    }

    await logAction({
      admin: req.user,
      action: 'UPDATE',
      module: 'Attendance',
      description: `Teacher ${req.user.fullName} bulk marked attendance for ${marked.length} students on ${attendanceDate.toDateString()}`,
      newData: { count: marked.length },
      ipAddress: req.ip,
    });

    res.status(200).json({
      success: true,
      message: `${marked.length} marked, ${skipped.length} skipped`,
      data: { marked, skipped },
    });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc Get attendance records for teacher's assigned class on a specific date
// @route GET /api/teacher/attendance?className=xxx&date=2026-01-15
exports.getMyClassAttendance = async (req, res) => {
  try {
    const { className, date } = req.query;
    const assigned = req.user.assignedClasses || [];

    if (!className || !assigned.includes(className)) {
      return res.status(403).json({ success: false, message: 'Invalid or unauthorized class' });
    }

    const students = await Student.find({ className }).select('_id fullName');
    const studentIds = students.map((s) => s._id);

    const filter = { refId: { $in: studentIds }, type: 'student' };
    if (date) {
      filter.date = normalizeDate(date);
    }

    const records = await Attendance.find(filter).sort({ date: -1 });

    // Merge: students without a record for that date show as "Not Marked"
    const recordMap = {};
    records.forEach((r) => (recordMap[r.refId.toString()] = r));

    const merged = students.map((s) => ({
      student: s,
      attendance: recordMap[s._id.toString()] || null,
    }));

    res.status(200).json({ success: true, count: merged.length, data: merged });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getMyProfile: exports.getMyProfile,
  getMyStudents: exports.getMyStudents,
  getMyExams: exports.getMyExams,
  getMyClassExamResults: exports.getMyClassExamResults,
  enterMarks: exports.enterMarks,
  markStudentAttendance: exports.markStudentAttendance,
  bulkMarkStudentAttendance: exports.bulkMarkStudentAttendance,
  getMyClassAttendance: exports.getMyClassAttendance,
};