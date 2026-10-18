const express = require('express');
const router = express.Router();
const {
  registerAdmin,
  loginAdmin,
  forgotPassword,
  resetPassword,
  getMe,
  loginTeacher,
  loginParent,
  setStaffCredentials,
  setFamilyPin,
} = require('../controllers/authController');
const { protect, authorize } = require('../middleware/authMiddleware');

// ===== Admin Auth (existing) =====
router.post('/register', registerAdmin);
router.post('/login', loginAdmin);
router.post('/forgot-password', forgotPassword);
router.put('/reset-password/:token', resetPassword);
router.get('/me', protect, authorize('admin'), getMe);

// ===== ✅ Teacher & Parent Login (New) =====
router.post('/teacher/login', loginTeacher);
router.post('/parent/login', loginParent);

// ===== ✅ Admin Utilities: Manage Portal Access (New) =====
router.put('/admin/set-staff-credentials/:staffId', protect, authorize('admin'), setStaffCredentials);
router.put('/admin/set-family-pin/:familyId', protect, authorize('admin'), setFamilyPin);

module.exports = router;