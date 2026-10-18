const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema(
  {
    familyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Family',
      required: true,
    },
    fullName: { type: String, required: true, trim: true },
    rollNumber: { type: String, unique: true, sparse: true },
    className: { type: String, trim: true },
    gender: { type: String, enum: ['male', 'female', 'other'], default: 'male' },
    siblingOrder: { type: Number, default: 1 },
    discountPercentage: { type: Number, default: 0 },
    monthlyTuitionFee: { type: Number, default: 0 },
    contactNumber: { type: String, trim: true, default: null },
    admissionDate: { type: Date, default: Date.now },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },

    // Progress tracking (used by updateProgress in studentController)
    progress: {
      attendancePercentage: { type: Number, default: 0 },
      currentGPA: { type: Number, default: 0 },
      remarks: { type: String, default: '' },
    },
  },
  { timestamps: true }
);

// Auto-generate rollNumber like STU-00001
studentSchema.pre('save', async function () {
  if (this.isNew && !this.rollNumber) {
    const count = await mongoose.model('Student').countDocuments();
    const randomSuffix = Math.floor(10 + Math.random() * 89); // avoid race-condition duplicates
    this.rollNumber = `STU-${String(count + 1).padStart(5, '0')}-${randomSuffix}`;
  }
});

module.exports = mongoose.model('Student', studentSchema, 'students');