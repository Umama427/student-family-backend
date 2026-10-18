const express = require('express');
const router = express.Router();
const {
  createSupportMessage,
  getSupportMessages,
  getMyMessages,
  resolveSupportMessage,
  deleteSupportMessage,
} = require('../controllers/supportController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.post('/', protect, authorize('admin', 'teacher', 'parent'), createSupportMessage);
router.get('/', protect, authorize('admin'), getSupportMessages);
router.get('/my', protect, authorize('teacher', 'parent'), getMyMessages);
router.put('/:id/resolve', protect, authorize('admin'), resolveSupportMessage);
router.delete('/:id', protect, authorize('admin'), deleteSupportMessage);

module.exports = router;