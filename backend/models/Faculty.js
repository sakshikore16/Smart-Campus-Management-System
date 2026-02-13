const mongoose = require('mongoose');

const facultySchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  employeeId: { type: String, trim: true },
  department: { type: String, trim: true },
  subjects: [{ type: String, trim: true }],
});

module.exports = mongoose.model('Faculty', facultySchema);
