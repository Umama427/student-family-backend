const mongoose = require('mongoose');

const subjectSchema = new mongoose.Schema(
  {
    subjectName: { type: String, required: [true, 'Subject name is required'], trim: true },
    subjectCode: { type: String, trim: true, uppercase: true },
    creditHours: { type: Number, default: 0 },
    class: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Class',
      required: [true, 'Class is required'],
    },
    teacher: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Staff',
      default: null,
    },
    totalMarks: { type: Number, default: 100 },
    passingMarks: { type: Number, default: 40 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

subjectSchema.index({ subjectName: 1, class: 1 }, { unique: true });

module.exports = mongoose.model('Subject', subjectSchema, 'subjects');