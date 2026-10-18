require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const connectDB = require('./config/db');
const reportRoutes = require('./routes/reportRoutes');
const bulkRoutes = require('./routes/bulkRoutes');
const paymentController = require('./controllers/paymentController');

const app = express();

// Connect Database
connectDB();

// Middlewares
app.use(cors());

// ⚠️ IMPORTANT: Stripe webhook ko RAW body chahiye — isliye yeh express.json() se PEHLE hai
app.post(
  '/api/payments/stripe/webhook',
  express.raw({ type: 'application/json' }),
  paymentController.stripeWebhook
);

app.use(express.json());
app.use(morgan('dev'));

// Routes (Existing)
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/families', require('./routes/familyRoutes'));
app.use('/api/students', require('./routes/studentRoutes'));
app.use('/api/challans', require('./routes/feeChallanRoutes'));
app.use('/api/staff', require('./routes/staffRoutes'));
app.use('/api/salaries', require('./routes/salaryRoutes'));
app.use('/api/dashboard', require('./routes/dashboardRoutes'));
app.use('/api/whatsapp', require('./routes/whatsappRoutes'));
app.use('/api/attendance', require('./routes/attendanceRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));

// ✅ NEW Routes
app.use('/api/classes', require('./routes/classRoutes'));
app.use('/api/subjects', require('./routes/subjectRoutes'));
app.use('/api/audit-logs', require('./routes/auditLogRoutes'));
app.use('/api/exams', require('./routes/examRoutes'));
app.use('/api/results', require('./routes/resultRoutes'));
app.use('/api/teacher', require('./routes/teacherRoutes'));
app.use('/api/parent', require('./routes/parentRoutes'));
app.use('/api/reports', reportRoutes);
app.use('/api/bulk', bulkRoutes);

// ✅ (Round 3): Support Section
app.use('/api/support', require('./routes/supportRoutes'));

// ✅ NEW (Round 4): Payments + Export
app.use('/api/payments', require('./routes/paymentRoutes'));
app.use('/api/export', require('./routes/exportRoutes'));

// Health Check
app.get('/', (req, res) => {
  res.status(200).json({ success: true, message: 'EduManage API is running ✅' });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route not found: ${req.originalUrl}` });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});