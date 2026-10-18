const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/authMiddleware');
const feeChallanController = require('../controllers/feeChallanController');

router.post('/', protect, authorize('admin'), feeChallanController.createChallan);
router.post('/bulk', protect, authorize('admin'), feeChallanController.generateBulkChallans);
router.post('/auto-generate-monthly', protect, authorize('admin'), feeChallanController.autoGenerateMonthlyChallans);
router.post('/apply-penalty', protect, authorize('admin'), feeChallanController.applyPenaltyOnOverdue);
router.get('/dashboard/summary', protect, authorize('admin'), feeChallanController.getDashboardSummary);

router.get('/', protect, authorize('admin', 'parent'), feeChallanController.getChallans);
router.get('/:id', protect, authorize('admin', 'parent'), feeChallanController.getChallanById);
router.get('/:id/pdf', protect, authorize('admin', 'parent'), feeChallanController.downloadChallanPDF);
router.get('/:id/receipt', protect, authorize('admin', 'parent'), feeChallanController.downloadReceiptPDF);

router.put('/:id', protect, authorize('admin'), feeChallanController.updateChallan);
router.put('/:id/pay', protect, authorize('admin'), feeChallanController.recordPayment);
router.delete('/:id', protect, authorize('admin'), feeChallanController.deleteChallan);

module.exports = router;