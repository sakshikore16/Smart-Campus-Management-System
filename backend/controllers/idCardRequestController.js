const IdCardRequest = require('../models/IdCardRequest');
const Faculty = require('../models/Faculty');
const { createNotification } = require('../utils/notificationHelper');

exports.createRequest = async (req, res) => {
  try {
    const faculty = await Faculty.findOne({ userId: req.user._id });
    if (!faculty) return res.status(403).json({ message: 'Faculty profile not found.' });
    const { issueType, description, attachmentUrl } = req.body;
    if (!issueType || !['lost', 'cut', 'damaged'].includes(issueType)) {
      return res.status(400).json({ message: 'issueType must be lost, cut, or damaged.' });
    }
    const doc = await IdCardRequest.create({
      facultyId: faculty._id,
      issueType,
      description: (description || '').trim(),
      ...(attachmentUrl && { attachmentUrl }),
    });
    res.status(201).json(doc);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMyRequests = async (req, res) => {
  try {
    const faculty = await Faculty.findOne({ userId: req.user._id });
    if (!faculty) return res.status(403).json({ message: 'Faculty profile not found.' });
    const list = await IdCardRequest.find({ facultyId: faculty._id }).sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getRequestsForAdmin = async (req, res) => {
  try {
    const list = await IdCardRequest.find().populate('facultyId').sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.resolveRequest = async (req, res) => {
  try {
    const doc = await IdCardRequest.findById(req.params.id).populate('facultyId');
    if (!doc) return res.status(404).json({ message: 'Request not found.' });
    const { adminResponse } = req.body;
    doc.status = 'Resolved';
    if (adminResponse != null) doc.adminResponse = adminResponse;
    doc.resolvedBy = req.user._id;
    doc.resolvedAt = new Date();
    await doc.save();
    if (doc.facultyId && doc.facultyId.userId) {
      await createNotification(doc.facultyId.userId, 'Your ID card request has been resolved.');
    }
    res.json(doc);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
