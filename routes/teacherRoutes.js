const express = require('express');
const router = express.Router();
const {
  getMyProfile,
  getMyStudents,
  getMyExams,
  getMyClassExamResults,
  enterMarks,
  markStudentAttendance,
  bulkMarkStudentAttendance,
  getMyClassAttendance,
} = require('../controllers/teacherController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect, authorize('teacher'));

router.get('/me', getMyProfile);
router.get('/my-students', getMyStudents);
router.get('/my-exams', getMyExams);
router.get('/exam-results/:examId', getMyClassExamResults);
router.post('/enter-marks', enterMarks);

// ✅ Attendance routes
router.post('/mark-attendance', markStudentAttendance);
router.post('/bulk-mark-attendance', bulkMarkStudentAttendance);
router.get('/attendance', getMyClassAttendance);

module.exports = router;