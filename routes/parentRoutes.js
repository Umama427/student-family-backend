const express = require('express');
const router = express.Router();
const {
  getMyProfile,
  getMyChildren,
  getChildChallans,
  getChildAttendance,
  getChildResults,
  getMyNotifications,
} = require('../controllers/parentController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect, authorize('parent'));

router.get('/me', getMyProfile);
router.get('/my-children', getMyChildren);
router.get('/children/:studentId/challans', getChildChallans);
router.get('/children/:studentId/attendance', getChildAttendance);
router.get('/children/:studentId/results', getChildResults);
router.get('/notifications', getMyNotifications);

module.exports = router;