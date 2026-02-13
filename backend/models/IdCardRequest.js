const mongoose = require('mongoose');

const idCardRequestSchema = new mongoose.Schema({
  facultyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Faculty', required: true },
  issueType: { type: String, enum: ['lost', 'cut', 'damaged'], required: true },
  description: { type: String, trim: true },
  attachmentUrl: { type: String },
  status: { type: String, enum: ['Pending', 'Resolved'], default: 'Pending' },
  adminResponse: { type: String },
  resolvedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  resolvedAt: { type: Date },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('IdCardRequest', idCardRequestSchema);
