const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { protect, protectFlexible, authorize } = require('../middleware/authMiddleware');

// ---- Protected via Authorization header: called by Flutter app's normal API calls ----
router.post('/stripe/create-session', protect, authorize('admin', 'parent'), paymentController.createStripeCheckout);
router.get('/stripe/verify/:sessionId', protect, authorize('admin', 'parent'), paymentController.verifyStripeSession);
router.get('/status/:challanId', protect, authorize('admin', 'parent'), paymentController.getPaymentStatus);

// ---- Protected via query/body token: these are full browser page loads (url_launcher),
//      custom headers can't be attached, so token travels in the URL / form field ----
router.get('/jazzcash/redirect/:challanId', protectFlexible, authorize('admin', 'parent'), paymentController.jazzCashRedirectPage);
router.get('/easypaisa/redirect/:challanId', protectFlexible, authorize('admin', 'parent'), paymentController.easyPaisaRedirectPage);
router.post(
  '/demo/confirm',
  express.urlencoded({ extended: true }),
  protectFlexible,
  authorize('admin', 'parent'),
  paymentController.demoConfirmPayment
);

// ---- Public: called directly BY the payment gateways' servers, never by our app ----
// (JazzCash/EasyPaisa postback + Stripe webhook can't send our JWT — they verify via
//  their own signature/hash mechanisms instead, which is already implemented.)
router.post('/jazzcash/return', express.urlencoded({ extended: true }), paymentController.jazzCashReturn);
router.post('/easypaisa/return', express.urlencoded({ extended: true }), paymentController.easyPaisaReturn);
router.post('/stripe/webhook', express.raw({ type: 'application/json' }), paymentController.stripeWebhook);

module.exports = router;