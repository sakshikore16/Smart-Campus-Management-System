const mongoose = require('mongoose');

const feeReceiptSchema = new mongoose.Schema({
  studentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Student', required: true },
  title: { type: String, trim: true },
  fileUrl: { type: String, required: true },
  cloudinaryId: { type: String },
  uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('FeeReceipt', feeReceiptSchema);
