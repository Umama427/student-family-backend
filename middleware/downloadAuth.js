const jwt = require('jsonwebtoken');
const Staff = require('../models/Staff');

const downloadAuth = (...allowedRoles) => {
  return async (req, res, next) => {
    try {
      let token = null;
      const authHeader = req.headers.authorization;
      if (authHeader && authHeader.startsWith('Bearer ')) {
        token = authHeader.split(' ')[1];
      } else if (req.query.token) {
        token = req.query.token;
      }
      if (!token) return res.status(401).json({ success: false, message: 'Not authorized, no token' });

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = { _id: decoded.id, id: decoded.id, role: decoded.role };

      if (allowedRoles.length && !allowedRoles.includes(decoded.role)) {
        return res.status(403).json({ success: false, message: 'Not authorized for this action' });
      }

      if (decoded.role === 'teacher') {
        const staff = await Staff.findById(decoded.id);
        req.user.assignedClasses = staff ? staff.assignedClasses : [];
      }
      if (decoded.role === 'parent') {
        req.user.familyId = decoded.id;
      }

      next();
    } catch (err) {
      return res.status(401).json({ success: false, message: 'Invalid or expired session' });
    }
  };
};

module.exports = downloadAuth;