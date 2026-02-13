const mongoose = require('mongoose');

const budgetSchema = new mongoose.Schema({
  department: { type: String, required: true, trim: true },
  amount: { type: Number, required: true, min: 0 },
  purpose: { type: String, trim: true },
  documentUrl: { type: String },
  status: { type: String, enum: ['Pending', 'Approved', 'Rejected'], default: 'Pending' },
  approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  approvedAt: { type: Date },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Budget', budgetSchema);
