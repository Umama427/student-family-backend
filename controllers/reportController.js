const Student = require('../models/Student');
const Exam = require('../models/Exam');
const Result = require('../models/Result');
const { generateResultsExcelBuffer } = require('../utils/excelGenerator');
const { generateReportCardPDF, generateClassReportCardsPDF } = require('../utils/reportCardGenerator');

function canAccessClass(user, className) {
  if (user.role === 'admin') return true;
  if (user.role === 'teacher') return (user.assignedClasses || []).includes(className);
  return false;
}

// @desc  Export all results of an exam to professional Excel sheet
exports.exportExamResultsExcel = async (req, res) => {
  try {
    const { examId } = req.params;
    const exam = await Exam.findById(examId);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    if (!canAccessClass(req.user, exam.className)) {
      return res.status(403).json({ success: false, message: 'Not authorized for this class' });
    }

    const students = await Student.find({ className: exam.className });
    const results = await Result.find({ examId });

    const buffer = await generateResultsExcelBuffer({
      examName: exam.examName,
      className: exam.className,
      academicYear: exam.academicYear,
      subjects: exam.subjects,
      students,
      results
    });

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=Results_${exam.examName.replace(/\s/g, '_')}.xlsx`);
    res.send(buffer);
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to generate Excel sheet', error: err.message });
  }
};

// @desc  Generate a single student's report card / transcript PDF
exports.generateStudentReportCard = async (req, res) => {
  try {
    const { studentId, examId } = req.params;
    const student = await Student.findById(studentId).populate('familyId', 'fatherName familyName');
    const exam = await Exam.findById(examId);
    if (!student || !exam) return res.status(404).json({ success: false, message: 'Student or Exam not found' });

    if (req.user.role === 'parent' && String(student.familyId?._id) !== String(req.user.familyId)) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }
    if (req.user.role === 'teacher' && !canAccessClass(req.user, exam.className)) {
      return res.status(403).json({ success: false, message: 'Not authorized for this class' });
    }

    const result = await Result.findOne({ examId, studentId });
    if (!result) return res.status(404).json({ success: false, message: 'Result not found for this student' });

    generateReportCardPDF(res, { student, exam, result });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to generate report card', error: err.message });
  }
};

// @desc  Generate report cards for ALL students of a class for one exam (one combined PDF)
exports.generateClassReportCards = async (req, res) => {
  try {
    const { examId } = req.params;
    const exam = await Exam.findById(examId);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });
    if (!canAccessClass(req.user, exam.className)) {
      return res.status(403).json({ success: false, message: 'Not authorized for this class' });
    }

    const students = await Student.find({ className: exam.className }).populate('familyId', 'fatherName familyName');
    const results = await Result.find({ examId });

    const studentsData = students.map(student => {
      const result = results.find(r => String(r.studentId) === String(student._id));
      if (!result) return null;
      return { student, exam, result };
    }).filter(Boolean);

    if (!studentsData.length) {
      return res.status(404).json({ success: false, message: 'No results entered yet for this exam' });
    }

    generateClassReportCardsPDF(res, { className: exam.className, studentsData });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to generate report cards', error: err.message });
  }
};