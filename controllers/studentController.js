const Student = require('../models/Student');
const FeeChallan = require('../models/FeeChallan');
const { logAction } = require('../utils/auditLogger');

// ==================== Helper: Build filter based on role ====================
const buildStudentFilter = (req) => {
  let filter = {};
  if (req.role === 'teacher') {
    filter.className = { $in: req.user.assignedClasses || [] };
  } else if (req.role === 'parent') {
    filter.familyId = req.user._id;
  }
  return filter;
};

// @desc   Create new student & AUTO-CREATE fee challan (Admin only)
const createStudent = async (req, res) => {
  try {
    const {
      familyId,
      fullName,
      className,
      gender,
      siblingOrder = 1,
      discountPercentage = 0,
      monthlyTuitionFee = 0,
      status = 'active',
      contactNumber = null,
    } = req.body;

    if (!familyId || !fullName) {
      return res.status(400).json({
        success: false,
        message: 'familyId and fullName are required fields',
      });
    }

    const student = await Student.create({
      familyId,
      fullName,
      className,
      gender,
      siblingOrder: Number(siblingOrder) || 1,
      discountPercentage: Number(discountPercentage) || 0,
      monthlyTuitionFee: Number(monthlyTuitionFee) || 0,
      status,
      contactNumber,
    });

    try {
      const now = new Date();
      const month = now.getMonth() + 1;
      const year = now.getFullYear();
      const dueDate = new Date(year, month - 1, 25);

      const tuitionFee = Number(student.monthlyTuitionFee) || 0;
      const discountPct = Number(student.discountPercentage) || 0;
      const discountAmt = (tuitionFee * discountPct) / 100;
      const totalPayable = tuitionFee - discountAmt;

      const existingChallan = await FeeChallan.findOne({
        studentId: student._id,
        month,
        year,
      });

      if (!existingChallan) {
        await FeeChallan.create({
          studentId: student._id,
          familyId: student.familyId,
          month,
          year,
          tuitionFee,
          discountPercentage: discountPct,
          discountAmount: discountAmt,
          totalPayable,
          dueDate,
          status: dueDate < now ? 'Overdue' : 'Pending',
          otherCharges: [],
        });
      }
    } catch (challanErr) {
      console.log('Notice: Auto-challan generation status:', challanErr.message);
    }

    await logAction({
      admin: req.admin,
      action: 'CREATE',
      module: 'Student',
      description: `Created new student: ${student.fullName} (Class: ${student.className || 'N/A'})`,
      targetId: student._id,
      newData: student.toObject(),
      ipAddress: req.ip,
    });

    res.status(201).json({
      success: true,
      message: 'Student added & fee challan generated successfully',
      data: student,
    });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Get students (Role-filtered: Admin=all, Teacher=own class, Parent=own children)
const getStudents = async (req, res) => {
  try {
    const filter = buildStudentFilter(req);

    const students = await Student.find(filter)
      .populate('familyId', 'familyName familyCode primaryPhone')
      .sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: students.length, data: students });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get single student (with ownership check)
const getStudentById = async (req, res) => {
  try {
    const student = await Student.findById(req.params.id).populate('familyId');
    if (!student) {
      return res.status(404).json({ success: false, message: 'Student not found' });
    }

    // ✅ Ownership check
    if (req.role === 'teacher' && !(req.user.assignedClasses || []).includes(student.className)) {
      return res.status(403).json({ success: false, message: 'Access denied: student not in your class' });
    }
    if (req.role === 'parent' && student.familyId._id.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Access denied: not your child' });
    }

    res.status(200).json({ success: true, data: student });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Update student (Admin only)
const updateStudent = async (req, res) => {
  try {
    const oldStudent = await Student.findById(req.params.id);
    if (!oldStudent) {
      return res.status(404).json({ success: false, message: 'Student not found' });
    }

    const student = await Student.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });

    await logAction({
      admin: req.admin,
      action: 'UPDATE',
      module: 'Student',
      description: `Updated student: ${student.fullName}`,
      targetId: student._id,
      oldData: oldStudent.toObject(),
      newData: student.toObject(),
      ipAddress: req.ip,
    });

    res.status(200).json({ success: true, data: student });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Delete student (Admin only)
const deleteStudent = async (req, res) => {
  try {
    const student = await Student.findByIdAndDelete(req.params.id);
    if (!student) {
      return res.status(404).json({ success: false, message: 'Student not found' });
    }

    await logAction({
      admin: req.admin,
      action: 'DELETE',
      module: 'Student',
      description: `Deleted student: ${student.fullName} (ID: ${student._id})`,
      targetId: student._id,
      oldData: student.toObject(),
      ipAddress: req.ip,
    });

    res.status(200).json({ success: true, message: 'Student deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Update Student Progress (Admin + Teacher, with ownership check for teacher)
const updateProgress = async (req, res) => {
  try {
    const { attendancePercentage, currentGPA, remarks } = req.body;

    const oldStudent = await Student.findById(req.params.id);
    if (!oldStudent) {
      return res.status(404).json({ success: false, message: 'Student not found' });
    }

    // ✅ Teacher ownership check
    if (req.role === 'teacher' && !(req.user.assignedClasses || []).includes(oldStudent.className)) {
      return res.status(403).json({ success: false, message: 'Access denied: student not in your class' });
    }

    const student = await Student.findByIdAndUpdate(
      req.params.id,
      {
        progress: {
          attendancePercentage: Number(attendancePercentage) || 0,
          currentGPA: Number(currentGPA) || 0,
          remarks: remarks || '',
        },
      },
      { new: true, runValidators: true }
    );

    // ✅ Audit log only when admin (req.admin exists); teacher actions log via generic user
    await logAction({
      admin: req.role === 'admin' ? req.admin : null,
      action: 'UPDATE',
      module: 'Student Progress',
      description: `Updated progress for: ${student.fullName} (GPA: ${currentGPA}, Attendance: ${attendancePercentage}%) by ${req.role}`,
      targetId: student._id,
      oldData: oldStudent.progress,
      newData: student.progress,
      ipAddress: req.ip,
    });

    res.status(200).json({ success: true, data: student });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

module.exports = {
  createStudent,
  getStudents,
  getStudentById,
  updateStudent,
  deleteStudent,
  updateProgress,
};