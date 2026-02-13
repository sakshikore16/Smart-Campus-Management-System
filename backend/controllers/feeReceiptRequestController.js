const FeeReceiptRequest = require('../models/FeeReceiptRequest');
const FeeReceipt = require('../models/FeeReceipt');
const Student = require('../models/Student');
const { createNotification } = require('../utils/notificationHelper');

exports.createRequest = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id });
    if (!student) return res.status(403).json({ message: 'Student profile not found.' });
    const { reason } = req.body;
    const reqDoc = await FeeReceiptRequest.create({
      studentId: student._id,
      reason: (reason || '').trim(),
    });
    res.status(201).json(reqDoc);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMyRequests = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id });
    if (!student) return res.status(403).json({ message: 'Student profile not found.' });
    const list = await FeeReceiptRequest.find({ studentId: student._id }).sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getRequestsForAdmin = async (req, res) => {
  try {
    const list = await FeeReceiptRequest.find().populate('studentId').sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.approveRequest = async (req, res) => {
  try {
    const reqDoc = await FeeReceiptRequest.findById(req.params.id).populate('studentId');
    if (!reqDoc) return res.status(404).json({ message: 'Request not found.' });
    const { status, receiptUrl } = req.body;
    if (!['Approved', 'Rejected'].includes(status)) return res.status(400).json({ message: 'status must be Approved or Rejected.' });
    reqDoc.status = status;
    if (receiptUrl) reqDoc.receiptUrl = receiptUrl;
    reqDoc.approvedBy = req.user._id;
    reqDoc.approvedAt = new Date();
    await reqDoc.save();
    if (reqDoc.studentId && reqDoc.studentId.userId) {
      await createNotification(reqDoc.studentId.userId, `Your fee receipt request has been ${status.toLowerCase()}.`);
    }
    res.json(reqDoc);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
