const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ['student', 'staff'], required: true },
    refId: { type: mongoose.Schema.Types.ObjectId, required: true, refPath: 'refModel' },
    refModel: { type: String, required: true, enum: ['Student', 'Staff'] },
    date: { type: Date, required: true, default: Date.now },
    status: { type: String, enum: ['Present', 'Absent', 'Leave', 'Late'], default: 'Present' },
    remarks: { type: String, trim: true },
  },
  { timestamps: true }
);

attendanceSchema.index({ refId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', attendanceSchema);