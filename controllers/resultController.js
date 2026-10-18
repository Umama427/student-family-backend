const Result = require('../models/Result');
const Exam = require('../models/Exam');
const Student = require('../models/Student');
const { calculateGrade } = require('../utils/gradeCalculator');
const { logAction } = require('../utils/auditLogger');

const computeResultStats = (subjects) => {
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

  return {
    subjects: subjectsWithGrade,
    totalMarksObtained,
    totalMaxMarks,
    percentage: Math.round(percentage * 100) / 100,
    overallGrade,
    gpa,
    status,
  };
};

// ✅ Helper: Teacher can only touch exams/results of their assigned classes
const teacherOwnsClass = (req, className) => {
  return (req.user.assignedClasses || []).includes(className);
};

// ✅ Helper: Parent can only view results of their own children
const parentOwnsResult = (req, result) => {
  return result.familyId && result.familyId.toString() === req.user._id.toString();
};

// @desc   Add result (Admin + Teacher [own class only])
exports.createResult = async (req, res) => {
  try {
    const { examId, studentId, subjects, remarks } = req.body;

    if (!examId || !studentId || !subjects || subjects.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'examId, studentId, and subjects are required',
      });
    }

    const exam = await Exam.findById(examId);
    if (!exam) {
      return res.status(404).json({ success: false, message: 'Exam not found' });
    }

    // ✅ Teacher ownership check
    if (req.role === 'teacher' && !teacherOwnsClass(req, exam.className)) {
      return res.status(403).json({ success: false, message: 'Access denied: not your assigned class' });
    }

    const student = await Student.findById(studentId);
    if (!student) {
      return res.status(404).json({ success: false, message: 'Student not found' });
    }

    const existingResult = await Result.findOne({ examId, studentId });
    if (existingResult) {
      return res.status(400).json({
        success: false,
        message: 'Result already exists for this student in this exam. Use update instead.',
      });
    }

    const stats = computeResultStats(subjects);

    const result = await Result.create({
      examId,
      studentId,
      familyId: student.familyId,
      className: exam.className,
      subjects: stats.subjects,
      totalMarksObtained: stats.totalMarksObtained,
      totalMaxMarks: stats.totalMaxMarks,
      percentage: stats.percentage,
      overallGrade: stats.overallGrade,
      gpa: stats.gpa,
      status: stats.status,
      remarks: remarks || '',
    });

    await logAction({
      admin: req.role === 'admin' ? req.admin : null,
      action: 'CREATE',
      module: 'Result',
      description: `Entered result for ${student.fullName} in ${exam.examName} (${stats.percentage}%) by ${req.role}`,
      targetId: result._id,
      newData: result.toObject(),
      ipAddress: req.ip,
    });

    res.status(201).json({
      success: true,
      message: 'Result entered successfully',
      data: result,
    });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Bulk entry (Admin + Teacher [own class only])
exports.bulkCreateResults = async (req, res) => {
  try {
    const { examId, results } = req.body;

    if (!examId || !Array.isArray(results) || results.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'examId and results array are required',
      });
    }

    const exam = await Exam.findById(examId);
    if (!exam) {
      return res.status(404).json({ success: false, message: 'Exam not found' });
    }

    // ✅ Teacher ownership check
    if (req.role === 'teacher' && !teacherOwnsClass(req, exam.className)) {
      return res.status(403).json({ success: false, message: 'Access denied: not your assigned class' });
    }

    const created = [];
    const skipped = [];

    for (const entry of results) {
      try {
        const existing = await Result.findOne({ examId, studentId: entry.studentId });
        if (existing) {
          skipped.push({ studentId: entry.studentId, reason: 'Result already exists' });
          continue;
        }

        const student = await Student.findById(entry.studentId);
        if (!student) {
          skipped.push({ studentId: entry.studentId, reason: 'Student not found' });
          continue;
        }

        const stats = computeResultStats(entry.subjects);

        const result = await Result.create({
          examId,
          studentId: entry.studentId,
          familyId: student.familyId,
          className: exam.className,
          subjects: stats.subjects,
          totalMarksObtained: stats.totalMarksObtained,
          totalMaxMarks: stats.totalMaxMarks,
          percentage: stats.percentage,
          overallGrade: stats.overallGrade,
          gpa: stats.gpa,
          status: stats.status,
          remarks: entry.remarks || '',
        });

        created.push(result);
      } catch (err) {
        skipped.push({ studentId: entry.studentId, reason: err.message });
      }
    }

    await logAction({
      admin: req.role === 'admin' ? req.admin : null,
      action: 'CREATE',
      module: 'Result',
      description: `Bulk entered ${created.length} results for exam: ${exam.examName} by ${req.role}`,
      targetId: exam._id,
      newData: { count: created.length },
      ipAddress: req.ip,
    });

    res.status(201).json({
      success: true,
      message: `${created.length} results created, ${skipped.length} skipped`,
      data: { created, skipped },
    });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Get all results for an exam (Admin = all, Teacher = own class only)
