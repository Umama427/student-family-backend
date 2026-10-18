const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const {
  createClass,
  getClasses,
  getClassById,
  updateClass,
  deleteClass,
} = require('../controllers/classController');

// ✅ All logged-in roles can view
router.get('/', protect, getClasses);
router.get('/:id', protect, getClassById);

// ✅ FIX: Sirf Admin create/update/delete kar sake
router.post('/', protect, authorize('admin'), createClass);
router.put('/:id', protect, authorize('admin'), updateClass);
router.delete('/:id', protect, authorize('admin'), deleteClass);

module.exports = router;