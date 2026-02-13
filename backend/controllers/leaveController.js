const Leave = require('../models/Leave');
const Student = require('../models/Student');
const Faculty = require('../models/Faculty');
const { createNotification } = require('../utils/notificationHelper');
const { validationResult } = require('express-validator');

exports.getMyLeaves = async (req, res) => {
  try {
    const leaves = await Leave.find({ userId: req.user._id }).sort({ createdAt: -1 });
    res.json(leaves);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.applyLeave = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
    const { reason, fromDate, toDate, medicalCertificateUrl } = req.body;
    const role = req.user.role === 'student' ? 'student' : 'faculty';
    const leave = await Leave.create({
      userId: req.user._id,
      role,
      reason,
      fromDate,
      toDate,
      medicalCertificateUrl: medicalCertificateUrl || undefined,
    });
    res.status(201).json(leave);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getAllLeaves = async (req, res) => {
  try {
    const leaves = await Leave.find().populate('userId', 'name email').sort({ createdAt: -1 });
    res.json(leaves);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getStudentLeavesForFaculty = async (req, res) => {
  try {
    const leaves = await Leave.find({ role: 'student' }).populate('userId', 'name email').sort({ createdAt: -1 });
    res.json(leaves);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getFacultyLeavesForAdmin = async (req, res) => {
  try {
    const leaves = await Leave.find({ role: 'faculty' }).populate('userId', 'name email').sort({ createdAt: -1 });
    res.json(leaves);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.reviewLeave = async (req, res) => {
  try {
    const leave = await Leave.findById(req.params.id);
    if (!leave) return res.status(404).json({ message: 'Leave not found.' });
    const { status } = req.body;
    if (!['Approved', 'Rejected'].includes(status)) {
      return res.status(400).json({ message: 'status must be Approved or Rejected.' });
    }
    leave.status = status;
    leave.reviewedBy = req.user._id;
    leave.reviewedAt = new Date();
    await leave.save();
    await createNotification(
      leave.userId,
      `Your leave application has been ${status.toLowerCase()}.`
    );
    res.json(leave);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
