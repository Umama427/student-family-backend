const Notification = require('../models/Notification');

// @desc   Create notification (Admin only)
exports.createNotification = async (req, res) => {
  try {
    const { title, message, type, audience } = req.body;

    if (!title || !message) {
      return res.status(400).json({ success: false, message: 'Title and message are required' });
    }

    const notification = await Notification.create({ title, message, type, audience });
    res.status(201).json({ success: true, data: notification });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Get notifications (Role-filtered by audience)
// Model enum: ['all', 'students', 'staff', 'families']
exports.getNotifications = async (req, res) => {
  try {
    const { type } = req.query;
    const filter = {};
    if (type) filter.type = type;

    // ✅ Role-based audience filtering (matches actual model enum)
    if (req.role === 'teacher') {
      filter.audience = { $in: ['all', 'staff'] };
    } else if (req.role === 'parent') {
      filter.audience = { $in: ['all', 'families'] };
    } else if (req.query.audience) {
      filter.audience = req.query.audience; // admin optional filter
    }

    const notifications = await Notification.find(filter).sort({ createdAt: -1 }).limit(100);
    res.status(200).json({ success: true, count: notifications.length, data: notifications });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Mark as read (all roles)
exports.markAsRead = async (req, res) => {
  try {
    const notification = await Notification.findByIdAndUpdate(
      req.params.id,
      { isRead: true },
      { new: true }
    );
    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    res.status(200).json({ success: true, data: notification });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Delete notification (Admin only)
exports.deleteNotification = async (req, res) => {
  try {
    const notification = await Notification.findByIdAndDelete(req.params.id);
    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }
    res.status(200).json({ success: true, message: 'Notification deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};