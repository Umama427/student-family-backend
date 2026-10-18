const express = require('express');
const router = express.Router();
const {
  getDashboardSummary,
  getRevenueTrend,
  getSalarySummary,
} = require('../controllers/dashboardController');
const { protect, authorize } = require('../middleware/authMiddleware');

// ✅ All roles can see summary (role-filtered inside controller)
router.get('/summary', protect, authorize('admin', 'teacher', 'parent'), getDashboardSummary);

// ✅ Financial/Salary data — Admin only (sensitive)
router.get('/revenue-trend', protect, authorize('admin'), getRevenueTrend);
router.get('/salary-summary', protect, authorize('admin'), getSalarySummary);

module.exports = router;