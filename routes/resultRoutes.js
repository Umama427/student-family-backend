const express = require('express');
const router = express.Router();
const {
  createResult,
  bulkCreateResults,
  getResultsByExam,
  getResultsByStudent,
  getResultById,
  updateResult,
  deleteResult,
  getClassSummary,
} = require('../controllers/resultController');
const { protect, authorize } = require('../middleware/authMiddleware');

// ✅ Admin + Teacher: Create/Bulk-create (filtered to own class in controller)
router.post('/', protect, authorize('admin', 'teacher'), createResult);
router.post('/bulk', protect, authorize('admin', 'teacher'), bulkCreateResults);

// ✅ All 3 roles can view (filtered in controller)
router.get('/by-exam/:examId', protect, authorize('admin', 'teacher', 'parent'), getResultsByExam);
router.get('/by-student/:studentId', protect, authorize('admin', 'teacher', 'parent'), getResultsByStudent);
router.get('/class-summary/:examId', protect, authorize('admin', 'teacher'), getClassSummary);

router
  .route('/:id')
  .get(protect, authorize('admin', 'teacher', 'parent'), getResultById)
  .put(protect, authorize('admin', 'teacher'), updateResult)
  .delete(protect, authorize('admin'), deleteResult);

module.exports = router;