exports.getResultsByExam = async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.examId);
    if (!exam) {
      return res.status(404).json({ success: false, message: 'Exam not found' });
    }

    // ✅ Teacher ownership check
    if (req.role === 'teacher' && !teacherOwnsClass(req, exam.className)) {
      return res.status(403).json({ success: false, message: 'Access denied: not your assigned class' });
    }

    let filter = { examId: req.params.examId };

    // ✅ Parent: sirf apne bachon ka result is exam mein
    if (req.role === 'parent') {
      filter.familyId = req.user._id;
    }

    const results = await Result.find(filter)
      .populate('studentId', 'fullName rollNumber')
      .sort({ percentage: -1 });

    res.status(200).json({
      success: true,
      count: results.length,
      data: results,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get all results for a student (Admin, Teacher [own class], Parent [own child])
exports.getResultsByStudent = async (req, res) => {
  try {
    const student = await Student.findById(req.params.studentId);
    if (!student) {
      return res.status(404).json({ success: false, message: 'Student not found' });
    }

    // ✅ Ownership checks
    if (req.role === 'teacher' && !teacherOwnsClass(req, student.className)) {
      return res.status(403).json({ success: false, message: 'Access denied: student not in your class' });
    }
    if (req.role === 'parent' && student.familyId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Access denied: not your child' });
    }

    const results = await Result.find({ studentId: req.params.studentId })
      .populate('examId', 'examName examType examDate academicYear')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: results.length,
      data: results,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get single result (full report card) — with ownership check
exports.getResultById = async (req, res) => {
  try {
    const result = await Result.findById(req.params.id)
      .populate('studentId', 'fullName familyId')
      .populate('examId', 'examName examType examDate academicYear');

    if (!result) {
      return res.status(404).json({ success: false, message: 'Result not found' });
    }

    // ✅ Ownership checks
    if (req.role === 'teacher' && !teacherOwnsClass(req, result.className)) {
      return res.status(403).json({ success: false, message: 'Access denied: not your class' });
    }
    if (req.role === 'parent' && !parentOwnsResult(req, result)) {
      return res.status(403).json({ success: false, message: 'Access denied: not your child' });
    }

    res.status(200).json({ success: true, data: result });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Update result (Admin + Teacher [own class only])
exports.updateResult = async (req, res) => {
  try {
    const oldResult = await Result.findById(req.params.id);
    if (!oldResult) {
      return res.status(404).json({ success: false, message: 'Result not found' });
    }

    // ✅ Teacher ownership check
    if (req.role === 'teacher' && !teacherOwnsClass(req, oldResult.className)) {
      return res.status(403).json({ success: false, message: 'Access denied: not your class' });
    }

    const { subjects, remarks } = req.body;
    let updateData = { remarks };

    if (subjects && subjects.length > 0) {
      const stats = computeResultStats(subjects);
      updateData = {
        ...updateData,
        subjects: stats.subjects,
        totalMarksObtained: stats.totalMarksObtained,
        totalMaxMarks: stats.totalMaxMarks,
        percentage: stats.percentage,
        overallGrade: stats.overallGrade,
        gpa: stats.gpa,
        status: stats.status,
      };
    }

    const result = await Result.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
      runValidators: true,
    });

    await logAction({
      admin: req.role === 'admin' ? req.admin : null,
      action: 'UPDATE',
      module: 'Result',
      description: `Updated result (ID: ${result._id}) by ${req.role}`,
      targetId: result._id,
      oldData: oldResult.toObject(),
      newData: result.toObject(),
      ipAddress: req.ip,
    });

    res.status(200).json({ success: true, data: result });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Delete result (Admin only)
exports.deleteResult = async (req, res) => {
  try {
    const result = await Result.findByIdAndDelete(req.params.id);
    if (!result) {
      return res.status(404).json({ success: false, message: 'Result not found' });
    }

    await logAction({
      admin: req.admin,
      action: 'DELETE',
      module: 'Result',
      description: `Deleted result (ID: ${result._id})`,
      targetId: result._id,
      oldData: result.toObject(),
      ipAddress: req.ip,
    });

    res.status(200).json({ success: true, message: 'Result deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Class performance summary (Admin + Teacher [own class only])
exports.getClassSummary = async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.examId);
    if (!exam) {
      return res.status(404).json({ success: false, message: 'Exam not found' });
    }

    // ✅ Teacher ownership check
    if (req.role === 'teacher' && !teacherOwnsClass(req, exam.className)) {
      return res.status(403).json({ success: false, message: 'Access denied: not your class' });
    }

    const results = await Result.find({ examId: req.params.examId }).populate(
      'studentId',
      'fullName'
    );

    if (results.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          totalStudents: 0,
          averagePercentage: 0,
          passCount: 0,
          failCount: 0,
          topScorers: [],
        },
      });
    }

    const totalStudents = results.length;
    const averagePercentage =
      results.reduce((sum, r) => sum + r.percentage, 0) / totalStudents;
    const passCount = results.filter((r) => r.status === 'Pass').length;
    const failCount = totalStudents - passCount;

    const topScorers = [...results]
      .sort((a, b) => b.percentage - a.percentage)
      .slice(0, 5)
      .map((r) => ({
        studentName: r.studentId.fullName,
        percentage: r.percentage,
        grade: r.overallGrade,
      }));

    res.status(200).json({
      success: true,
      data: {
        totalStudents,
        averagePercentage: Math.round(averagePercentage * 100) / 100,
        passCount,
        failCount,
        topScorers,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};