const AuditLog = require('../models/AuditLog');

const logAction = async ({
  admin,
  action,
  module,
  description,
  targetId = null,
  ipAddress = null,
  oldData = null,
  newData = null,
}) => {
  try {
    if (!admin || !admin._id) {
      console.error('Audit log skipped: user object missing or invalid');
      return;
    }

    // ✅ familyName bhi fallback mein add kiya (Parent actions ke liye)
    const userName =
      admin.name || admin.fullName || admin.familyName || admin.email || admin.username || 'Unknown User';

    await AuditLog.create({
      user: admin._id,
      userName,
      action,
      module,
      description,
      targetId,
      ipAddress,
      oldData,
      newData,
    });
  } catch (error) {
    console.error('Audit log error:', error.message);
  }
};

module.exports = { logAction };