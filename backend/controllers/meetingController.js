const Meeting = require('../models/Meeting');

exports.getMeetings = async (req, res) => {
  try {
    const list = await Meeting.find().sort({ scheduledAt: 1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createMeeting = async (req, res) => {
  try {
    const { title, description, scheduledAt, department } = req.body;
    if (!title || !scheduledAt) return res.status(400).json({ message: 'title and scheduledAt required.' });
    const meeting = await Meeting.create({
      title: title.trim(),
      description: (description || '').trim(),
      scheduledAt: new Date(scheduledAt),
      department: (department || '').trim(),
      createdBy: req.user._id,
    });
    res.status(201).json(meeting);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.updateMeeting = async (req, res) => {
  try {
    const meeting = await Meeting.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!meeting) return res.status(404).json({ message: 'Meeting not found.' });
    res.json(meeting);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteMeeting = async (req, res) => {
  try {
    const meeting = await Meeting.findByIdAndDelete(req.params.id);
    if (!meeting) return res.status(404).json({ message: 'Meeting not found.' });
    res.json({ message: 'Meeting deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
