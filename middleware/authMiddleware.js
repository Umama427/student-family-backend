const jwt = require('jsonwebtoken');
const Admin = require('../models/Admin');
const Staff = require('../models/Staff');
const Family = require('../models/Family');

const JWT_SECRET = process.env.JWT_SECRET || 'edumanage_super_secret_key_umama_2026';

async function resolveUserFromToken(token) {
  const decoded = jwt.verify(token, JWT_SECRET);
  const role = decoded.role || 'admin';

  let user;
  if (role === 'admin') {
    user = await Admin.findById(decoded.id).select('-password');
  } else if (role === 'teacher') {
    user = await Staff.findById(decoded.id).select('-password');
  } else if (role === 'parent') {
    user = await Family.findById(decoded.id);
  }
  return { user, role };
}

// ✅ Universal protect — works for Admin, Teacher, Parent (Authorization header only)
exports.protect = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({ success: false, message: 'Not authorized, no token' });
    }

    const { user, role } = await resolveUserFromToken(token);

    if (!user) {
      return res.status(401).json({ success: false, message: `${role} not found` });
    }

    if (role === 'admin') {
      req.admin = user; // ✅ Backward compatibility - purane controllers ke liye
    }

    req.role = role;
    req.user = user; // ✅ Generic access har role ke liye

    next();
  } catch (error) {
    return res.status(401).json({ success: false, message: 'Not authorized, token failed' });
  }
};

// ✅ NEW: Flexible protect — Authorization header OR ?token= query OR form-body token
// Zaroorat: payment redirect pages browser navigation (url_launcher) se khulte hain,
// jahan custom headers bheja possible nahi hota — isliye yahan token ko URL/body
// ke through bhi accept karte hain, taake ye routes bhi secure rahein.
exports.protectFlexible = async (req, res, next) => {
  try {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    } else if (req.query && req.query.token) {
      token = req.query.token;
    } else if (req.body && req.body.token) {
      token = req.body.token;
    }

    if (!token) {
      return res.status(401).send('<h3>Not authorized — missing or expired session.</h3>');
    }

    const { user, role } = await resolveUserFromToken(token);

    if (!user) {
      return res.status(401).send('<h3>Not authorized — user not found.</h3>');
    }

    if (role === 'admin') {
      req.admin = user;
    }

    req.role = role;
    req.user = user;
    req.authToken = token; // controllers isko dobara HTML form me embed kar sakte hain

    next();
  } catch (error) {
    return res.status(401).send('<h3>Not authorized — invalid or expired token.</h3>');
  }
};

// ✅ Role-based restriction
// Usage: authorize('admin') ya authorize('admin', 'teacher')
exports.authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.role)) {
      return res.status(403).json({
        success: false,
        message: `Access denied. '${req.role}' role is not authorized for this action.`,
      });
    }
    next();
  };
};