const express = require('express');
const upload = require('../middleware/upload');
const {
  uploadCertificate,
  uploadLeaveMedicalCert,
  getMyCertificates,
  uploadFeeReceipt,
  getMyFeeReceipts,
  getFeeReceiptsByStudent,
  uploadSalarySlip,
  getMySalarySlips,
  getSalarySlipsByFaculty,
  uploadComplaintAttachment,
  uploadBudgetDocument,
  uploadIdCardAttachment,
} = require('../controllers/fileController');
const { auth, role } = require('../middleware/auth');

const router = express.Router();

router.post('/certificates', auth, role('student'), upload.single('file'), uploadCertificate);
router.post('/leave-medical-cert', auth, role('student', 'faculty'), upload.single('file'), uploadLeaveMedicalCert);
router.post('/complaint-attachment', auth, role('student', 'faculty'), upload.single('file'), uploadComplaintAttachment);
router.post('/budget-document', auth, role('admin', 'faculty'), upload.single('file'), uploadBudgetDocument);
router.post('/id-card-attachment', auth, role('faculty'), upload.single('file'), uploadIdCardAttachment);
router.get('/certificates', auth, role('student'), getMyCertificates);

router.post('/fee-receipts', auth, role('admin'), upload.single('file'), uploadFeeReceipt);
router.get('/fee-receipts', auth, role('student'), getMyFeeReceipts);
router.get('/fee-receipts/admin', auth, role('admin'), getFeeReceiptsByStudent);

router.post('/salary-slips', auth, role('admin'), upload.single('file'), uploadSalarySlip);
router.get('/salary-slips', auth, role('faculty'), getMySalarySlips);
router.get('/salary-slips/admin', auth, role('admin'), getSalarySlipsByFaculty);

module.exports = router;
