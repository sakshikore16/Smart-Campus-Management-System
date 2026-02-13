const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  rollNo: { type: String, required: true, unique: true, trim: true },
  department: { type: String, required: true, trim: true },
  course: { type: String, required: true, trim: true },
});

module.exports = mongoose.model('Student', studentSchema);
