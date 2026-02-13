const mongoose = require('mongoose');

const adminSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  employeeId: { type: String, required: true, trim: true },
  position: { type: String, trim: true },
  department: { type: String, required: true, trim: true },
});

module.exports = mongoose.model('Admin', adminSchema);
