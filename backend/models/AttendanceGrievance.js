const mongoose = require('mongoose');

const attendanceGrievanceSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  facultyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Faculty', required: true },
  subject: { type: String, required: true, trim: true },
  date: { type: Date, required: true },
  proofUrl: { type: String },
  cloudinaryId: { type: String },
  comments: { type: String, trim: true },
  status: { type: String, enum: ['Pending', 'Approved', 'Rejected'], default: 'Pending' },
  reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  reviewedAt: { type: Date },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('AttendanceGrievance', attendanceGrievanceSchema);
