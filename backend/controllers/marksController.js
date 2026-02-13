const Mark = require('../models/Mark');
const Student = require('../models/Student');
const Faculty = require('../models/Faculty');

exports.uploadMarks = async (req, res) => {
  try {
    const faculty = await Faculty.findOne({ userId: req.user._id });
    if (!faculty) return res.status(403).json({ message: 'Faculty profile not found.' });
    const { studentId, subject, examType, marks, maxMarks } = req.body;
    if (!studentId || !subject || marks == null) return res.status(400).json({ message: 'studentId, subject, marks required.' });
    const mark = await Mark.create({
      studentId,
      subject,
      examType: (examType || '').trim(),
      marks: Number(marks),
      maxMarks: maxMarks != null ? Number(maxMarks) : 100,
      uploadedBy: req.user._id,
    });
    res.status(201).json(mark);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMyMarks = async (req, res) => {
  try {
    const student = await Student.findOne({ userId: req.user._id });
    if (!student) return res.status(403).json({ message: 'Student profile not found.' });
    const list = await Mark.find({ studentId: student._id }).sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMarksByStudent = async (req, res) => {
  try {
    const { studentId } = req.query;
    const filter = studentId ? { studentId } : {};
    const list = await Mark.find(filter).sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
