const Notification = require('../models/Notification');
const User = require('../models/User');
const Student = require('../models/Student');
const Faculty = require('../models/Faculty');

exports.sendToAll = async (req, res) => {
  try {
    const { message } = req.body;
    if (!message) return res.status(400).json({ message: 'message required.' });
    const users = await User.find({ role: { $in: ['student', 'faculty'] } }).select('_id');
    for (const u of users) {
      await Notification.create({ userId: u._id, message });
    }
    res.json({ message: `Notification sent to ${users.length} users.` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.sendToStudents = async (req, res) => {
  try {
    const { message } = req.body;
    if (!message) return res.status(400).json({ message: 'message required.' });
    const students = await Student.find().select('userId');
    for (const s of students) {
      await Notification.create({ userId: s.userId, message });
    }
    res.json({ message: `Notification sent to ${students.length} students.` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.sendToFaculty = async (req, res) => {
  try {
    const { message } = req.body;
    if (!message) return res.status(400).json({ message: 'message required.' });
    const faculty = await Faculty.find().select('userId');
    for (const f of faculty) {
      await Notification.create({ userId: f.userId, message });
    }
    res.json({ message: `Notification sent to ${faculty.length} faculty.` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.sendToUser = async (req, res) => {
  try {
    const { userId, message } = req.body;
    if (!userId || !message) return res.status(400).json({ message: 'userId and message required.' });
    await Notification.create({ userId, message });
    res.json({ message: 'Notification sent.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
