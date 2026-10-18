const express = require('express');
const router = express.Router();
const {
  getAuditLogs,
  getAuditLogById,
  getAuditSummary,
} = require('../controllers/auditLogController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect, authorize('admin'));

router.get('/', getAuditLogs);
router.get('/summary', getAuditSummary);
router.get('/:id', getAuditLogById);

module.exports = router;