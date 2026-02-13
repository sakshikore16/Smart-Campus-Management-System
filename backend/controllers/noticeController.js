const Notice = require('../models/Notice');
const User = require('../models/User');
const Student = require('../models/Student');
const Faculty = require('../models/Faculty');
const { createNotification } = require('../utils/notificationHelper');

exports.getNotices = async (req, res) => {
  try {
    const { type } = req.query;
    const filter = type ? { type } : {};
    const notices = await Notice.find(filter).populate('createdBy', 'name').sort({ createdAt: -1 });
    res.json(notices);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getNoticeById = async (req, res) => {
  try {
    const notice = await Notice.findById(req.params.id).populate('createdBy', 'name');
    if (!notice) return res.status(404).json({ message: 'Notice not found.' });
    res.json(notice);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createNotice = async (req, res) => {
  try {
    const { title, content, type } = req.body;
    const notice = await Notice.create({
      title,
      content,
      type: type || 'notice',
      createdBy: req.user._id,
    });
    const users = await User.find({ role: { $in: ['student', 'faculty'] } }).select('_id');
    for (const u of users) {
      await createNotification(u._id, `New ${type || 'notice'}: ${title}`);
    }
    const populated = await Notice.findById(notice._id).populate('createdBy', 'name');
    res.status(201).json(populated);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateNotice = async (req, res) => {
  try {
    const notice = await Notice.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    ).populate('createdBy', 'name');
    if (!notice) return res.status(404).json({ message: 'Notice not found.' });
    res.json(notice);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteNotice = async (req, res) => {
  try {
    const notice = await Notice.findByIdAndDelete(req.params.id);
    if (!notice) return res.status(404).json({ message: 'Notice not found.' });
    res.json({ message: 'Notice deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
