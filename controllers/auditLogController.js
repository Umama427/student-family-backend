const AuditLog = require('../models/AuditLog');

// @desc    Get all audit logs (with filters & pagination)
// @route   GET /api/audit-logs?module=Student&action=DELETE&page=1&limit=20
// @access  Private (Admin only)
exports.getAuditLogs = async (req, res) => {
  try {
    const { module, action, userId, startDate, endDate } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const filter = {};
    if (module) filter.module = module;
    if (action) filter.action = action;
    if (userId) filter.user = userId;

    if (startDate || endDate) {
      filter.createdAt = {};
      if (startDate) filter.createdAt.$gte = new Date(startDate);
      if (endDate) filter.createdAt.$lte = new Date(endDate);
    }

    const total = await AuditLog.countDocuments(filter);
    const logs = await AuditLog.find(filter)
      .populate('user', 'name email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    res.status(200).json({
      success: true,
      count: logs.length,
      total,
      totalPages: Math.ceil(total / limit),
      currentPage: page,
      data: logs,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error while fetching audit logs',
      error: error.message,
    });
  }
};

// @desc    Get audit log by ID (full details including old/new data)
// @route   GET /api/audit-logs/:id
// @access  Private (Admin only)
exports.getAuditLogById = async (req, res) => {
  try {
    const log = await AuditLog.findById(req.params.id).populate(
      'user',
      'name email'
    );

    if (!log) {
      return res.status(404).json({
        success: false,
        message: 'Audit log not found',
      });
    }

    res.status(200).json({
      success: true,
      data: log,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error while fetching audit log',
      error: error.message,
    });
  }
};

// @desc    Get audit log summary (counts by action/module)
// @route   GET /api/audit-logs/summary
// @access  Private (Admin only)
exports.getAuditSummary = async (req, res) => {
  try {
    const byAction = await AuditLog.aggregate([
      { $group: { _id: '$action', count: { $sum: 1 } } },
    ]);

    const byModule = await AuditLog.aggregate([
      { $group: { _id: '$module', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]);

    const recentActivity = await AuditLog.find()
      .populate('user', 'name')
      .sort({ createdAt: -1 })
      .limit(10);

    res.status(200).json({
      success: true,
      data: {
        byAction,
        byModule,
        recentActivity,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error while fetching summary',
      error: error.message,
    });
  }
};