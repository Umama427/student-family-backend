const mongoose = require('mongoose');

const subjectResultSchema = new mongoose.Schema(
  {
    subjectName: {
      type: String,
      required: true,
    },
    marksObtained: {
      type: Number,
      required: true,
      min: 0,
    },
    totalMarks: {
      type: Number,
      required: true,
    },
    grade: {
      type: String,
      default: '',
    },
  },
  { _id: false }
);

const resultSchema = new mongoose.Schema(
  {
    examId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Exam',
      required: true,
    },
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      required: true,
    },
    familyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Family',
    },
    className: {
      type: String,
      required: true,
    },
    subjects: {
      type: [subjectResultSchema],
      required: true,
    },
    totalMarksObtained: {
      type: Number,
      default: 0,
    },
    totalMaxMarks: {
      type: Number,
      default: 0,
    },
    percentage: {
      type: Number,
      default: 0,
    },
    overallGrade: {
      type: String,
      default: '',
    },
    gpa: {
      type: Number,
      default: 0,
    },
    status: {
      type: String,
      enum: ['Pass', 'Fail'],
      default: 'Pass',
    },
    remarks: {
      type: String,
      default: '',
    },
  },
  { timestamps: true }
);

// Prevent duplicate result entry for same student + exam
resultSchema.index({ examId: 1, studentId: 1 }, { unique: true });

module.exports = mongoose.model('Result', resultSchema);