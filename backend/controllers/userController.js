const mongoose = require('mongoose');
const User = require('../models/User');
const Student = require('../models/Student');
const Faculty = require('../models/Faculty');
const Admin = require('../models/Admin');
const { validationResult } = require('express-validator');

exports.getStudents = async (req, res) => {
  try {
    const students = await Student.find().populate('userId', 'name email');
    res.json(students);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getStudentsList = async (req, res) => {
  try {
    const students = await Student.find().populate('userId', 'name email');
    res.json(students);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getStudentById = async (req, res) => {
  try {
    const student = await Student.findById(req.params.id).populate('userId', 'name email');
    if (!student) return res.status(404).json({ message: 'Student not found.' });
    res.json(student);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.addStudent = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
    const { name, email, password, rollNo, department, course } = req.body;
    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ message: 'Email already registered.' });
    const user = await User.create({ name, email, password, role: 'student' });
    const student = await Student.create({
      userId: user._id,
      rollNo,
      department,
      course,
    });
    const userObj = await User.findById(user._id).select('-password');
    res.status(201).json({ user: userObj, student });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateStudent = async (req, res) => {
  try {
    const student = await Student.findById(req.params.id);
    if (!student) return res.status(404).json({ message: 'Student not found.' });
    const { rollNo, department, course } = req.body;
    if (rollNo) student.rollNo = rollNo;
    if (department) student.department = department;
    if (course) student.course = course;
    await student.save();
    if (req.body.name) {
      await User.findByIdAndUpdate(student.userId, { name: req.body.name });
    }
    const updated = await Student.findById(student._id).populate('userId', 'name email');
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteStudent = async (req, res) => {
  try {
    const student = await Student.findById(req.params.id);
    if (!student) return res.status(404).json({ message: 'Student not found.' });
    await User.findByIdAndDelete(student.userId);
    await Student.findByIdAndDelete(req.params.id);
    res.json({ message: 'Student deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getFaculty = async (req, res) => {
  try {
    const faculty = await Faculty.find().populate('userId', 'name email');
    res.json(faculty);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getFacultyList = async (req, res) => {
  try {
    const faculty = await Faculty.find().populate('userId', 'name');
    res.json(faculty);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getFacultyById = async (req, res) => {
  try {
    const faculty = await Faculty.findById(req.params.id).populate('userId', 'name email');
    if (!faculty) return res.status(404).json({ message: 'Faculty not found.' });
    res.json(faculty);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.addFaculty = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
    const { name, email, password, subjects, employeeId, department } = req.body;
    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ message: 'Email already registered.' });
    const user = await User.create({ name, email, password, role: 'faculty' });
    const faculty = await Faculty.create({
      userId: user._id,
      employeeId: (employeeId || '').trim(),
      department: (department || '').trim(),
      subjects: Array.isArray(subjects) ? subjects : subjects ? [subjects] : [],
    });
    const userObj = await User.findById(user._id).select('-password');
    res.status(201).json({ user: userObj, faculty });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateFaculty = async (req, res) => {
  try {
    const faculty = await Faculty.findById(req.params.id);
    if (!faculty) return res.status(404).json({ message: 'Faculty not found.' });
    if (req.body.subjects !== undefined) faculty.subjects = Array.isArray(req.body.subjects) ? req.body.subjects : req.body.subjects ? [req.body.subjects] : [];
    if (req.body.employeeId !== undefined) faculty.employeeId = req.body.employeeId.trim();
    if (req.body.department !== undefined) faculty.department = req.body.department.trim();
    await faculty.save();
    if (req.body.name !== undefined) {
      await User.findByIdAndUpdate(faculty.userId, { name: req.body.name.trim() });
    }
    const updated = await Faculty.findById(faculty._id).populate('userId', 'name email');
    res.json(updated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteFaculty = async (req, res) => {
  try {
    const faculty = await Faculty.findById(req.params.id);
    if (!faculty) return res.status(404).json({ message: 'Faculty not found.' });
    await User.findByIdAndDelete(faculty.userId);
    await Faculty.findByIdAndDelete(req.params.id);
    res.json({ message: 'Faculty deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Current user updates their own profile (student or faculty only).
exports.updateMyProfile = async (req, res) => {
  try {
    const user = req.user;
    if (user.role === 'student') {
      const student = await Student.findOne({ userId: user._id });
      if (!student) return res.status(404).json({ message: 'Student profile not found.' });
      const { name, rollNo, department, course } = req.body;
      if (name !== undefined) await User.findByIdAndUpdate(user._id, { name: name.trim() });
      if (rollNo !== undefined) student.rollNo = rollNo.trim();
      if (department !== undefined) student.department = department.trim();
      if (course !== undefined) student.course = course.trim();
      await student.save();
      const updated = await Student.findOne({ userId: user._id }).populate('userId', 'name email');
      return res.json(updated);
    }
    if (user.role === 'faculty') {
      const faculty = await Faculty.findOne({ userId: user._id });
      if (!faculty) return res.status(404).json({ message: 'Faculty profile not found.' });
      const { name, employeeId, department, subjects } = req.body;
      if (name !== undefined) await User.findByIdAndUpdate(user._id, { name: name.trim() });
      if (employeeId !== undefined) faculty.employeeId = employeeId.trim();
      if (department !== undefined) faculty.department = department.trim();
      if (subjects !== undefined) faculty.subjects = Array.isArray(subjects) ? subjects : subjects ? [subjects] : [];
      await faculty.save();
      const updated = await Faculty.findOne({ userId: user._id }).populate('userId', 'name email');
      return res.json(updated);
    }
    return res.status(403).json({ message: 'Only students and faculty can update profile here.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Admins: only existing admins can list and add other admins (no public registration).
exports.getAdmins = async (req, res) => {
  try {
    const admins = await Admin.find().populate('userId', 'name email createdAt');
    res.json(admins);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.addAdmin = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
    const { name, email, password, employeeId, position, department } = req.body;
    const existing = await User.findOne({ email: (email || '').toLowerCase().trim() });
    if (existing) return res.status(400).json({ message: 'Email already registered.' });
    const user = await User.create({
      name: (name || '').trim(),
      email: (email || '').toLowerCase().trim(),
      password: password || 'changeme',
      role: 'admin',
    });
    await Admin.create({
      userId: user._id,
      employeeId: (employeeId || '').trim(),
      position: (position || '').trim(),
      department: (department || '').trim(),
    });
    const userObj = await User.findById(user._id).select('-password');
    const profile = await Admin.findOne({ userId: user._id });
    res.status(201).json({ user: userObj, profile: profile || undefined, message: 'Admin added.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateAdmin = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
    const id = req.params.id;
    if (!id || !mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid admin id.' });
    }
    const admin = await Admin.findById(id).populate('userId');
    if (!admin) return res.status(404).json({ message: 'Admin not found.' });
    const user = admin.userId;
    if (!user) return res.status(404).json({ message: 'User not found.' });

    const { name, email, password, employeeId, position, department } = req.body;
    if (name !== undefined) user.name = name.trim();
    if (email !== undefined) {
      const normalized = email.toLowerCase().trim();
      const existing = await User.findOne({ email: normalized, _id: { $ne: user._id } });
      if (existing) return res.status(400).json({ message: 'Email already in use.' });
      user.email = normalized;
    }
    if (password !== undefined && password.length >= 6) user.password = password;
    await user.save();

    if (employeeId !== undefined) admin.employeeId = employeeId.trim();
    if (position !== undefined) admin.position = position.trim();
    if (department !== undefined) admin.department = department.trim();
    await admin.save();

    const userObj = await User.findById(user._id).select('-password');
    const updatedProfile = await Admin.findOne({ userId: user._id });
    res.json({ user: userObj, profile: updatedProfile || undefined, message: 'Admin updated.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteAdmin = async (req, res) => {
  try {
    const id = req.params.id;
    if (!id || !mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Invalid admin id.' });
    }
    const admin = await Admin.findById(id);
    if (!admin) return res.status(404).json({ message: 'Admin not found.' });
    if (admin.userId.toString() === req.user._id.toString()) {
      return res.status(400).json({ message: 'You cannot delete your own account.' });
    }
    const count = await Admin.countDocuments();
    if (count <= 1) return res.status(400).json({ message: 'Cannot delete the last admin. At least one admin must remain.' });
    await User.findByIdAndDelete(admin.userId);
    await Admin.findByIdAndDelete(id);
    res.json({ message: 'Admin deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
