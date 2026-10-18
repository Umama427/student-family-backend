const ExcelJS = require('exceljs');
const Student = require('../models/Student');
const Family = require('../models/Family');
const Staff = require('../models/Staff');
const FeeChallan = require('../models/FeeChallan');

const MODULE_MAP = {
  students: Student,
  families: Family,
  staff: Staff,
  challans: FeeChallan,
};

function flatten(obj, prefix = '') {
  let result = {};
  for (const key in obj) {
    if (key === '__v' || key === 'password') continue;
    const value = obj[key];
    const newKey = prefix ? `${prefix}.${key}` : key;
    if (
      value &&
      typeof value === 'object' &&
      !Array.isArray(value) &&
      !(value instanceof Date) &&
      value._bsontype !== 'ObjectID'
    ) {
      Object.assign(result, flatten(value, newKey));
    } else if (Array.isArray(value)) {
      result[newKey] = value.map((v) => (typeof v === 'object' ? JSON.stringify(v) : v)).join('; ');
    } else {
      result[newKey] = value instanceof Date ? value.toISOString().split('T')[0] : value;
    }
  }
  return result;
}

function csvEscape(value) {
  if (value === null || value === undefined) return '';
  const str = String(value);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

exports.exportModule = async (req, res) => {
  try {
    const { module } = req.params;
    const format = (req.query.format || 'excel').toLowerCase();

    const Model = MODULE_MAP[module];
    if (!Model) {
      return res.status(400).json({ success: false, message: `Unknown export module: ${module}` });
    }

    let query = Model.find().lean();
    if (module === 'students') query = query.populate('familyId', 'fatherName motherName contactNumber');
    if (module === 'challans') query = query.populate('studentId', 'fullName rollNumber className');

    const records = await query;
    const flatRecords = records.map((r) => flatten(r));

    if (flatRecords.length === 0) {
      return res.status(404).json({ success: false, message: 'No records found to export' });
    }

    const headers = Array.from(
      flatRecords.reduce((set, rec) => {
        Object.keys(rec).forEach((k) => set.add(k));
        return set;
      }, new Set())
    );

    if (format === 'csv') {
      let csv = headers.join(',') + '\n';
      flatRecords.forEach((rec) => {
        csv += headers.map((h) => csvEscape(rec[h])).join(',') + '\n';
      });
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="${module}-export.csv"`);
      return res.send(csv);
    }

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet(module);
    sheet.columns = headers.map((h) => ({ header: h, key: h, width: 20 }));
    sheet.getRow(1).eachCell((cell) => {
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF2ECC9A' } };
      cell.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    });
    flatRecords.forEach((rec) => sheet.addRow(rec));

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${module}-export.xlsx"`);
    await workbook.xlsx.write(res);
    res.end();
  } catch (err) {
    console.error('Export error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};