const FeePayment = require('../models/FeePayment');
const Student = require('../models/Student');
const { createNotification } = require('../utils/notificationHelper');

exports.createPayment = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id });
    if (!student) return res.status(403).json({ message: 'Student profile not found.' });
    const { amount, academicYear } = req.body;
    if (amount == null || amount < 0) return res.status(400).json({ message: 'Valid amount required.' });
    const payment = await FeePayment.create({
      studentId: student._id,
      amount: Number(amount),
      academicYear: (academicYear || '').trim() || undefined,
      status: 'Pending',
    });
    res.status(201).json(payment);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMyPayments = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id });
    if (!student) return res.status(403).json({ message: 'Student profile not found.' });
    const list = await FeePayment.find({ studentId: student._id }).sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getPaymentsForAdmin = async (req, res) => {
  try {
    const list = await FeePayment.find().populate('studentId').sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.approvePayment = async (req, res) => {
  try {
    const payment = await FeePayment.findById(req.params.id).populate('studentId');
    if (!payment) return res.status(404).json({ message: 'Payment not found.' });
    const { status } = req.body;
    if (!['Approved', 'Rejected'].includes(status)) return res.status(400).json({ message: 'status must be Approved or Rejected.' });
    payment.status = status;
    payment.approvedBy = req.user._id;
    payment.approvedAt = new Date();
    await payment.save();
    if (payment.studentId && payment.studentId.userId) {
      await createNotification(payment.studentId.userId, `Your fee payment has been ${status.toLowerCase()}.`);
    }
    res.json(payment);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
