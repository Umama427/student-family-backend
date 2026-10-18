const Subject = require('../models/Subject');
const Class = require('../models/Class');

exports.createSubject = async (req, res) => {
  try {
    const { subjectName, subjectCode, creditHours, classId, teacherId, totalMarks, passingMarks } = req.body;

    if (!subjectName || !classId) {
      return res.status(400).json({ success: false, message: 'subjectName and classId are required' });
    }

    const classExists = await Class.findById(classId);
    if (!classExists) {
      return res.status(404).json({ success: false, message: 'Class not found' });
    }

    const subject = await Subject.create({
      subjectName,
      subjectCode,
      creditHours,
      class: classId,        // ✅ FIX: 'class' field use karein
      teacher: teacherId || null,  // ✅ FIX: 'teacher' field use karein
      totalMarks,
      passingMarks,
    });

    classExists.subjects.push(subject._id);
    await classExists.save();

    res.status(201).json({ success: true, data: subject });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.getSubjects = async (req, res) => {
  try {
    const { classId } = req.query;
    const filter = {};
    if (classId) filter.class = classId;  // ✅ FIX

    const subjects = await Subject.find(filter)
      .populate('class', 'className section')   // ✅ FIX
      .populate('teacher', 'fullName designation')  // ✅ FIX
      .sort({ subjectName: 1 });

    res.status(200).json({ success: true, count: subjects.length, data: subjects });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getSubjectById = async (req, res) => {
  try {
    const subject = await Subject.findById(req.params.id)
      .populate('class')   // ✅ FIX
      .populate('teacher'); // ✅ FIX

    if (!subject) {
      return res.status(404).json({ success: false, message: 'Subject not found' });
    }
    res.status(200).json({ success: true, data: subject });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateSubject = async (req, res) => {
  try {
    const updateData = { ...req.body };
    // ✅ FIX: Frontend se classId/teacherId aaye to schema field names mein map karein
    if (updateData.classId) {
      updateData.class = updateData.classId;
      delete updateData.classId;
    }
    if (updateData.teacherId) {
      updateData.teacher = updateData.teacherId;
      delete updateData.teacherId;
    }

    const subject = await Subject.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
      runValidators: true,
    });
    if (!subject) {
      return res.status(404).json({ success: false, message: 'Subject not found' });
    }
    res.status(200).json({ success: true, data: subject });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.deleteSubject = async (req, res) => {
  try {
    const subject = await Subject.findByIdAndDelete(req.params.id);
    if (!subject) {
      return res.status(404).json({ success: false, message: 'Subject not found' });
    }

    await Class.findByIdAndUpdate(subject.class, { $pull: { subjects: subject._id } }); // ✅ FIX

    res.status(200).json({ success: true, message: 'Subject deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};