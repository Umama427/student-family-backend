const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    message: { type: String, required: true, trim: true },
    type: {
      type: String,
      enum: ['general', 'emergency', 'fee', 'attendance'],
      default: 'general',
    },
    audience: {
      type: String,
      enum: ['all', 'students', 'staff', 'families'],
      default: 'all',
    },
    isRead: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Notification', notificationSchema);