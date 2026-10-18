const mongoose = require('mongoose');

const subjectSchema = new mongoose.Schema(
  {
    subjectName: {
      type: String,
      required: true,
      trim: true,
    },
    totalMarks: {
      type: Number,
      required: true,
      default: 100,
    },
    passingMarks: {
      type: Number,
      default: 50,
    },
  },
  { _id: false }
);

const examSchema = new mongoose.Schema(
  {
    examName: {
      type: String,
      required: [true, 'Exam name is required'],
      trim: true,
      // e.g., "Mid Term 2026", "Final Term 2026", "Monthly Test - January"
    },
    examType: {
      type: String,
      enum: ['Monthly Test', 'Midterm', 'Final Term', 'Quiz', 'Other'],
      default: 'Other',
    },
    className: {
      type: String,
      required: [true, 'Class name is required'],
      trim: true,
      // e.g., "BSCS-1st" (matches Student.className)
    },
    subjects: {
      type: [subjectSchema],
      required: true,
      validate: {
        validator: (arr) => arr.length > 0,
        message: 'At least one subject is required',
      },
    },
    examDate: {
      type: Date,
      required: [true, 'Exam date is required'],
    },
    academicYear: {
      type: String,
      default: () => new Date().getFullYear().toString(),
    },
    status: {
      type: String,
      enum: ['Scheduled', 'Completed', 'Cancelled'],
      default: 'Scheduled',
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Exam', examSchema);