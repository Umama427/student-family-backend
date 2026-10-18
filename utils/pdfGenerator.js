const PDFDocument = require('pdfkit');

const INSTITUTE_NAME = 'STUDENT FAMILY MANAGEMENT SYSTEM';
const INSTITUTE_SUBTITLE = 'EduManage Campus';
const BANK_NAME = 'ASKARI BANK';
const BANK_ACCOUNT = '0001171650500995';

const numberToWords = (num) => {
  if (num === null || num === undefined) return 'Zero Rupees Only';
  let n = Number(num);
  if (Number.isNaN(n) || n <= 0) return 'Zero Rupees Only';
  n = Math.round(n);

  const ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];
  const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

  const convertBelowThousand = (x) => {
    let str = '';
    let val = x;
    if (val >= 100) {
      str += ones[Math.floor(val / 100)] + ' Hundred ';
      val %= 100;
    }
    if (val >= 20) {
      str += tens[Math.floor(val / 10)] + ' ';
      val %= 10;
    }
    if (val > 0) {
      str += ones[val] + ' ';
    }
    return str.trim();
  };

  let result = '';
  let remaining = n;

  const crore = Math.floor(remaining / 10000000);
  remaining %= 10000000;
  const lakh = Math.floor(remaining / 100000);
  remaining %= 100000;
  const thousand = Math.floor(remaining / 1000);
  remaining %= 1000;

  if (crore) result += convertBelowThousand(crore) + ' Crore ';
  if (lakh) result += convertBelowThousand(lakh) + ' Lakh ';
  if (thousand) result += convertBelowThousand(thousand) + ' Thousand ';
  if (remaining) result += convertBelowThousand(remaining);

  const words = result.trim();
  return words ? `${words} Rupees Only` : 'Zero Rupees Only';
};

const formatAmount = (num) => {
  const n = Number(num || 0);
  if (Number.isNaN(n)) return '0';
  return n.toLocaleString('en-PK');
};

const safeText = (v, fallback = '-') => {
  if (v === null || v === undefined) return fallback;
  const str = String(v).trim();
  return str === '' ? fallback : str;
};

