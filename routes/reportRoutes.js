const express = require('express');
const router = express.Router();
const downloadAuth = require('../middleware/downloadAuth');
const { exportExamResultsExcel, generateStudentReportCard, generateClassReportCards } = require('../controllers/reportController');

router.get('/exam/:examId/excel', downloadAuth('admin', 'teacher'), exportExamResultsExcel);
router.get('/student/:studentId/exam/:examId/pdf', downloadAuth('admin', 'teacher', 'parent'), generateStudentReportCard);
router.get('/class/exam/:examId/pdf', downloadAuth('admin', 'teacher'), generateClassReportCards);

module.exports = router;