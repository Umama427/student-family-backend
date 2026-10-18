const crypto = require('crypto');
const Stripe = require('stripe');
const Payment = require('../models/Payment');
const FeeChallan = require('../models/FeeChallan');

const stripe = process.env.STRIPE_SECRET_KEY ? Stripe(process.env.STRIPE_SECRET_KEY) : null;

// ================= STRIPE =================
exports.createStripeCheckout = async (req, res) => {
  try {
    if (!stripe) {
      return res.status(503).json({ success: false, message: 'Stripe not configured. Add STRIPE_SECRET_KEY in .env' });
    }
    const { challanId } = req.body;
    const challan = await FeeChallan.findById(challanId).populate('studentId');
    if (!challan) return res.status(404).json({ success: false, message: 'Challan not found' });

    const remaining = Number(challan.totalPayable) - Number(challan.paidAmount || 0);
    if (remaining <= 0) {
      return res.status(400).json({ success: false, message: 'Challan already paid' });
    }

    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      line_items: [
        {
          price_data: {
            currency: 'pkr',
            product_data: {
              name: `Fee Challan #${challan.challanNumber}`,
              description: `${challan.studentId?.fullName || 'Student'} - ${challan.month}/${challan.year}`,
            },
            unit_amount: Math.round(remaining * 100),
          },
          quantity: 1,
        },
      ],
      success_url: `${process.env.CLIENT_URL}?payment=success&challanId=${challan._id}&session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.CLIENT_URL}?payment=cancel&challanId=${challan._id}`,
      metadata: { challanId: challan._id.toString() },
    });

    await Payment.create({
      challanId: challan._id,
      studentId: challan.studentId?._id,
      familyId: challan.familyId,
      amount: remaining,
      method: 'Stripe',
      provider: 'stripe_checkout',
      providerTransactionId: session.id,
      status: 'Pending',
    });

    res.json({ success: true, url: session.url });
  } catch (err) {
    console.error('Stripe checkout error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.verifyStripeSession = async (req, res) => {
  try {
    if (!stripe) {
      return res.status(503).json({ success: false, message: 'Stripe not configured' });
    }
    const { sessionId } = req.params;
    const session = await stripe.checkout.sessions.retrieve(sessionId);

    if (!session) {
      return res.status(404).json({ success: false, message: 'Session not found' });
    }

    const payment = await Payment.findOne({ providerTransactionId: session.id });
    if (!payment) {
      return res.status(404).json({ success: false, message: 'Payment record not found' });
    }

    if (session.payment_status === 'paid') {
      if (payment.status !== 'Success') {
        payment.status = 'Success';
        payment.paidAt = new Date();
        payment.rawResponse = session;
        await payment.save();

        const challan = await FeeChallan.findById(payment.challanId);
        if (challan) {
          challan.paidAmount = Number(challan.paidAmount || 0) + Number(payment.amount);
          challan.status = challan.paidAmount >= challan.totalPayable ? 'Paid' : 'Partial';
          challan.paidDate = new Date();
          challan.paymentMethod = 'Stripe';
          await challan.save();
        }
      }
      return res.json({ success: true, status: 'Paid', challanId: payment.challanId });
    } else {
      return res.json({ success: true, status: 'Pending' });
    }
  } catch (err) {
    console.error('Verify stripe session error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.stripeWebhook = async (req, res) => {
  if (!stripe || !process.env.STRIPE_WEBHOOK_SECRET) {
    return res.status(503).send('Stripe webhook not configured');
  }
  const sig = req.headers['stripe-signature'];
  let event;
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    try {
      const payment = await Payment.findOne({ providerTransactionId: session.id });
      if (payment && payment.status !== 'Success') {
        payment.status = 'Success';
        payment.paidAt = new Date();
        payment.rawResponse = session;
        await payment.save();

        const challan = await FeeChallan.findById(payment.challanId);
        if (challan) {
          challan.paidAmount = Number(challan.paidAmount || 0) + Number(payment.amount);
          challan.status = challan.paidAmount >= challan.totalPayable ? 'Paid' : 'Partial';
          challan.paidDate = new Date();
          challan.paymentMethod = 'Stripe';
          await challan.save();
        }
      }
    } catch (err) {
      console.error('Error processing stripe webhook:', err);
    }
  }

  res.json({ received: true });
};

// ================= JAZZCASH =================
function jazzCashSortedHash(params, salt) {
  const sortedKeys = Object.keys(params).sort();
  let str = salt;
  sortedKeys.forEach((key) => {
    if (params[key] !== '' && params[key] !== undefined && params[key] !== null) {
      str += `&${params[key]}`;
    }
  });
  return crypto.createHmac('sha256', salt).update(str).digest('hex');
}

function demoPaymentPage({ gatewayName, color, challanId, remaining, studentName, challanNumber, token }) {
  return `
    <html>
      <head>
        <title>${gatewayName} - Demo Payment</title>
        <style>
          body { font-family: Arial, sans-serif; background:#f4f7fb; display:flex; align-items:center; justify-content:center; height:100vh; margin:0; }
          .card { background:#fff; padding:40px; border-radius:16px; box-shadow:0 8px 24px rgba(0,0,0,0.1); text-align:center; width:380px; }
          .badge { background:#FFF3CD; color:#8A6D1D; padding:6px 14px; border-radius:20px; font-size:12px; font-weight:bold; display:inline-block; margin-bottom:16px; }
          .logo { font-size:22px; font-weight:bold; color:${color}; margin-bottom:6px; }
          .amount { font-size:28px; font-weight:bold; margin:16px 0; color:#111; }
          .btn { background:${color}; color:#fff; border:none; padding:14px 24px; border-radius:10px; font-size:15px; font-weight:bold; width:100%; cursor:pointer; margin-top:10px; }
          .btn-cancel { background:#eee; color:#333; }
          .info { color:#666; font-size:13px; margin:4px 0; }
          form { margin-top:10px; }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="badge">⚠ DEMO MODE — Merchant credentials pending</div>
          <div class="logo">${gatewayName}</div>
          <div class="info">${studentName || 'Student'} • Challan #${challanNumber}</div>
          <div class="amount">Rs. ${Number(remaining).toLocaleString()}</div>
          <form method="POST" action="/api/payments/demo/confirm">
            <input type="hidden" name="challanId" value="${challanId}" />
            <input type="hidden" name="gateway" value="${gatewayName}" />
            <input type="hidden" name="token" value="${token || ''}" />
            <button class="btn" type="submit">✅ Simulate Successful Payment</button>
          </form>
          <form method="GET" action="${process.env.CLIENT_URL || '/'}">
            <button class="btn btn-cancel" type="submit">Cancel</button>
          </form>
        </div>
      </body>
    </html>
  `;
}

exports.jazzCashRedirectPage = async (req, res) => {
  try {
    const challan = await FeeChallan.findById(req.params.challanId).populate('studentId');
    if (!challan) return res.status(404).send('Challan not found');
    const remaining = Number(challan.totalPayable) - Number(challan.paidAmount || 0);

    // ---- DEMO MODE: real merchant credentials not yet available ----
    if (!process.env.JAZZCASH_MERCHANT_ID || !process.env.JAZZCASH_PASSWORD || !process.env.JAZZCASH_INTEGRITY_SALT) {
      return res.send(
        demoPaymentPage({
          gatewayName: 'JazzCash',
          color: '#D4145A',
          challanId: challan._id,
          remaining,
          studentName: challan.studentId?.fullName,
          challanNumber: challan.challanNumber,
          token: req.authToken,
        })
      );
    }

    const now = new Date();
    const txnDateTime = now.toISOString().replace(/[-:T.Z]/g, '').slice(0, 14);
    const expiry = new Date(now.getTime() + 60 * 60 * 1000)
      .toISOString()
      .replace(/[-:T.Z]/g, '')
      .slice(0, 14);
    const txnRefNo = `T${Date.now()}`;

    const params = {
      pp_Version: '1.1',
      pp_TxnType: 'MWALLET',
      pp_Language: 'EN',
      pp_MerchantID: process.env.JAZZCASH_MERCHANT_ID,
      pp_Password: process.env.JAZZCASH_PASSWORD,
      pp_TxnRefNo: txnRefNo,
      pp_Amount: Math.round(remaining * 100).toString(),
      pp_TxnCurrency: 'PKR',
      pp_TxnDateTime: txnDateTime,
      pp_BillReference: challan.challanNumber,
      pp_Description: `Fee Challan ${challan.challanNumber}`,
      pp_TxnExpiryDateTime: expiry,
      pp_ReturnURL: `${process.env.SERVER_URL}/api/payments/jazzcash/return`,
    };
    params.pp_SecureHash = jazzCashSortedHash(params, process.env.JAZZCASH_INTEGRITY_SALT);

    await Payment.create({
      challanId: challan._id,
      studentId: challan.studentId?._id,
      familyId: challan.familyId,
      amount: remaining,
      method: 'JazzCash',
      provider: 'jazzcash',
      providerTransactionId: txnRefNo,
      status: 'Pending',
    });

    const inputs = Object.entries(params)
      .map(([k, v]) => `<input type="hidden" name="${k}" value="${v}">`)
      .join('');

    res.send(`
      <html><body onload="document.forms[0].submit()">
        <form action="${process.env.JAZZCASH_SANDBOX_URL}" method="POST">
          ${inputs}
        </form>
        <p>Redirecting to JazzCash...</p>
      </body></html>
    `);
  } catch (err) {
    console.error('JazzCash redirect error:', err);
    res.status(500).send('JazzCash error: ' + err.message);
  }
};

exports.jazzCashReturn = async (req, res) => {
  try {
    const { pp_TxnRefNo, pp_ResponseCode, pp_ResponseMessage } = req.body;
    const payment = await Payment.findOne({ providerTransactionId: pp_TxnRefNo });
    if (payment) {
      payment.rawResponse = req.body;
      if (pp_ResponseCode === '000') {
        payment.status = 'Success';
        payment.paidAt = new Date();
        await payment.save();

        const challan = await FeeChallan.findById(payment.challanId);
        if (challan) {
          challan.paidAmount = Number(challan.paidAmount || 0) + Number(payment.amount);
          challan.status = challan.paidAmount >= challan.totalPayable ? 'Paid' : 'Partial';
          challan.paidDate = new Date();
          challan.paymentMethod = 'JazzCash';
          await challan.save();
        }
      } else {
        payment.status = 'Failed';
        await payment.save();
      }
    }
    res.send(`
      <html><body>
        <h2>${pp_ResponseCode === '000' ? '✅ Payment Successful' : '❌ Payment Failed'}</h2>
        <p>${pp_ResponseMessage || ''}</p>
        <a href="${process.env.CLIENT_URL}">Return to App</a>
      </body></html>
    `);
  } catch (err) {
    console.error('JazzCash return error:', err);
    res.status(500).send('Error processing JazzCash return');
  }
};

// ================= EASYPAISA =================
exports.easyPaisaRedirectPage = async (req, res) => {
  try {
    const challan = await FeeChallan.findById(req.params.challanId).populate('studentId');
    if (!challan) return res.status(404).send('Challan not found');
    const remaining = Number(challan.totalPayable) - Number(challan.paidAmount || 0);

    // ---- DEMO MODE: real merchant credentials not yet available ----
    if (!process.env.EASYPAISA_STORE_ID || !process.env.EASYPAISA_HASH_KEY) {
      return res.send(
        demoPaymentPage({
          gatewayName: 'EasyPaisa',
          color: '#2E8B57',
          challanId: challan._id,
          remaining,
          studentName: challan.studentId?.fullName,
          challanNumber: challan.challanNumber,
          token: req.authToken,
        })
      );
    }

    const orderId = `EP${Date.now()}`;

    const params = {
      storeId: process.env.EASYPAISA_STORE_ID,
      amount: remaining.toFixed(2),
      postBackURL: `${process.env.SERVER_URL}/api/payments/easypaisa/return`,
      orderRefNum: orderId,
      expiryDate: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
      merchantHashedReq: '',
    };

    const hashSource = `${params.amount}&${params.orderRefNum}&${params.storeId}`;
    params.merchantHashedReq = crypto
      .createHmac('sha256', process.env.EASYPAISA_HASH_KEY)
      .update(hashSource)
      .digest('hex');

    await Payment.create({
      challanId: challan._id,
      studentId: challan.studentId?._id,
      familyId: challan.familyId,
      amount: remaining,
      method: 'EasyPaisa',
      provider: 'easypaisa',
      providerTransactionId: orderId,
      status: 'Pending',
    });

    const inputs = Object.entries(params)
      .map(([k, v]) => `<input type="hidden" name="${k}" value="${v}">`)
      .join('');

    res.send(`
      <html><body onload="document.forms[0].submit()">
        <form action="${process.env.EASYPAISA_SANDBOX_URL}" method="POST">
          ${inputs}
        </form>
        <p>Redirecting to EasyPaisa...</p>
      </body></html>
    `);
  } catch (err) {
    console.error('EasyPaisa redirect error:', err);
    res.status(500).send('EasyPaisa error: ' + err.message);
  }
};

exports.easyPaisaReturn = async (req, res) => {
  try {
    const { orderRefNum, status } = req.body;
    const payment = await Payment.findOne({ providerTransactionId: orderRefNum });
    const isSuccess = status === '0000' || status === 'SUCCESS';
    if (payment) {
      payment.rawResponse = req.body;
      payment.status = isSuccess ? 'Success' : 'Failed';
      if (isSuccess) payment.paidAt = new Date();
      await payment.save();

      if (isSuccess) {
        const challan = await FeeChallan.findById(payment.challanId);
        if (challan) {
          challan.paidAmount = Number(challan.paidAmount || 0) + Number(payment.amount);
          challan.status = challan.paidAmount >= challan.totalPayable ? 'Paid' : 'Partial';
          challan.paidDate = new Date();
          challan.paymentMethod = 'EasyPaisa';
          await challan.save();
        }
      }
    }
    res.send(`
      <html><body>
        <h2>${isSuccess ? '✅ Payment Successful' : '❌ Payment Failed'}</h2>
        <a href="${process.env.CLIENT_URL}">Return to App</a>
      </body></html>
    `);
  } catch (err) {
    console.error('EasyPaisa return error:', err);
    res.status(500).send('Error processing EasyPaisa return');
  }
};

// ================= DEMO MODE CONFIRM (JazzCash/EasyPaisa simulate) =================
exports.demoConfirmPayment = async (req, res) => {
  try {
    const { challanId, gateway } = req.body;
    const challan = await FeeChallan.findById(challanId);
    if (!challan) return res.status(404).send('Challan not found');

    const remaining = Number(challan.totalPayable) - Number(challan.paidAmount || 0);

    await Payment.create({
      challanId: challan._id,
      studentId: challan.studentId,
      familyId: challan.familyId,
      amount: remaining,
      method: gateway || 'Demo',
      provider: `${(gateway || 'demo').toLowerCase()}_demo`,
      providerTransactionId: `DEMO${Date.now()}`,
      status: 'Success',
      paidAt: new Date(),
    });

    challan.paidAmount = Number(challan.paidAmount || 0) + remaining;
    challan.status = 'Paid';
    challan.paidDate = new Date();
    challan.paymentMethod = gateway || 'Demo';
    await challan.save();

    res.send(`
      <html><body style="font-family:Arial, sans-serif; text-align:center; margin-top:80px;">
        <h2>✅ Payment Successful (Demo Mode)</h2>
        <p>Challan #${challan.challanNumber} marked as Paid.</p>
        <a href="${process.env.CLIENT_URL}">Return to App</a>
      </body></html>
    `);
  } catch (err) {
    console.error('Demo confirm error:', err);
    res.status(500).send('Error confirming demo payment: ' + err.message);
  }
};

// ================= STATUS =================
exports.getPaymentStatus = async (req, res) => {
  try {
    const challan = await FeeChallan.findById(req.params.challanId);
    if (!challan) return res.status(404).json({ success: false, message: 'Challan not found' });
    res.json({
      success: true,
      status: challan.status,
      paidAmount: challan.paidAmount,
      totalPayable: challan.totalPayable,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};