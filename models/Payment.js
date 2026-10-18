const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema(
  {
    challanId: { type: mongoose.Schema.Types.ObjectId, ref: 'FeeChallan', required: true },
    studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student' },
    familyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Family' },
    amount: { type: Number, required: true },
    method: { type: String, enum: ['Stripe', 'JazzCash', 'EasyPaisa'], required: true },
    provider: { type: String },
    providerTransactionId: { type: String, index: true },
    status: { type: String, enum: ['Pending', 'Success', 'Failed'], default: 'Pending' },
    rawResponse: { type: mongoose.Schema.Types.Mixed },
    paidAt: { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Payment', paymentSchema);