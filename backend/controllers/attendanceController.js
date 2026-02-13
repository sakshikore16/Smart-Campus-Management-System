const Attendance = require('../models/Attendance');
const Student = require('../models/Student');
const Faculty = require('../models/Faculty');

exports.getStudentsForAttendance = async (req, res) => {
  try {
    const students = await Student.find().populate('userId', 'name email');
    res.json(students);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMyAttendance = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id });
    if (!student) return res.status(404).json({ message: 'Student profile not found.' });
    const { subject, from, to } = req.query;
    const filter = { studentId: student._id };
    if (subject) filter.subject = subject;
    if (from || to) {
      filter.date = {};
      if (from) filter.date.$gte = new Date(from);
      if (to) filter.date.$lte = new Date(to);
    }
    const attendance = await Attendance.find(filter).sort({ date: -1 });
    res.json(attendance);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getAttendanceByStudent = async (req, res) => {
  try {
    const { studentId, subject, from, to } = req.query;
    const filter = {};
    if (studentId) filter.studentId = studentId;
    if (subject) filter.subject = subject;
    if (from || to) {
      filter.date = {};
      if (from) filter.date.$gte = new Date(from);
      if (to) filter.date.$lte = new Date(to);
    }
    const attendance = await Attendance.find(filter)
      .populate('studentId')
      .sort({ date: -1 });
    res.json(attendance);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.markAttendance = async (req, res) => {
  try {
    const faculty = await Faculty.findOne({ userId: req.user._id });
    if (!faculty) return res.status(403).json({ message: 'Faculty profile not found.' });
    const { studentId, subject, date, status } = req.body;
    if (!studentId || !subject || !date || !status) {
      return res.status(400).json({ message: 'studentId, subject, date, status required.' });
    }
    const record = await Attendance.findOneAndUpdate(
      { studentId, subject, date: new Date(date) },
      { status, markedBy: req.user._id },
      { upsert: true, new: true }
    );
    res.json(record);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.bulkMarkAttendance = async (req, res) => {
  try {
    const faculty = await Faculty.findOne({ userId: req.user._id });
    if (!faculty) return res.status(403).json({ message: 'Faculty profile not found.' });
    const { subject, date, entries } = req.body; // entries: [{ studentId, status }]
    if (!subject || !date || !Array.isArray(entries)) {
      return res.status(400).json({ message: 'subject, date, entries (array) required.' });
    }
    const results = [];
    for (const e of entries) {
      const record = await Attendance.findOneAndUpdate(
        { studentId: e.studentId, subject, date: new Date(date) },
        { status: e.status || 'Present', markedBy: req.user._id },
        { upsert: true, new: true }
      );
      results.push(record);
    }
    res.json(results);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
