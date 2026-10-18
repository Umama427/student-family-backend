const mongoose = require('mongoose');

const otherChargeSchema = new mongoose.Schema(
  {
    description: { type: String, trim: true },
    label: { type: String, trim: true },
    amount: { type: Number, default: 0 },
  },
  { _id: false }
);

const feeChallanSchema = new mongoose.Schema(
  {
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      required: true,
    },
    familyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Family',
      required: true,
    },

    challanNumber: { type: String, unique: true, sparse: true },

    month: { type: Number, required: true, min: 1, max: 12 },
    year: { type: Number, required: true },

    tuitionFee: { type: Number, default: 0 },
    otherCharges: { type: [otherChargeSchema], default: [] },
    discountPercentage: { type: Number, default: 0 },
    discountAmount: { type: Number, default: 0 },

    penaltyAmount: { type: Number, default: 0 },
    penaltyApplied: { type: Boolean, default: false },

    totalPayable: { type: Number, required: true, default: 0 },

    paidAmount: { type: Number, default: 0 },
    paymentMethod: {
      type: String,
      enum: ['Cash', 'Bank Transfer', 'JazzCash', 'EasyPaisa', 'Cheque', 'Other'],
      default: 'Cash',
    },
    paidDate: { type: Date },

    dueDate: { type: Date, required: true },

    status: {
      type: String,
      enum: ['Pending', 'Paid', 'Overdue', 'Partial'],
      default: 'Pending',
    },

    remarks: { type: String, trim: true },
  },
  { timestamps: true }
);

feeChallanSchema.index({ studentId: 1, month: 1, year: 1 }, { unique: true });

feeChallanSchema.virtual('netPayable').get(function () {
  return this.totalPayable;
});

feeChallanSchema.virtual('amount').get(function () {
  return this.totalPayable;
});

feeChallanSchema.pre('save', async function () {
  if (!this.challanNumber) {
    const yearMonth = `${this.year}${String(this.month).padStart(2, '0')}`;
    const count = await mongoose.model('FeeChallan').countDocuments();
    this.challanNumber = `CHL-${yearMonth}-${String(count + 1).padStart(5, '0')}`;
  }
});

feeChallanSchema.set('toJSON', { virtuals: true });
feeChallanSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('FeeChallan', feeChallanSchema, 'feechallans');