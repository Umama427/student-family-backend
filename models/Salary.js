const mongoose = require('mongoose');

const salarySchema = new mongoose.Schema(
  {
    staffId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Staff',
      required: true,
    },
    month: { type: String, required: true },
    year: { type: Number, required: true },
    baseSalary: { type: Number, required: true },
    bonus: { type: Number, default: 0 },
    deductions: { type: Number, default: 0 },
    netSalary: { type: Number, required: true },
    status: { type: String, enum: ['Paid', 'Pending'], default: 'Paid' },
    paymentMethod: { type: String, default: 'Cash' },
    paymentDate: { type: Date },
    remarks: { type: String },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Salary', salarySchema);