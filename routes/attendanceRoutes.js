const express = require('express');
const router = express.Router();
const {
  markAttendance,
  bulkMarkAttendance,
  getAttendance,
  getAttendanceSummary,
  getDailyRoster,
  deleteAttendance,
} = require('../controllers/attendanceController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.post('/', protect, authorize('admin', 'teacher'), markAttendance);
router.post('/bulk', protect, authorize('admin', 'teacher'), bulkMarkAttendance);

router.get('/', protect, authorize('admin', 'teacher', 'parent'), getAttendance);
router.get('/summary', protect, authorize('admin', 'teacher', 'parent'), getAttendanceSummary);
router.get('/roster', protect, authorize('admin', 'teacher', 'parent'), getDailyRoster);

router.delete('/:id', protect, authorize('admin'), deleteAttendance);

module.exports = router;