const express = require('express');
const router = express.Router();
const {
  createStudent,
  getStudents,
  getStudentById,
  updateStudent,
  deleteStudent,
  updateProgress,
} = require('../controllers/studentController');
const { protect, authorize } = require('../middleware/authMiddleware');

// ❌ REMOVED: router.use(protect, authorize('admin')); — ye sab block kar raha tha

// ✅ All 3 roles can VIEW (data auto-filtered in controller)
router.get('/', protect, authorize('admin', 'teacher', 'parent'), getStudents);
router.get('/:id', protect, authorize('admin', 'teacher', 'parent'), getStudentById);

// ✅ Only Admin can CREATE/UPDATE/DELETE
router.post('/', protect, authorize('admin'), createStudent);
router.put('/:id', protect, authorize('admin'), updateStudent);
router.delete('/:id', protect, authorize('admin'), deleteStudent);

// ✅ Admin + Teacher can update progress (marks/attendance remarks)
router.put('/:id/progress', protect, authorize('admin', 'teacher'), updateProgress);

module.exports = router;