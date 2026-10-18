const express = require('express');
const router = express.Router();
const {
  createExam,
  getExams,
  getExamById,
  updateExam,
  deleteExam,
} = require('../controllers/examController');
const { protect, authorize } = require('../middleware/authMiddleware');

// ✅ All roles can view (filtered in controller)
router.get('/', protect, authorize('admin', 'teacher', 'parent'), getExams);
router.get('/:id', protect, authorize('admin', 'teacher', 'parent'), getExamById);

// ✅ Only Admin can create/update/delete
router.post('/', protect, authorize('admin'), createExam);
router.put('/:id', protect, authorize('admin'), updateExam);
router.delete('/:id', protect, authorize('admin'), deleteExam);

module.exports = router;