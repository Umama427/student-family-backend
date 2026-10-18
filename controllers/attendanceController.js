const Attendance = require('../models/Attendance');
const Student = require('../models/Student');
const Staff = require('../models/Staff');

// ✅ Helper: get allowed student IDs based on role
const getAllowedStudentIds = async (req) => {
  if (req.role === 'teacher') {
    const students = await Student.find({ className: { $in: req.user.assignedClasses || [] } }).select('_id');
    return students.map((s) => s._id.toString());
  }
  if (req.role === 'parent') {
    const students = await Student.find({ familyId: req.user._id }).select('_id');
    return students.map((s) => s._id.toString());
  }
  return null; // null = admin, no restriction
};

exports.markAttendance = async (req, res) => {
  try {
    const { type, refId, date, status, remarks } = req.body;

    if (!type || !refId || !status) {
      return res.status(400).json({ success: false, message: 'type, refId and status are required' });
    }

    if (req.role === 'teacher' && type === 'student') {
      const allowedIds = await getAllowedStudentIds(req);
      if (!allowedIds.includes(refId.toString())) {
        return res.status(403).json({ success: false, message: 'Access denied: student not in your class' });
      }
    }

    const refModel = type === 'staff' ? 'Staff' : 'Student';
    const day = new Date(date || Date.now());
    day.setHours(0, 0, 0, 0);

    const record = await Attendance.findOneAndUpdate(
      { refId, date: day },
      { type, refId, refModel, date: day, status, remarks },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    res.status(200).json({ success: true, data: record });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.bulkMarkAttendance = async (req, res) => {
  try {
    const { type, date, records } = req.body;

    if (!type || !Array.isArray(records) || records.length === 0) {
      return res.status(400).json({ success: false, message: 'type and records array are required' });
    }

    let validRecords = records;
    if (req.role === 'teacher' && type === 'student') {
      const allowedIds = await getAllowedStudentIds(req);
      validRecords = records.filter((r) => allowedIds.includes(r.refId.toString()));
      if (validRecords.length === 0) {
        return res.status(403).json({ success: false, message: 'Access denied: no students in your class' });
      }
    }

    const refModel = type === 'staff' ? 'Staff' : 'Student';
    const day = new Date(date || Date.now());
    day.setHours(0, 0, 0, 0);

    const ops = validRecords.map((r) => ({
      updateOne: {
        filter: { refId: r.refId, date: day },
        update: { type, refId: r.refId, refModel, date: day, status: r.status, remarks: r.remarks || '' },
        upsert: true,
      },
    }));

    await Attendance.bulkWrite(ops);
    res.status(200).json({ success: true, message: `${validRecords.length} attendance records saved.` });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.getAttendance = async (req, res) => {
  try {
    const { type, refId, month, year } = req.query;
    const filter = {};
    if (type) filter.type = type;
    if (refId) filter.refId = refId;

    if (month && year) {
      const start = new Date(year, month - 1, 1);
      const end = new Date(year, month, 0, 23, 59, 59);
      filter.date = { $gte: start, $lte: end };
    }

    const allowedIds = await getAllowedStudentIds(req);
    if (allowedIds !== null) {
      filter.type = 'student';
      if (refId) {
        if (!allowedIds.includes(refId)) {
          return res.status(403).json({ success: false, message: 'Access denied' });
        }
      } else {
        filter.refId = { $in: allowedIds };
      }
    }

    const records = await Attendance.find(filter).populate('refId').sort({ date: -1 });
    res.status(200).json({ success: true, count: records.length, data: records });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getAttendanceSummary = async (req, res) => {
  try {
    const { type, refId } = req.query;

    if (!type || !refId) {
      return res.status(400).json({ success: false, message: 'type and refId are required' });
    }

    const allowedIds = await getAllowedStudentIds(req);
    if (allowedIds !== null && !allowedIds.includes(refId)) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }

    const records = await Attendance.find({ type, refId });
    const present = records.filter((r) => r.status === 'Present').length;
    const absent = records.filter((r) => r.status === 'Absent').length;
    const leave = records.filter((r) => r.status === 'Leave').length;
    const late = records.filter((r) => r.status === 'Late').length;
    const total = records.length;
    const percentage = total ? (((present + late) / total) * 100).toFixed(2) : '0.00';

    res.status(200).json({
      success: true,
      data: { total, present, absent, leave, late, percentage },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ✅ NEW: Get full day roster (all students/staff + their attendance status) for a given date
// GET /api/attendance/roster?type=student&className=BSCS-1st&date=2026-10-17
exports.getDailyRoster = async (req, res) => {
  try {
    const { type, className, date } = req.query;
    if (!type || !date) {
      return res.status(400).json({ success: false, message: 'type and date are required' });
    }

    const day = new Date(date);
    day.setHours(0, 0, 0, 0);

    let people = [];

    if (type === 'student') {
      if (req.role === 'parent') {
        people = await Student.find({ familyId: req.user._id, status: 'active' });
      } else {
        const filter = { status: 'active' };
        if (req.role === 'teacher') {
          filter.className = { $in: req.user.assignedClasses || [] };
          if (className && !(req.user.assignedClasses || []).includes(className)) {
            return res.status(403).json({ success: false, message: 'Access denied: not your class' });
          }
        }
        if (className) filter.className = className;
        people = await Student.find(filter);
      }
    } else if (type === 'staff') {
      if (req.role !== 'admin') {
        return res.status(403).json({ success: false, message: 'Access denied' });
      }
      people = await Staff.find({ status: 'active' });
    }

    const refIds = people.map((p) => p._id);
    const records = await Attendance.find({ refId: { $in: refIds }, date: day });

    const recordMap = {};
    records.forEach((r) => {
      recordMap[r.refId.toString()] = r;
    });

    const roster = people.map((p) => {
      const rec = recordMap[p._id.toString()];
      return {
        refId: p._id,
        name: p.fullName,
        className: p.className || null,
        designation: p.designation || null,
        status: rec ? rec.status : null,
        remarks: rec ? rec.remarks : '',
        attendanceId: rec ? rec._id : null,
      };
    });

    res.status(200).json({ success: true, date: day, count: roster.length, data: roster });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.deleteAttendance = async (req, res) => {
  try {
    const record = await Attendance.findByIdAndDelete(req.params.id);
    if (!record) {
      return res.status(404).json({ success: false, message: 'Attendance record not found' });
    }
    res.status(200).json({ success: true, message: 'Attendance record deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};