const safeDateGB = (d) => {
  try {
    if (!d) return '-';
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return '-';
    return dt.toLocaleDateString('en-GB', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  } catch (err) {
    return '-';
  }
};

const safeDateShort = (d) => {
  try {
    if (!d) return '-';
    const dt = new Date(d);
    if (Number.isNaN(dt.getTime())) return '-';
    return dt.toDateString();
  } catch (err) {
    return '-';
  }
};

const buildFeeRows = (challan = {}) => {
  const rows = [];
  const tuitionFee = Number(challan.tuitionFee || 0);
  if (!Number.isNaN(tuitionFee) && tuitionFee !== 0) {
    rows.push({ label: 'TUITION FEE', amount: tuitionFee });
  } else if (tuitionFee === 0) {
    // Keep showing 0 only if you want; otherwise skip.
    // To match existing behavior, still show TUITION FEE as 0? Your old code pushed it anyway.
    rows.push({ label: 'TUITION FEE', amount: 0 });
  } else {
    rows.push({ label: 'TUITION FEE', amount: 0 });
  }

  if (Array.isArray(challan.otherCharges)) {
    challan.otherCharges.forEach((c) => {
      const amount = Number(c?.amount || 0);
      if (Number.isNaN(amount) || amount === 0) return; // skip 0 other charges to avoid clutter
      const desc = safeText(c?.description, 'OTHER CHARGE').toUpperCase();
      rows.push({ label: desc, amount });
    });
  }

  const discountAmount = Number(challan.discountAmount || 0);
  if (!Number.isNaN(discountAmount) && discountAmount > 0) {
    rows.push({ label: 'DISCOUNT', amount: -discountAmount });
  }

  const penaltyAmount = Number(challan.penaltyAmount || 0);
  if (!Number.isNaN(penaltyAmount) && penaltyAmount !== 0) {
    rows.push({ label: 'PENALTY', amount: penaltyAmount });
  }

  return rows;
};

const drawChallanCopy = (doc, x, y, width, data = {}, copyTitle) => {
  const student = data.student || {};
  const family = data.family || {};
  const challan = data.challan || {};

  let cursorY = y;
  const padding = 6;
  const innerWidth = width - padding * 2;

  // Bill ID / Challan No (keep existing logic, but safe)
  let billId = '-';
  try {
    if (challan._id) {
      const idStr = String(challan._id);
      // Take last 16 chars, pad if shorter, prefix 1001 to match old format
      const tail = idStr.slice(-16).padStart(16, '0');
      billId = `1001${tail}`;
    }
  } catch (err) {
    billId = '-';
  }

  const challanNo = safeText(
    challan.challanNumber,
    challan._id
      ? `${safeText(challan.year, '----')}-${safeText(challan.month, '--')}-${String(challan._id).slice(-5)}`
      : '-'
  );

  const issueDate = safeDateGB(challan.createdAt || Date.now());
  const dueDate = safeDateGB(challan.dueDate);

  const totalPayable = Number(challan.totalPayable || 0);

  // Copy title
  doc
    .font('Helvetica-Bold')
    .fontSize(8)
    .text(safeText(copyTitle, ''), x + padding, cursorY, {
      width: innerWidth,
      align: 'center',
    });
  cursorY += 12;

  // Bank name
  doc
    .font('Helvetica-Bold')
    .fontSize(9)
    .text(BANK_NAME, x + padding, cursorY, { width: innerWidth, align: 'center' });
  cursorY += 11;

  // Note
  doc
    .font('Helvetica')
    .fontSize(5.5)
    .text(
      'Bank Tellers enter the Challan Number & Sys-ID in the Narration Box',
      x + padding,
      cursorY,
      { width: innerWidth, align: 'center' }
    );
  cursorY += 12;

  // Bill ID
  doc
    .font('Helvetica')
    .fontSize(6)
    .text(`1-Bill ID: ${billId}`, x + padding, cursorY, { width: innerWidth });
  cursorY += 10;

  const infoRow = (label, value) => {
    const val = safeText(value, '-');
    doc
      .font('Helvetica-Bold')
      .fontSize(6.5)
      .text(safeText(label, ''), x + padding, cursorY, {
        width: innerWidth * 0.4,
        continued: false,
      });
    doc
      .font('Helvetica')
      .fontSize(6.5)
      .text(val, x + padding + innerWidth * 0.42, cursorY, {
        width: innerWidth * 0.58,
      });
    cursorY += 10;
  };

  infoRow('CHALLAN NO', challanNo);
  infoRow('ISSUE DATE', issueDate);
  infoRow('DUE DATE', dueDate);

  cursorY += 3;

  // Institute
  doc
    .font('Helvetica-Bold')
    .fontSize(7)
    .text(INSTITUTE_NAME, x + padding, cursorY, { width: innerWidth, align: 'center' });
  cursorY += 9;
  doc
    .font('Helvetica')
    .fontSize(6.5)
    .text(INSTITUTE_SUBTITLE, x + padding, cursorY, { width: innerWidth, align: 'center' });
  cursorY += 11;

  // Bank account
  doc
    .font('Helvetica')
    .fontSize(6)
    .text(`CREDIT BANK ACCOUNT # ${BANK_ACCOUNT}`, x + padding, cursorY, {
      width: innerWidth,
      align: 'center',
    });
  cursorY += 11;

  infoRow('SESSION', safeText(challan.year, '-'));
  infoRow('SHIFT', 'Morning');

  cursorY += 2;

  // Student/Family info (null-safe)
  const studentName = safeText(student.fullName, '-');
  const fatherName = safeText(family.fatherName, '-');
  let regNo = '-';
  if (student.rollNumber) {
    regNo = safeText(student.rollNumber, '-');
  } else if (student._id) {
    try {
      regNo = String(student._id).slice(-8);
    } catch (err) {
      regNo = '-';
    }
  }
  const className = safeText(student.className, '-');

  infoRow('Name:', studentName);
  infoRow('S/O-D/O:', fatherName);
  infoRow('Reg No:', regNo);
  infoRow('Class:', className);

  cursorY += 3;

  // Table header
  doc.rect(x + padding, cursorY, innerWidth, 10).fill('#e8e8e8');
  doc
    .fillColor('black')
    .font('Helvetica-Bold')
    .fontSize(6)
    .text('DESCRIPTION', x + padding + 2, cursorY + 2, { width: innerWidth * 0.65 })
    .text('AMOUNT', x + padding, cursorY + 2, { width: innerWidth - 2, align: 'right' });
  cursorY += 11;

  // Fee rows
  const rows = buildFeeRows(challan);
  rows.forEach((row) => {
    const label = safeText(row.label, '-');
    const amount = Number(row.amount || 0);
    doc
      .font('Helvetica')
      .fontSize(6)
      .text(label, x + padding + 2, cursorY, {
        width: innerWidth * 0.65,
        ellipsis: true,
        lineBreak: false,
      })
      .text(formatAmount(amount), x + padding, cursorY, {
        width: innerWidth - 2,
        align: 'right',
      });
    cursorY += 9;
  });

  // Net amount
  doc.rect(x + padding, cursorY, innerWidth, 11).fill('#dcdcdc');
  doc
    .fillColor('black')
    .font('Helvetica-Bold')
    .fontSize(6.5)
    .text('NET AMOUNT PAYABLE', x + padding + 2, cursorY + 2, {
      width: innerWidth * 0.65,
      ellipsis: true,
      lineBreak: false,
    })
    .text(formatAmount(totalPayable), x + padding, cursorY + 2, {
      width: innerWidth - 2,
      align: 'right',
    });
  cursorY += 14;

  // Amount in words
  doc
    .font('Helvetica-Oblique')
    .fontSize(5.5)
    .text(numberToWords(totalPayable), x + padding, cursorY, {
      width: innerWidth,
      align: 'center',
    });
  cursorY += 14;

  // Bank stamp/signature
  doc.rect(x + padding, cursorY, innerWidth, 16).stroke();
  doc
    .font('Helvetica')
    .fontSize(6)
    .text('BANK STAMP & SIGNATURE', x + padding, cursorY + 5, {
      width: innerWidth,
      align: 'center',
    });
  cursorY += 22;

  // Footer
  doc
    .font('Helvetica')
    .fontSize(4.5)
    .text('All rights are reserved by EduManage', x + padding, cursorY, {
      width: innerWidth,
      align: 'center',
    });
  cursorY += 7;

  doc
    .font('Helvetica-Oblique')
    .fontSize(4.5)
    .fillColor('#555')
    .text(
      'Challan generate karne mein mushkil ho to ITSC contact karein ya branch visit karein',
      x + padding,
      cursorY,
      { width: innerWidth, align: 'center' }
    );
  doc.fillColor('black');
};

exports.generateChallanPDF = (res, data = {}) => {
  let doc;
  try {
    if (!data || !data.challan) {
      if (!res.headersSent) {
        return res.status(400).json({
          success: false,
          message: 'Challan data missing for PDF generation',
        });
      }
      return;
    }

    doc = new PDFDocument({ size: 'A4', layout: 'landscape', margin: 15 });

    // Safe filename
    let challanId = 'unknown';
    try {
      if (data.challan._id) {
        challanId = String(data.challan._id).replace(/[^a-zA-Z0-9_-]/g, '');
        if (!challanId) challanId = 'unknown';
      }
    } catch (err) {
      challanId = 'unknown';
    }

    // Set headers before piping
    if (!res.headersSent) {
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader(
        'Content-Disposition',
        `attachment; filename="Challan-${challanId}.pdf"`
      );
      res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, private');
      res.setHeader('X-Content-Type-Options', 'nosniff');
    }

    // Handle PDF/document errors
    doc.on('error', (err) => {
      console.error('Challan PDF generation error:', err);
      if (!res.headersSent) {
        try {
          res.status(500).json({
            success: false,
            message: 'Failed to generate challan PDF',
          });
        } catch (e) {
          // ignore
        }
      } else {
        try {
          if (!res.writableEnded) {
            res.destroy(err);
          }
        } catch (e) {
          // ignore
        }
      }
    });

    // If client disconnects early, stop writing
    res.on('close', () => {
      try {
        if (doc && !doc.writableEnded) {
          doc.end();
        }
      } catch (err) {
        // ignore
      }
    });

    doc.pipe(res);

    const pageWidth = doc.page.width;
    const pageHeight = doc.page.height;
    const margin = 15;
    const gap = 6;
    const copyWidth = (pageWidth - margin * 2 - gap * 3) / 4;

    const copyTitles = ['Bank Copy', 'Accounts Copy', 'Academics Copy', "Student's Copy"];

    copyTitles.forEach((title, index) => {
      const x = margin + index * (copyWidth + gap);
      drawChallanCopy(doc, x, margin, copyWidth, data, title);

      if (index < 3) {
        const lineX = x + copyWidth + gap / 2;
        try {
          doc
            .save()
            .dash(3, { space: 2 })
            .moveTo(lineX, margin)
            .lineTo(lineX, pageHeight - margin)
            .stroke()
            .undash()
            .restore();
        } catch (err) {
          // Don't break the rest of the copies if a single dash line fails
        }
      }
    });

    doc.end();
  } catch (err) {
    console.error('generateChallanPDF fatal error:', err);
    try {
      if (!res.headersSent) {
        res.status(500).json({
          success: false,
          message: 'Failed to generate challan PDF',
        });
      } else if (!res.writableEnded) {
        res.destroy(err);
      }
    } catch (e) {
      // ignore
    }
  }
};

exports.generateReceiptPDF = (res, data = {}) => {
  let doc;
  try {
    const student = data.student || {};
    const family = data.family || {};
    const challan = data.challan || {};

    if (!challan || Object.keys(challan).length === 0) {
      if (!res.headersSent) {
        return res.status(400).json({
          success: false,
          message: 'Challan data missing for receipt generation',
        });
      }
      return;
    }

    doc = new PDFDocument({ size: 'A4', margin: 40 });

    // Safe filename
    let challanId = 'unknown';
    try {
      if (challan._id) {
        challanId = String(challan._id).replace(/[^a-zA-Z0-9_-]/g, '');
        if (!challanId) challanId = 'unknown';
      }
    } catch (err) {
      challanId = 'unknown';
    }

    if (!res.headersSent) {
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader(
        'Content-Disposition',
        `attachment; filename="Receipt-${challanId}.pdf"`
      );
      res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, private');
      res.setHeader('X-Content-Type-Options', 'nosniff');
    }

    doc.on('error', (err) => {
      console.error('Receipt PDF generation error:', err);
      if (!res.headersSent) {
        try {
          res.status(500).json({
            success: false,
            message: 'Failed to generate receipt PDF',
          });
        } catch (e) {
          // ignore
        }
      } else {
        try {
          if (!res.writableEnded) {
            res.destroy(err);
          }
        } catch (e) {
          // ignore
        }
      }
    });

    res.on('close', () => {
      try {
        if (doc && !doc.writableEnded) {
          doc.end();
        }
      } catch (err) {
        // ignore
      }
    });

    doc.pipe(res);

    // Header
    doc.font('Helvetica-Bold').fontSize(16).text(INSTITUTE_NAME, { align: 'center' });
    doc.font('Helvetica').fontSize(10).text(INSTITUTE_SUBTITLE, { align: 'center' });
    doc.moveDown(1);
    doc.font('Helvetica-Bold').fontSize(14).text('PAYMENT RECEIPT', { align: 'center' });
    doc.moveDown(1);

    // Details
    doc.font('Helvetica').fontSize(11);

    const receiptNo = safeText(
      challan.challanNumber,
      challan._id ? `RCPT-${String(challan._id).slice(-6)}` : 'RCPT-UNKNOWN'
    );

    doc.text(`Receipt No: ${receiptNo}`);
    doc.text(`Student Name: ${safeText(student.fullName)}`);
    doc.text(`Guardian Name: ${safeText(family.fatherName)}`);
    doc.text(`Class: ${safeText(student.className)}`);
    doc.text(`Month/Year: ${safeText(challan.month)}/${safeText(challan.year)}`);
    doc.text(`Payment Method: ${safeText(challan.paymentMethod, 'Cash')}`);
    doc.text(`Payment Date: ${safeDateShort(challan.paidDate)}`);
    doc.moveDown(0.5);

    const paidAmount = Number(challan.paidAmount || 0);
    const totalPayable = Number(challan.totalPayable || 0);

    doc
      .font('Helvetica-Bold')
      .fontSize(12)
      .text(`Amount Paid: Rs. ${formatAmount(paidAmount)}`);
    doc
      .font('Helvetica')
      .fontSize(10)
      .text(`Total Payable: Rs. ${formatAmount(totalPayable)}`);
    doc.text(`Status: ${safeText(challan.status)}`);

    doc.moveDown(2);
    doc
      .fontSize(9)
      .text('This is a system-generated receipt and does not require a signature.', {
        align: 'center',
      });

    doc.end();
  } catch (err) {
    console.error('generateReceiptPDF fatal error:', err);
    try {
      if (!res.headersSent) {
        res.status(500).json({
          success: false,
          message: 'Failed to generate receipt PDF',
        });
      } else if (!res.writableEnded) {
        res.destroy(err);
      }
    } catch (e) {
      // ignore
    }
  }
};