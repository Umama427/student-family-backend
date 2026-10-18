const ExcelJS = require('exceljs');

async function generateResultsExcelBuffer({ examName, className, academicYear, subjects, students, results }) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'EduManage';
  workbook.created = new Date();

  const sheet = workbook.addWorksheet('Results', {
    pageSetup: { paperSize: 9, orientation: 'landscape', fitToPage: true }
  });

  const totalCols = 5 + subjects.length;

  sheet.mergeCells(1, 1, 1, totalCols);
  const titleCell = sheet.getCell(1, 1);
  titleCell.value = `EXAM RESULT SHEET — ${examName}`;
  titleCell.font = { size: 16, bold: true, color: { argb: 'FFFFFFFF' } };
  titleCell.alignment = { horizontal: 'center', vertical: 'middle' };
  sheet.getRow(1).height = 30;
  sheet.getRow(1).eachCell(c => { c.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1F4E78' } }; });

  sheet.mergeCells(2, 1, 2, totalCols);
  const subCell = sheet.getCell(2, 1);
  subCell.value = `Class: ${className}   |   Academic Year: ${academicYear || '-'}   |   Generated: ${new Date().toLocaleDateString()}`;
  subCell.font = { italic: true, size: 11 };
  subCell.alignment = { horizontal: 'center' };

  sheet.addRow([]);

  const headerRow = ['Roll No', 'Student Name'];
  subjects.forEach(s => headerRow.push(`${s.subjectName} (${s.totalMarks})`));
  headerRow.push('Total Obtained', 'Total Marks', 'Percentage', 'Grade');
  const hRow = sheet.addRow(headerRow);
  hRow.eachCell(cell => {
    cell.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF2E75B6' } };
    cell.alignment = { horizontal: 'center', vertical: 'middle' };
    cell.border = { top: { style: 'thin' }, bottom: { style: 'thin' }, left: { style: 'thin' }, right: { style: 'thin' } };
  });

  const sortedStudents = [...students].sort((a, b) => (a.fullName || '').localeCompare(b.fullName || ''));

  sortedStudents.forEach((student, idx) => {
    const result = results.find(r => String(r.studentId) === String(student._id));
    const row = [student.rollNumber || '-', student.fullName];

    subjects.forEach(sub => {
      const subResult = result?.subjects?.find(r => r.subjectName === sub.subjectName);
      row.push(subResult ? subResult.marksObtained : '-');
    });

    const totalObtained = result ? result.totalMarksObtained : '-';
    const totalMarks = result ? result.totalMaxMarks : subjects.reduce((s, x) => s + x.totalMarks, 0);
    const percentage = result ? `${result.percentage}%` : '-';
    const grade = result ? result.overallGrade : '-';
    const isFail = result && result.status === 'Fail';

    row.push(totalObtained, totalMarks, percentage, grade);

    const dataRow = sheet.addRow(row);
    dataRow.eachCell((cell, colNumber) => {
      cell.alignment = { horizontal: 'center', vertical: 'middle' };
      cell.border = { top: { style: 'thin' }, bottom: { style: 'thin' }, left: { style: 'thin' }, right: { style: 'thin' } };
      if (colNumber === 2) cell.alignment = { horizontal: 'left' };
      if (idx % 2 === 0) cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF2F7FC' } };
    });

    const gradeCell = dataRow.getCell(row.length);
    gradeCell.font = isFail ? { color: { argb: 'FFCC0000' }, bold: true } : { color: { argb: 'FF006100' }, bold: true };
  });

  sheet.getColumn(1).width = 12;
  sheet.getColumn(2).width = 25;
  for (let i = 3; i <= 2 + subjects.length; i++) sheet.getColumn(i).width = 16;
  sheet.getColumn(3 + subjects.length).width = 16;
  sheet.getColumn(4 + subjects.length).width = 14;
  sheet.getColumn(5 + subjects.length).width = 14;
  sheet.getColumn(6 + subjects.length).width = 10;

  return workbook.xlsx.writeBuffer();
}

module.exports = { generateResultsExcelBuffer };