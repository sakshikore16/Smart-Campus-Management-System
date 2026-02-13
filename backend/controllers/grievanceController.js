const cloudinary = require('../config/cloudinary');
const AttendanceGrievance = require('../models/AttendanceGrievance');
const Student = require('../models/Student');
const Faculty = require('../models/Faculty');
const { createNotification } = require('../utils/notificationHelper');

const uploadProof = (buffer) => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      { folder: 'smartcampus/grievance-proof' },
      (err, result) => (err ? reject(err) : resolve(result))
    );
    uploadStream.end(buffer);
  });
};

exports.createGrievance = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id });
    if (!student) return res.status(403).json({ message: 'Student profile not found.' });
    const { facultyId, subject, date, comments } = req.body;
    if (!facultyId || !subject || !date) return res.status(400).json({ message: 'facultyId, subject, date required.' });
    const facultyObj = await Faculty.findById(facultyId);
    if (!facultyObj) return res.status(400).json({ message: 'Invalid faculty selected.' });
    let proofUrl, cloudinaryId;
    if (req.file && req.file.buffer) {
      const result = await uploadProof(req.file.buffer);
      proofUrl = result.secure_url;
      cloudinaryId = result.public_id;
    }
    const grievance = await AttendanceGrievance.create({
      studentId: student._id,
      facultyId: facultyObj._id,
      subject: String(subject).trim(),
      date: new Date(date),
      proofUrl: proofUrl || req.body.proofUrl || undefined,
      cloudinaryId: cloudinaryId || req.body.cloudinaryId,
      comments: comments ? String(comments).trim() : '',
    });
    if (facultyObj) await createNotification(facultyObj.userId, 'New attendance correction request from a student.');
    res.status(201).json(grievance);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMyGrievances = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id });
    if (!student) return res.status(403).json({ message: 'Student profile not found.' });
    const list = await AttendanceGrievance.find({ studentId: student._id })
      .populate('facultyId')
      .sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getGrievancesForFaculty = async (req, res) => {
  try {
    const faculty = await Faculty.findOne({ userId: req.user._id });
    if (!faculty) return res.status(403).json({ message: 'Faculty profile not found.' });
    const list = await AttendanceGrievance.find({ facultyId: faculty._id, status: 'Pending' })
      .populate({ path: 'studentId', populate: { path: 'userId', select: 'name' } })
      .sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.reviewGrievance = async (req, res) => {
  try {
    const grievance = await AttendanceGrievance.findById(req.params.id).populate('studentId');
    if (!grievance) return res.status(404).json({ message: 'Grievance not found.' });
    const { status } = req.body;
    if (!['Approved', 'Rejected'].includes(status)) return res.status(400).json({ message: 'status must be Approved or Rejected.' });
    grievance.status = status;
    grievance.reviewedBy = req.user._id;
    grievance.reviewedAt = new Date();
    await grievance.save();
    if (grievance.studentId && grievance.studentId.userId) {
      await createNotification(grievance.studentId.userId, `Your attendance correction request has been ${status.toLowerCase()}.`);
    }
    res.json(grievance);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
