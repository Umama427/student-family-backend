const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Admin',
      required: true,
    },
    userName: {
      type: String,
      required: true,
    },
    action: {
      type: String,
      required: true,
      enum: ['CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT'],
    },
    module: {
      type: String,
      required: true,
      // e.g., "Student", "Fee Challan", "Attendance", "Staff"
    },
    description: {
      type: String,
      required: true,
      // e.g., "Deleted student John Doe (ID: 123)"
    },
    targetId: {
      type: mongoose.Schema.Types.ObjectId,
      default: null,
      // ID of the record that was affected
    },
    ipAddress: {
      type: String,
      default: null,
    },
    oldData: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
      // Store previous data for UPDATE/DELETE actions
    },
    newData: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
      // Store new data for CREATE/UPDATE actions
    },
  },
  { timestamps: true }
);

// Index for faster queries
auditLogSchema.index({ createdAt: -1 });
auditLogSchema.index({ user: 1, createdAt: -1 });
auditLogSchema.index({ module: 1 });

module.exports = mongoose.model('AuditLog', auditLogSchema);