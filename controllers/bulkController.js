const Student = require('../models/Student');
const FeeChallan = require('../models/FeeChallan');
const Exam = require('../models/Exam');
const Result = require('../models/Result');
const { calculateGrade } = require('../utils/gradeCalculator');

// @desc  Bulk generate fee challans for ALL active students of a class in one go (Admin only)
// Body: { className, month (1-12), year, dueDate, otherCharges: [{label, amount}] (optional) }
exports.bulkGenerateChallans = async (req, res) => {
  try {
    const { className, month, year, dueDate, otherCharges = [] } = req.body;

    if (!className || !month || !year || !dueDate) {
      return res.status(400).json({ success: false, message: 'className, month, year and dueDate are required' });
    }

    const students = await Student.find({ className, status: 'active' });
    if (!students.length) {
      return res.status(404).json({ success: false, message: 'No active students found in this class' });
    }

    const otherChargesTotal = otherCharges.reduce((sum, i) => sum + Number(i.amount || 0), 0);
    const createdList = [];
    let skippedCount = 0;

    for (const student of students) {
      const existing = await FeeChallan.findOne({ studentId: student._id, month: Number(month), year: Number(year) });
      if (existing) { skippedCount++; continue; }

      const tuitionFee = Number(student.monthlyTuitionFee) || 0;
      const discountPercentage = Number(student.discountPercentage) || 0;
      const discountAmount = (tuitionFee * discountPercentage) / 100;
      const totalPayable = tuitionFee - discountAmount + otherChargesTotal;

      const challan = await FeeChallan.create({
        studentId: student._id,
        familyId: student.familyId,
        month: Number(month),
        year: Number(year),
        tuitionFee,
        otherCharges,
        discountPercentage,
        discountAmount,
        totalPayable,
        dueDate,
        status: new Date(dueDate) < new Date() ? 'Overdue' : 'Pending',
      });

      createdList.push(challan);
    }

    res.status(201).json({
      success: true,
      message: `${createdList.length} challans generated, ${skippedCount} skipped (already existed for this month)`,
      count: createdList.length,
      skipped: skippedCount,
      data: createdList
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Bulk challan generation failed', error: err.message });
  }
};

// @desc  Bulk enter marks for ONE subject across MANY students of an exam at once (Admin + Teacher)
// Body: { examId, subjectName, marks: [{ studentId, marksObtained }] }
exports.bulkEnterResults = async (req, res) => {
  try {
    const { examId, subjectName, marks } = req.body;
    if (!examId || !subjectName || !Array.isArray(marks) || !marks.length) {
      return res.status(400).json({ success: false, message: 'examId, subjectName and marks[] are required' });
    }

    const exam = await Exam.findById(examId);
    if (!exam) return res.status(404).json({ success: false, message: 'Exam not found' });

    if (req.role === 'teacher' && !(req.user.assignedClasses || []).includes(exam.className)) {
      return res.status(403).json({ success: false, message: 'Not authorized for this class' });
    }

    const subjectDef = exam.subjects.find(s => s.subjectName === subjectName);
    if (!subjectDef) {
      return res.status(400).json({ success: false, message: 'This subject does not exist in the selected exam' });
    }
    const totalMarks = subjectDef.totalMarks;

    let savedCount = 0;

    for (const entry of marks) {
      if (entry.marksObtained === '' || entry.marksObtained === null || entry.marksObtained === undefined) continue;

      const student = await Student.findById(entry.studentId);
      if (!student) continue;

      const marksObtained = Number(entry.marksObtained);
      const subjPercentage = (marksObtained / totalMarks) * 100;
      const { grade } = calculateGrade(subjPercentage);

      let result = await Result.findOne({ examId, studentId: entry.studentId });

      if (!result) {
        result = new Result({
          examId,
          studentId: entry.studentId,
          familyId: student.familyId,
          className: exam.className,
          subjects: [{ subjectName, marksObtained, totalMarks, grade }],
        });
      } else {
        const idx = result.subjects.findIndex(s => s.subjectName === subjectName);
        if (idx >= 0) {
          result.subjects[idx].marksObtained = marksObtained;
          result.subjects[idx].totalMarks = totalMarks;
          result.subjects[idx].grade = grade;
        } else {
          result.subjects.push({ subjectName, marksObtained, totalMarks, grade });
        }
      }

      const totalMarksObtained = result.subjects.reduce((s, x) => s + x.marksObtained, 0);
      const totalMaxMarks = result.subjects.reduce((s, x) => s + x.totalMarks, 0);
      const percentage = totalMaxMarks > 0 ? (totalMarksObtained / totalMaxMarks) * 100 : 0;
      const overall = calculateGrade(percentage);

      result.totalMarksObtained = totalMarksObtained;
      result.totalMaxMarks = totalMaxMarks;
      result.percentage = Math.round(percentage * 100) / 100;
      result.overallGrade = overall.grade;
      result.gpa = overall.gpa;
      result.status = overall.status;

      await result.save();
      savedCount++;
    }

    res.status(200).json({ success: true, message: `Marks saved for ${savedCount} students`, count: savedCount });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Bulk result entry failed', error: err.message });
  }
};