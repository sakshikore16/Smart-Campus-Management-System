const cloudinary = require('../config/cloudinary');
const FeeReceipt = require('../models/FeeReceipt');
const SalarySlip = require('../models/SalarySlip');
const Certificate = require('../models/Certificate');
const Student = require('../models/Student');
const Faculty = require('../models/Faculty');
const { createNotification } = require('../utils/notificationHelper');

const uploadToCloudinary = (buffer, folder) => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      { folder: `smartcampus/${folder}` },
      (err, result) => {
        if (err) reject(err);
        else resolve(result);
      }
    );
    uploadStream.end(buffer);
  });
};

exports.uploadCertificate = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id });
    if (!student) return res.status(404).json({ message: 'Student profile not found.' });
    if (!req.file) return res.status(400).json({ message: 'No file uploaded.' });
    const result = await uploadToCloudinary(req.file.buffer, 'certificates');
    const cert = await Certificate.create({
      studentId: student._id,
      title: req.body.title || req.file.originalname,
      fileUrl: result.secure_url,
      cloudinaryId: result.public_id,
    });
    res.status(201).json(cert);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.uploadLeaveMedicalCert = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded.' });
    const result = await uploadToCloudinary(req.file.buffer, 'leave-medical');
    res.status(201).json({ url: result.secure_url });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.uploadComplaintAttachment = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded.' });
    const result = await uploadToCloudinary(req.file.buffer, 'complaint-attachments');
    res.status(201).json({ url: result.secure_url });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.uploadBudgetDocument = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded.' });
    const result = await uploadToCloudinary(req.file.buffer, 'budget-documents');
    res.status(201).json({ url: result.secure_url });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.uploadIdCardAttachment = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded.' });
    const result = await uploadToCloudinary(req.file.buffer, 'id-card-attachments');
    res.status(201).json({ url: result.secure_url });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMyCertificates = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id });
    if (!student) return res.status(404).json({ message: 'Student profile not found.' });
    const certs = await Certificate.find({ studentId: student._id }).sort({ createdAt: -1 });
    res.json(certs);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.uploadFeeReceipt = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded.' });
    const { studentId, title } = req.body;
    if (!studentId) return res.status(400).json({ message: 'studentId required.' });
    const result = await uploadToCloudinary(req.file.buffer, 'fee-receipts');
    const receipt = await FeeReceipt.create({
      studentId,
      title: title || req.file.originalname,
      fileUrl: result.secure_url,
      cloudinaryId: result.public_id,
      uploadedBy: req.user._id,
    });
    const student = await Student.findById(studentId);
    if (student) {
      await createNotification(student.userId, 'A new fee receipt has been uploaded for you.');
    }
    res.status(201).json(receipt);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMyFeeReceipts = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id });
    if (!student) return res.status(404).json({ message: 'Student profile not found.' });
    const receipts = await FeeReceipt.find({ studentId: student._id }).sort({ createdAt: -1 });
    res.json(receipts);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getFeeReceiptsByStudent = async (req, res) => {
  try {
    const { studentId } = req.query;
    const filter = studentId ? { studentId } : {};
    const receipts = await FeeReceipt.find(filter).sort({ createdAt: -1 });
    res.json(receipts);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.uploadSalarySlip = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded.' });
    const { facultyId, title } = req.body;
    if (!facultyId) return res.status(400).json({ message: 'facultyId required.' });
    const result = await uploadToCloudinary(req.file.buffer, 'salary-slips');
    const slip = await SalarySlip.create({
      facultyId,
      title: title || req.file.originalname,
      fileUrl: result.secure_url,
      cloudinaryId: result.public_id,
      uploadedBy: req.user._id,
    });
    const faculty = await Faculty.findById(facultyId);
    if (faculty) {
      await createNotification(faculty.userId, 'A new salary slip has been uploaded for you.');
    }
    res.status(201).json(slip);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMySalarySlips = async (req, res) => {
  try {
    const faculty = await Faculty.findOne({ userId: req.user._id });
    if (!faculty) return res.status(404).json({ message: 'Faculty profile not found.' });
    const slips = await SalarySlip.find({ facultyId: faculty._id }).sort({ createdAt: -1 });
    res.json(slips);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getSalarySlipsByFaculty = async (req, res) => {
  try {
    const { facultyId } = req.query;
    const filter = facultyId ? { facultyId } : {};
    const slips = await SalarySlip.find(filter).sort({ createdAt: -1 });
    res.json(slips);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
