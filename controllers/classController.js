const Class = require('../models/Class');
const Student = require('../models/Student');

// @desc   Create a new class
// @route  POST /api/classes
exports.createClass = async (req, res) => {
  try {
    const { className, section, classTeacher } = req.body;

    if (!className) {
      return res.status(400).json({ success: false, message: 'className is required' });
    }

    const exists = await Class.findOne({ className });
    if (exists) {
      return res.status(400).json({ success: false, message: 'Class already exists' });
    }

    const newClass = await Class.create({ className, section, classTeacher });
    res.status(201).json({ success: true, data: newClass });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Get all classes (with subject count & student count)
// @route  GET /api/classes
exports.getClasses = async (req, res) => {
  try {
    const classes = await Class.find()
      .populate('classTeacher', 'fullName designation')
      .populate('subjects', 'subjectName subjectCode')
      .sort({ className: 1 });

    // Attach live student count for each class
    const classesWithCount = await Promise.all(
      classes.map(async (cls) => {
        const studentCount = await Student.countDocuments({ className: cls.className, status: 'active' });
        return { ...cls.toObject(), totalStudents: studentCount };
      })
    );

    res.status(200).json({ success: true, count: classesWithCount.length, data: classesWithCount });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get single class with full details
// @route  GET /api/classes/:id
exports.getClassById = async (req, res) => {
  try {
    const cls = await Class.findById(req.params.id)
      .populate('classTeacher', 'fullName designation phone')
      .populate('subjects');

    if (!cls) {
      return res.status(404).json({ success: false, message: 'Class not found' });
    }

    const students = await Student.find({ className: cls.className, status: 'active' });

    res.status(200).json({ success: true, data: { ...cls.toObject(), students } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Update class
// @route  PUT /api/classes/:id
exports.updateClass = async (req, res) => {
  try {
    const cls = await Class.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!cls) {
      return res.status(404).json({ success: false, message: 'Class not found' });
    }
    res.status(200).json({ success: true, data: cls });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Delete class
// @route  DELETE /api/classes/:id
exports.deleteClass = async (req, res) => {
  try {
    const cls = await Class.findByIdAndDelete(req.params.id);
    if (!cls) {
      return res.status(404).json({ success: false, message: 'Class not found' });
    }
    res.status(200).json({ success: true, message: 'Class deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};