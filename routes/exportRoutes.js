const express = require('express');
const router = express.Router();
const { exportModule } = require('../controllers/exportController');
const { protect, authorize } = require('../middleware/authMiddleware');

// ✅ Sirf admin export kar sakta hai (frontend me ExportButton bhi RoleGuard['admin'] hi hai)
router.get('/:module', protect, authorize('admin'), exportModule);

module.exports = router;