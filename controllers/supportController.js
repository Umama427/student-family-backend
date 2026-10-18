const SupportMessage = require('../models/SupportMessage');

// @desc   Create a new support message (Teacher/Parent/Admin)
// @route  POST /api/support
exports.createSupportMessage = async (req, res) => {
  try {
    const { senderName, senderEmail, subject, message } = req.body;

    if (!senderName || !subject || !message) {
      return res.status(400).json({
        success: false,
        message: 'senderName, subject and message are required',
      });
    }

    const supportMessage = await SupportMessage.create({
      senderName,
      senderEmail,
      senderRole: req.role,
      senderId: req.role === 'admin' ? req.admin : req.user._id,
      subject,
      message,
    });

    res.status(201).json({
      success: true,
      message: 'Message sent successfully',
      data: supportMessage,
    });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Get all support messages (Admin only)
// @route  GET /api/support
exports.getSupportMessages = async (req, res) => {
  try {
    const filter = {};
    if (req.query.status) filter.status = req.query.status;

    const messages = await SupportMessage.find(filter).sort({ createdAt: -1 });
    res.status(200).json({ success: true, count: messages.length, data: messages });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get logged-in user's own support messages
// @route  GET /api/support/my
exports.getMyMessages = async (req, res) => {
  try {
    const messages = await SupportMessage.find({ senderId: req.user._id }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, count: messages.length, data: messages });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Mark a support message as resolved + optional admin reply (Admin only)
// @route  PUT /api/support/:id/resolve
exports.resolveSupportMessage = async (req, res) => {
  try {
    const { adminReply } = req.body;
    const updated = await SupportMessage.findByIdAndUpdate(
      req.params.id,
      { status: 'resolved', adminReply: adminReply || '' },
      { new: true }
    );
    if (!updated) {
      return res.status(404).json({ success: false, message: 'Message not found' });
    }
    res.status(200).json({ success: true, data: updated });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Delete a support message (Admin only)
// @route  DELETE /api/support/:id
exports.deleteSupportMessage = async (req, res) => {
  try {
    const deleted = await SupportMessage.findByIdAndDelete(req.params.id);
    if (!deleted) {
      return res.status(404).json({ success: false, message: 'Message not found' });
    }
    res.status(200).json({ success: true, message: 'Message deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};