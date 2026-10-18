const Family = require('../models/Family');
const Student = require('../models/Student');

// @desc   Create a new family
// @route  POST /api/families
exports.createFamily = async (req, res) => {
  try {
    const family = await Family.create(req.body);
    res.status(201).json({ success: true, data: family });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Get all families
// @route  GET /api/families
exports.getFamilies = async (req, res) => {
  try {
    const families = await Family.find().sort({ createdAt: -1 });
    res.status(200).json({ success: true, count: families.length, data: families });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Get single family WITH its students (for Sibling Tree UI)
// @route  GET /api/families/:id
exports.getFamilyById = async (req, res) => {
  try {
    const family = await Family.findById(req.params.id).populate('students');
    if (!family) {
      return res.status(404).json({ success: false, message: 'Family not found' });
    }
    res.status(200).json({ success: true, data: family });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// @desc   Update family
// @route  PUT /api/families/:id
exports.updateFamily = async (req, res) => {
  try {
    const family = await Family.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!family) {
      return res.status(404).json({ success: false, message: 'Family not found' });
    }
    res.status(200).json({ success: true, data: family });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

// @desc   Delete family
// @route  DELETE /api/families/:id
exports.deleteFamily = async (req, res) => {
  try {
    const family = await Family.findByIdAndDelete(req.params.id);
    if (!family) {
      return res.status(404).json({ success: false, message: 'Family not found' });
    }
    res.status(200).json({ success: true, message: 'Family deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};