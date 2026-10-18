const mongoose = require('mongoose');

const supportMessageSchema = new mongoose.Schema(
  {
    senderName: { type: String, required: true, trim: true },
    senderEmail: { type: String, trim: true, lowercase: true },
    senderRole: { type: String, enum: ['teacher', 'parent', 'admin'], required: true },
    senderId: { type: mongoose.Schema.Types.ObjectId, required: true },
    subject: { type: String, required: true, trim: true },
    message: { type: String, required: true, trim: true },
    status: { type: String, enum: ['open', 'resolved'], default: 'open' },
    adminReply: { type: String, default: '' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('SupportMessage', supportMessageSchema);