const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Student = require('../models/Student');
const Faculty = require('../models/Faculty');
const Admin = require('../models/Admin');
const { validationResult } = require('express-validator');

const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

exports.checkEmail = async (req, res) => {
  try {
    const { email } = req.query;
    if (!email) return res.status(400).json({ message: 'Email is required.' });
    const user = await User.findOne({ email: email.toLowerCase().trim() });
    res.json({ exists: !!user });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.register = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const firstMsg = errors.array()[0]?.msg || 'Validation failed';
      return res.status(400).json({ message: firstMsg, errors: errors.array() });
    }
    const { name, email, password, role } = req.body;
    const existing = await User.findOne({ email: email.toLowerCase().trim() });
    if (existing) return res.status(400).json({ message: 'Email already registered.' });

    const user = await User.create({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password,
      role,
    });

    if (role === 'student') {
      const { rollNo, department, course } = req.body;
      if (!rollNo || !department || !course) return res.status(400).json({ message: 'rollNo, department, course required for student.' });
      await Student.create({ userId: user._id, rollNo: rollNo.trim(), department: department.trim(), course: course.trim() });
    } else if (role === 'faculty') {
      const { employeeId, department, subjects } = req.body;
      await Faculty.create({
        userId: user._id,
        employeeId: (employeeId || '').trim(),
        department: (department || '').trim(),
        subjects: Array.isArray(subjects) ? subjects : subjects ? [subjects] : [],
      });
    }
    // Admin cannot register via this endpoint; admins are added only by existing admins from the admin portal.

    const userObj = await User.findById(user._id).select('-password');
    let profile = null;
    if (role === 'student') profile = await Student.findOne({ userId: user._id });
    else if (role === 'faculty') profile = await Faculty.findOne({ userId: user._id });

    const token = generateToken(user._id);
    res.status(201).json({
      token,
      user: userObj,
      profile: profile || undefined,
      message: 'Registration successful.',
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.login = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
    const { email, password } = req.body;
    const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+password');
    if (!user) {
      return res.status(401).json({ message: 'Email not registered. Please register first.', code: 'EMAIL_NOT_FOUND' });
    }
    const match = await user.comparePassword(password);
    if (!match) {
      return res.status(401).json({ message: 'Invalid password.' });
    }
    const token = generateToken(user._id);
    const userObj = await User.findById(user._id).select('-password');
    let profile = null;
    if (user.role === 'student') profile = await Student.findOne({ userId: user._id });
    else if (user.role === 'faculty') profile = await Faculty.findOne({ userId: user._id });
    else if (user.role === 'admin') profile = await Admin.findOne({ userId: user._id });
    res.json({ token, user: userObj, profile: profile || undefined });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.me = async (req, res) => {
  try {
    const user = req.user;
    let profile = null;
    if (user.role === 'student') profile = await Student.findOne({ userId: user._id });
    else if (user.role === 'faculty') profile = await Faculty.findOne({ userId: user._id });
    else if (user.role === 'admin') profile = await Admin.findOne({ userId: user._id });
    res.json({ user, profile: profile || undefined });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

/** Admin-only login: same as login but rejects non-admin users. Use separate URL /api/admin/login. */
exports.adminLogin = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
    const { email, password } = req.body;
    const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+password');
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }
    const match = await user.comparePassword(password);
    if (!match) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }
    if (user.role !== 'admin') {
      return res.status(403).json({ message: 'Access denied. This portal is for administrators only.' });
    }
    const token = generateToken(user._id);
    const userObj = await User.findById(user._id).select('-password');
    const profile = await Admin.findOne({ userId: user._id });
    res.json({ token, user: userObj, profile: profile || undefined });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
