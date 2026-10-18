const PDFDocument = require('pdfkit');

function drawReportCardPage(doc, schoolName, { student, exam, result }) {
  const fatherName = student.familyId?.fatherName || '-';
  const isFail = result.status === 'Fail';

  doc.rect(0, 0, doc.page.width, 90).fill('#1F4E78');
  doc.fillColor('#FFFFFF').fontSize(22).font('Helvetica-Bold').text(schoolName, 40, 25, { align: 'center' });
  doc.fontSize(12).font('Helvetica').text('STUDENT REPORT CARD', { align: 'center' });
  doc.fillColor('#000000');

  const infoY = 110;
  doc.roundedRect(40, infoY, doc.page.width - 80, 90, 6).stroke('#999999');
  doc.fontSize(11).font('Helvetica-Bold').text('Student Name:', 55, infoY + 12);
  doc.font('Helvetica').text(student.fullName, 160, infoY + 12);
  doc.font('Helvetica-Bold').text('Roll Number:', 320, infoY + 12);
  doc.font('Helvetica').text(String(student.rollNumber || '-'), 420, infoY + 12);
  doc.font('Helvetica-Bold').text('Class:', 55, infoY + 32);
  doc.font('Helvetica').text(exam.className, 160, infoY + 32);
  doc.font('Helvetica-Bold').text('Exam:', 320, infoY + 32);
  doc.font('Helvetica').text(exam.examName, 420, infoY + 32);
  doc.font('Helvetica-Bold').text('Father Name:', 55, infoY + 52);
  doc.font('Helvetica').text(fatherName, 160, infoY + 52);
  doc.font('Helvetica-Bold').text('Academic Year:', 320, infoY + 52);
  doc.font('Helvetica').text(exam.academicYear || '-', 420, infoY + 52);

  let tableY = infoY + 110;
  const col = [55, 300, 400, 480];
  doc.rect(40, tableY, doc.page.width - 80, 24).fill('#2E75B6');
  doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(11);
  doc.text('Subject', col[0], tableY + 7);
  doc.text('Marks Obtained', col[1], tableY + 7);
  doc.text('Total Marks', col[2], tableY + 7);
  doc.text('Grade', col[3], tableY + 7);
  doc.fillColor('#000000');

  tableY += 24;
  doc.font('Helvetica').fontSize(11);
  (result.subjects || []).forEach((sub, i) => {
    const rowH = 22;
    if (i % 2 === 0) { doc.rect(40, tableY, doc.page.width - 80, rowH).fill('#F2F7FC'); doc.fillColor('#000000'); }
    doc.text(sub.subjectName, col[0], tableY + 5);
    doc.text(String(sub.marksObtained), col[1], tableY + 5);
    doc.text(String(sub.totalMarks), col[2], tableY + 5);
    const subFail = (sub.marksObtained / sub.totalMarks) * 100 < 33;
    doc.fillColor(subFail ? '#CC0000' : '#006100').text(sub.grade || '-', col[3], tableY + 5);
    doc.fillColor('#000000');
    tableY += rowH;
  });

  tableY += 10;
  doc.rect(40, tableY, doc.page.width - 80, 30).fill('#1F4E78');
  doc.fillColor('#FFFFFF').font('Helvetica-Bold');
  doc.text(`Total: ${result.totalMarksObtained} / ${result.totalMaxMarks}`, col[0], tableY + 8);
  doc.text(`Percentage: ${result.percentage}%`, col[1], tableY + 8);
  doc.text(`Grade: ${result.overallGrade}`, col[3], tableY + 8);
  doc.fillColor('#000000');

  tableY += 40;
  doc.font('Helvetica-Bold').fillColor(isFail ? '#CC0000' : '#006100')
    .text(`Result: ${result.status.toUpperCase()}`, col[0], tableY);
  doc.fillColor('#000000');

  tableY += 30;
  doc.font('Helvetica-Bold').text('Remarks:', 55, tableY);
  doc.font('Helvetica').text(result.remarks || '-', 150, tableY, { width: 380 });

  tableY += 60;
  doc.moveTo(55, tableY).lineTo(220, tableY).stroke();
  doc.text('Class Teacher Signature', 55, tableY + 5);
  doc.moveTo(380, tableY).lineTo(540, tableY).stroke();
  doc.text('Principal Signature', 380, tableY + 5);
}

function generateReportCardPDF(res, data) {
  const doc = new PDFDocument({ size: 'A4', margin: 40 });
  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `inline; filename=ReportCard_${data.student.fullName.replace(/\s/g, '_')}.pdf`);
  doc.pipe(res);
  drawReportCardPage(doc, 'EduManage School', data);
  doc.end();
}

function generateClassReportCardsPDF(res, { className, studentsData }) {
  const doc = new PDFDocument({ size: 'A4', margin: 40 });
  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', `inline; filename=ReportCards_${className.replace(/\s/g, '_')}.pdf`);
  doc.pipe(res);
  studentsData.forEach((data, i) => {
    if (i > 0) doc.addPage();
    drawReportCardPage(doc, 'EduManage School', data);
  });
  doc.end();
}

module.exports = { generateReportCardPDF, generateClassReportCardsPDF };