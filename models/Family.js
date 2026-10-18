const mongoose = require('mongoose');

const familySchema = new mongoose.Schema(
  {
    familyCode: { type: String, unique: true },
    familyName: { type: String, required: true, trim: true },
    fatherName: { type: String, required: true, trim: true },
    motherName: { type: String, trim: true },
    primaryPhone: { type: String, required: true, unique: true, trim: true },
    alternatePhone: { type: String, trim: true },
    email: { type: String, lowercase: true, trim: true },
    address: { type: String, trim: true },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },

    // Student/Parent Portal access (login via familyCode + primaryPhone + pin)
    portalPin: { type: String, default: '0000' }, // 4-digit pin, admin can change later
  },
  { timestamps: true }
);

// Virtual: linked students for the Sibling Tree UI
familySchema.virtual('students', {
  ref: 'Student',
  localField: '_id',
  foreignField: 'familyId',
});

// Virtual: quick sibling count (needs populate to work properly, but defined for clarity)
familySchema.virtual('siblingCount').get(function () {
  return this.students ? this.students.length : 0;
});

familySchema.set('toJSON', { virtuals: true });
familySchema.set('toObject', { virtuals: true });

// Auto-generate familyCode like FAM-0001 (with random suffix to avoid race-condition duplicates)
familySchema.pre('save', async function () {
  if (!this.familyCode) {
    const count = await mongoose.model('Family').countDocuments();
    const randomSuffix = Math.floor(100 + Math.random() * 899); // avoids collision in bulk inserts
    this.familyCode = `FAM-${String(count + 1).padStart(4, '0')}-${randomSuffix}`;
  }
});

module.exports = mongoose.model('Family', familySchema, 'families');