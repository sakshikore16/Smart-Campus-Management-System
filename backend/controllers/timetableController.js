const Timetable = require('../models/Timetable');
const Faculty = require('../models/Faculty');
const Student = require('../models/Student');

exports.getTimetable = async (req, res) => {
  try {
    const entries = await Timetable.find().populate('facultyId').sort({ dayOfWeek: 1, startTime: 1 });
    const byDay = {};
    for (let d = 0; d <= 6; d++) byDay[d] = [];
    entries.forEach((e) => {
      byDay[e.dayOfWeek].push(e);
    });
    res.json({ entries, byDay });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getMyTimetable = async (req, res) => {
  try {
    if (req.user.role === 'faculty') {
      const faculty = await Faculty.findOne({ userId: req.user._id });
      if (!faculty) return res.json({ entries: [], byDay: {} });
      const subjects = faculty.subjects || [];
      const entries = await Timetable.find({ subject: { $in: subjects } })
        .populate('facultyId')
        .sort({ dayOfWeek: 1, startTime: 1 });
      const byDay = {};
      for (let d = 0; d <= 6; d++) byDay[d] = [];
      entries.forEach((e) => byDay[e.dayOfWeek].push(e));
      return res.json({ entries, byDay });
    }
    const entries = await Timetable.find().populate('facultyId').sort({ dayOfWeek: 1, startTime: 1 });
    const byDay = {};
    for (let d = 0; d <= 6; d++) byDay[d] = [];
    entries.forEach((e) => byDay[e.dayOfWeek].push(e));
    res.json({ entries, byDay });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createTimetableEntry = async (req, res) => {
  try {
    const { subject, dayOfWeek, startTime, endTime, room, facultyId } = req.body;
    if (!subject || dayOfWeek == null || !startTime || !endTime) {
      return res.status(400).json({ message: 'subject, dayOfWeek, startTime, endTime required.' });
    }

    let finalFacultyId = facultyId;
    if (req.user.role === 'faculty') {
      const faculty = await Faculty.findOne({ userId: req.user._id });
      if (!faculty) return res.status(404).json({ message: 'Faculty profile not found.' });
      finalFacultyId = faculty._id;
    }

    const entry = await Timetable.create({
      subject,
      dayOfWeek: Number(dayOfWeek),
      startTime,
      endTime,
      room: room || '',
      facultyId: finalFacultyId || undefined,
    });
    res.status(201).json(entry);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateTimetableEntry = async (req, res) => {
  try {
    const query = { _id: req.params.id };
    if (req.user.role === 'faculty') {
      const faculty = await Faculty.findOne({ userId: req.user._id });
      if (!faculty) return res.status(404).json({ message: 'Faculty profile not found.' });
      query.facultyId = faculty._id;
    }

    const entry = await Timetable.findOneAndUpdate(query, req.body, { new: true });
    if (!entry) return res.status(404).json({ message: 'Timetable entry not found or permission denied.' });
    res.json(entry);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteTimetableEntry = async (req, res) => {
  try {
    const query = { _id: req.params.id };
    if (req.user.role === 'faculty') {
      const faculty = await Faculty.findOne({ userId: req.user._id });
      if (!faculty) return res.status(404).json({ message: 'Faculty profile not found.' });
      query.facultyId = faculty._id;
    }

    const entry = await Timetable.findOneAndDelete(query);
    if (!entry) return res.status(404).json({ message: 'Timetable entry not found or permission denied.' });
    res.json({ message: 'Entry deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
