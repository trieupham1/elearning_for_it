const jwt = require('jsonwebtoken');

// Middleware to verify token
const authMiddleware = (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  
  if (!token) {
    console.log('Auth middleware: No token provided');
    return res.status(401).json({ message: 'No token provided' });
  }
  
  if (!process.env.JWT_SECRET) {
    console.error('Auth middleware: JWT_SECRET not configured');
    return res.status(500).json({ message: 'Server configuration error' });
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log(`Auth middleware: Token verified for user ${decoded.userId}`);
    req.user = decoded;
    next();
  } catch (error) {
    console.log(`Auth middleware: Token verification failed - ${error.message}`);
    res.status(401).json({ message: 'Invalid token' });
  }
};

// Middleware to check instructor role
const instructorOnly = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Access denied. Admin only.' });
  }
  next();
};

// Middleware to check student role
const studentOnly = (req, res, next) => {
  if (req.user.role !== 'student') {
    return res.status(403).json({ message: 'Access denied. Student only.' });
  }
  next();
};

// Middleware to check admin role
const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Access denied. Admin only.' });
  }
  next();
};

module.exports = {
  authMiddleware,
  instructorOnly,
  studentOnly,
  adminOnly
};