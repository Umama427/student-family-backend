const express = require('express');
const router = express.Router();
const {
  getFeeReminderLink,
  getPaymentConfirmationLink,
  getAnnouncementLink,
  getBulkAnnouncementLinks,
  getSalaryWhatsAppLink
} = require('../controllers/whatsappController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.use(protect, authorize('admin'));

router.get('/fee-reminder/:challanId', getFeeReminderLink);
router.get('/payment-confirmation/:challanId', getPaymentConfirmationLink);
router.post('/announcement/:familyId', getAnnouncementLink);
router.post('/bulk-announcement', getBulkAnnouncementLinks);
router.get('/salary/:salaryId', getSalaryWhatsAppLink);

module.exports = router;