const Staff = require('../models/Staff');

// @desc   Create new staff member (Saves in 'staffs' collection)
// @route  POST /api/staff
exports.createStaff = async (req, res) => {
  try {
    const {
      fullName,
      name,
      email,
      phone,
      phoneNumber, // ✅ Backward compatibility ke liye accept karo
      department,
      designation,
      basicSalary,
      baseSalary,
      salary,
    } = req.body;

    const salaryValue = Number(basicSalary || baseSalary || salary || 0);
    // ✅ FIXED: Sirf ek field 'phone' mein store karo (chahe frontend se phone aaye ya phoneNumber)
    const phoneValue = phone || phoneNumber || '';

    const staff = await Staff.create({
      fullName: fullName || name,
      email: email || '',
      phone: phoneValue, // ✅ Model mein ab sirf ye field hai
      department: department || 'General',
      designation: designation || 'Teacher',
      basicSalary: salaryValue,
      baseSalary: salaryValue,
      status: 'active',
    });

    res.status(201).json({ success: true, data: staff });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Get all staff members (Admin only)
exports.getStaff = async (req, res) => {
  try {
    const staffMembers = await Staff.find().sort({ createdAt: -1 });
    res.status(200).json({
      success: true,
      count: staffMembers.length,
      data: staffMembers,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getStaffById = async (req, res) => {
  try {
    const staff = await Staff.findById(req.params.id);
    if (!staff) {
      return res.status(404).json({ success: false, message: 'Staff member not found' });
    }
    res.status(200).json({ success: true, data: staff });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.updateStaff = async (req, res) => {
  try {
    // ✅ Agar update mein phoneNumber aaye to use bhi phone mein normalize karo
    if (req.body.phoneNumber && !req.body.phone) {
      req.body.phone = req.body.phoneNumber;
    }
    delete req.body.phoneNumber; // field ab model mein hai hi nahi

    const staff = await Staff.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!staff) {
      return res.status(404).json({ success: false, message: 'Staff member not found' });
    }
    res.status(200).json({ success: true, data: staff });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

exports.deleteStaff = async (req, res) => {
  try {
    const staff = await Staff.findByIdAndDelete(req.params.id);
    if (!staff) {
      return res.status(404).json({ success: false, message: 'Staff member not found' });
    }
    res.status(200).json({ success: true, message: 'Staff member deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};