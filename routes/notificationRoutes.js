const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const {
  createNotification,
  getNotifications,
  markAsRead,
  deleteNotification,
} = require('../controllers/notificationController');

// ✅ All roles can view (filtered by audience in controller)
router.get('/', protect, authorize('admin', 'teacher', 'parent'), getNotifications);

// ✅ All roles can mark as read
router.put('/:id/read', protect, authorize('admin', 'teacher', 'parent'), markAsRead);

// Admin-only: create & delete
router.post('/', protect, authorize('admin'), createNotification);
router.delete('/:id', protect, authorize('admin'), deleteNotification);

module.exports = router;