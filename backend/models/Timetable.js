const mongoose = require('mongoose');

const timetableSchema = new mongoose.Schema({
  subject: { type: String, required: true, trim: true },
  dayOfWeek: { type: Number, required: true, min: 0, max: 6 }, // 0 = Sunday
  startTime: { type: String, required: true },
  endTime: { type: String, required: true },
  room: { type: String, trim: true },
  facultyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Faculty' },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Timetable', timetableSchema);
