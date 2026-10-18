const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const { bulkGenerateChallans, bulkEnterResults } = require('../controllers/bulkController');

router.post('/challans', protect, authorize('admin'), bulkGenerateChallans);
router.post('/results', protect, authorize('admin', 'teacher'), bulkEnterResults);

module.exports = router;