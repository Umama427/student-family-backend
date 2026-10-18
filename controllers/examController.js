const Exam = require('../models/Exam');
const Result = require('../models/Result');
const Student = require('../models/Student');
const { logAction } = require('../utils/auditLogger');

// @desc    Create exam (Admin only)
exports.createExam = async (req, res) => {
  try {
    const { examName, examType, className, subjects, examDate, academicYear } = req.body;

    if (!examName || !className || !subjects || !examDate) {
      return res.status(400).json({
        success: false,
        message: 'examName, className, subjects, and examDate are required',
      });
    }

    const exam = await Exam.create({
      examName,
      examType,
      className,
      subjects,
      examDate,
      academicYear,
    });

    await logAction({
      admin: req.admin,
      action: 'CREATE',
      module: 'Exam',
      description: `Created exam: ${exam.examName} for class ${exam.className}`,
      targetId: exam._id,
      newData: exam.toObject(),
      ipAddress: req.ip,
    });

    res.status(201).json({
      success: true,
      message: 'Exam created successfully',
      data: exam,
    });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc    Get all exams (Admin = all, Teacher = own class, Parent = children's classes)
exports.getExams = async (req, res) => {
  try {
    const filter = {};
    if (req.query.examType) filter.examType = req.query.examType;

    if (req.role === 'teacher') {
      filter.className = { $in: req.user.assignedClasses || [] };
    } else if (req.role === 'parent') {
      const children = await Student.find({ familyId: req.user._id }).select('className');
      const classNames = [...new Set(children.map((c) => c.className))];
      filter.className = { $in: classNames };
    } else if (req.query.className) {
      filter.className = req.query.className; // admin optional filter
    }

    const exams = await Exam.find(filter).sort({ examDate: -1 });

    res.status(200).json({
      success: true,
      count: exams.length,
      data: exams,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Get single exam (with ownership check)
exports.getExamById = async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id);
    if (!exam) {
      return res.status(404).json({ success: false, message: 'Exam not found' });
    }

    if (req.role === 'teacher' && !(req.user.assignedClasses || []).includes(exam.className)) {
      return res.status(403).json({ success: false, message: 'Access denied: not your class' });
    }

    if (req.role === 'parent') {
      const children = await Student.find({ familyId: req.user._id }).select('className');
      const classNames = children.map((c) => c.className);
      if (!classNames.includes(exam.className)) {
        return res.status(403).json({ success: false, message: 'Access denied' });
      }
    }

    res.status(200).json({ success: true, data: exam });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc    Update exam (Admin only)
exports.updateExam = async (req, res) => {
  try {
    const oldExam = await Exam.findById(req.params.id);
    if (!oldExam) {
      return res.status(404).json({ success: false, message: 'Exam not found' });
    }

    const exam = await Exam.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });

    await logAction({
      admin: req.admin,
      action: 'UPDATE',
      module: 'Exam',
      description: `Updated exam: ${exam.examName}`,
      targetId: exam._id,
      oldData: oldExam.toObject(),
      newData: exam.toObject(),
      ipAddress: req.ip,
    });

    res.status(200).json({ success: true, data: exam });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc    Delete exam (Admin only)
exports.deleteExam = async (req, res) => {
  try {
    const exam = await Exam.findById(req.params.id);
    if (!exam) {
      return res.status(404).json({ success: false, message: 'Exam not found' });
    }

    const resultCount = await Result.countDocuments({ examId: req.params.id });
    if (resultCount > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot delete. ${resultCount} result(s) already exist for this exam. Delete results first.`,
      });
    }

    await Exam.findByIdAndDelete(req.params.id);

    await logAction({
      admin: req.admin,
      action: 'DELETE',
      module: 'Exam',
      description: `Deleted exam: ${exam.examName}`,
      targetId: exam._id,
      oldData: exam.toObject(),
      ipAddress: req.ip,
    });

    res.status(200).json({ success: true, message: 'Exam deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};