const mongoose = require('mongoose');

const classSchema = new mongoose.Schema(
  {
    className: { type: String, required: true, trim: true, unique: true }, // e.g. "BSCS-1st", "Grade 5"
    section: { type: String, trim: true, default: 'A' },
    classTeacher: { type: mongoose.Schema.Types.ObjectId, ref: 'Staff' },
    subjects: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Subject' }],
    totalStudents: { type: Number, default: 0 },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Class', classSchema);