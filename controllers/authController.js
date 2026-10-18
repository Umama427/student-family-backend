const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Admin = require('../models/Admin');
const Staff = require('../models/Staff');
const Family = require('../models/Family');
const { logAction } = require('../utils/auditLogger');

const generateToken = (id, role = 'admin') => {
  return jwt.sign({ id, role }, process.env.JWT_SECRET || 'edumanage_super_secret_key_umama_2026', {
    expiresIn: '30d',
  });
};

// ==================== ADMIN AUTH (Existing - Unchanged Logic) ====================

exports.registerAdmin = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ success: false, message: 'Name, email and password are required' });
    }

    const exists = await Admin.findOne({ email });
    if (exists) {
      return res.status(400).json({ success: false, message: 'Admin already exists with this email' });
    }

    const admin = await Admin.create({ name, email, password });

    res.status(201).json({
      success: true,
      message: 'Admin registered successfully',
      data: { _id: admin._id, name: admin.name, email: admin.email },
      token: generateToken(admin._id, 'admin'),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.loginAdmin = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    const admin = await Admin.findOne({ email });
    if (!admin) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    const isMatch = await admin.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: { _id: admin._id, name: admin.name, email: admin.email, role: 'admin' },
      token: generateToken(admin._id, 'admin'),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Email is required' });
    }

    const admin = await Admin.findOne({ email });
    if (!admin) {
      return res.status(404).json({ success: false, message: 'No admin found with this email' });
    }

    const resetToken = crypto.randomBytes(20).toString('hex');
    admin.resetPasswordToken = crypto.createHash('sha256').update(resetToken).digest('hex');
    admin.resetPasswordExpire = Date.now() + 10 * 60 * 1000;
    await admin.save({ validateBeforeSave: false });

    const resetUrl = `http://localhost:56893/reset-password/${resetToken}`;

    res.status(200).json({
      success: true,
      message: 'Password reset link generated successfully',
      resetUrl,
      resetToken,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.resetPassword = async (req, res) => {
  try {
    const hashedToken = crypto.createHash('sha256').update(req.params.token).digest('hex');

    const admin = await Admin.findOne({
      resetPasswordToken: hashedToken,
      resetPasswordExpire: { $gt: Date.now() },
    });

    if (!admin) {
      return res.status(400).json({ success: false, message: 'Invalid or expired reset token' });
    }

    if (!req.body.password || req.body.password.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
    }

    admin.password = req.body.password;
    admin.resetPasswordToken = undefined;
    admin.resetPasswordExpire = undefined;
    await admin.save();

    res.status(200).json({
      success: true,
      message: 'Password reset successful. You can now login.',
      token: generateToken(admin._id, 'admin'),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getMe = async (req, res) => {
  try {
    const admin = await Admin.findById(req.admin.id).select('-password');
    res.status(200).json({ success: true, data: admin });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== ✅ TEACHER AUTH (New) ====================

// @desc   Login Teacher
// @route  POST /api/auth/teacher/login
exports.loginTeacher = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    const staff = await Staff.findOne({ email }).select('+password');

    if (!staff || !staff.password || !staff.hasPortalAccess) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials or portal access not enabled. Contact admin.',
      });
    }

    const isMatch = await staff.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        _id: staff._id,
        fullName: staff.fullName,
        email: staff.email,
        designation: staff.designation,
        assignedClasses: staff.assignedClasses,
        assignedSubjects: staff.assignedSubjects, // ✅ NEW
        role: 'teacher',
      },
      token: generateToken(staff._id, 'teacher'),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== ✅ PARENT AUTH (New) ====================

// @desc   Login Parent/Family
// @route  POST /api/auth/parent/login
exports.loginParent = async (req, res) => {
  try {
    const { primaryPhone, portalPin } = req.body;

    if (!primaryPhone || !portalPin) {
      return res.status(400).json({ success: false, message: 'Phone number and PIN are required' });
    }

    const family = await Family.findOne({ primaryPhone });

    if (!family || family.portalPin !== portalPin) {
      return res.status(401).json({ success: false, message: 'Invalid phone number or PIN' });
    }

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        _id: family._id,
        familyName: family.familyName,
        familyCode: family.familyCode,
        primaryPhone: family.primaryPhone,
        role: 'parent',
      },
      token: generateToken(family._id, 'parent'),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== ✅ ADMIN UTILITIES (Manage Portal Access) ====================

// @desc   Admin sets/updates a teacher's portal credentials
// @route  PUT /api/auth/admin/set-staff-credentials/:staffId
exports.setStaffCredentials = async (req, res) => {
  try {
    const { email, password, assignedClasses, assignedSubjects } = req.body;

    const staff = await Staff.findById(req.params.staffId);
    if (!staff) {
      return res.status(404).json({ success: false, message: 'Staff member not found' });
    }

    if (email) staff.email = email;
    if (password) staff.password = password; // will be hashed by pre-save hook
    if (assignedClasses) staff.assignedClasses = assignedClasses;
    if (assignedSubjects) staff.assignedSubjects = assignedSubjects; // ✅ NEW

    await staff.save();

    await logAction({
      admin: req.admin,
      action: 'UPDATE',
      module: 'Staff Portal Access',
      description: `Set portal credentials for staff: ${staff.fullName}`,
      targetId: staff._id,
      ipAddress: req.ip,
    });

    res.status(200).json({
      success: true,
      message: 'Teacher portal access configured successfully',
      data: {
        _id: staff._id,
        fullName: staff.fullName,
        email: staff.email,
        hasPortalAccess: staff.hasPortalAccess,
        assignedClasses: staff.assignedClasses,
        assignedSubjects: staff.assignedSubjects, // ✅ NEW
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Admin sets/resets a family's portal PIN
// @route  PUT /api/auth/admin/set-family-pin/:familyId
exports.setFamilyPin = async (req, res) => {
  try {
    const { portalPin } = req.body;

    if (!portalPin || portalPin.length !== 4) {
      return res.status(400).json({ success: false, message: 'PIN must be exactly 4 digits' });
    }

    const family = await Family.findByIdAndUpdate(
      req.params.familyId,
      { portalPin },
      { new: true }
    );

    if (!family) {
      return res.status(404).json({ success: false, message: 'Family not found' });
    }

    await logAction({
      admin: req.admin,
      action: 'UPDATE',
      module: 'Family Portal Access',
      description: `Reset portal PIN for family: ${family.familyName}`,
      targetId: family._id,
      ipAddress: req.ip,
    });

    res.status(200).json({
      success: true,
      message: 'Family PIN updated successfully',
      data: { _id: family._id, familyName: family.familyName, portalPin: family.portalPin },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};