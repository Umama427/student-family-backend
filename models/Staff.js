const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const staffSchema = new mongoose.Schema(
  {
    staffCode: { type: String, unique: true },
    fullName: { type: String, required: true, trim: true },
    email: { type: String, trim: true, lowercase: true },

    // ✅ FIXED: Sirf ek field rakho — 'phone'
    phone: { type: String, trim: true, required: true },

    department: { type: String, default: 'General' },
    designation: { type: String, default: 'Teacher' },
    basicSalary: { type: Number, required: true, default: 0 },
    baseSalary: { type: Number, default: 0 },
    status: { type: String, enum: ['active', 'inactive'], default: 'active' },
    joiningDate: { type: Date, default: Date.now },

    password: { type: String, select: false },
    hasPortalAccess: { type: Boolean, default: false },

    // ✅ FIXED: Default empty array hamesha set rahega (consistency ke liye)
    assignedClasses: { type: [String], default: [] },

    // ✅ NEW: Teacher ko assign ki gayi subjects (subject NAMES store honge,
    // 'assignedClasses' wale pattern ki tarah — consistency ke liye)
    assignedSubjects: { type: [String], default: [] },
  },
  { timestamps: true }
);

staffSchema.pre('save', async function () {
  if (this.isNew && !this.staffCode) {
    const count = await mongoose.model('Staff').countDocuments();
    this.staffCode = `STF-${String(count + 1).padStart(4, '0')}`;
  }

  if (this.isModified('password') && this.password) {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    this.hasPortalAccess = true;
  }
});

staffSchema.methods.matchPassword = async function (enteredPassword) {
  return bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('Staff', staffSchema, 'staffs');