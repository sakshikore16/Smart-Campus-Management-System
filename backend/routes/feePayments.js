const express = require('express');
const { auth, role } = require('../middleware/auth');
const {
  createPayment,
  getMyPayments,
  getPaymentsForAdmin,
  approvePayment,
} = require('../controllers/feePaymentController');

const router = express.Router();

router.post('/', auth, role('student'), createPayment);
router.get('/my', auth, role('student'), getMyPayments);
router.get('/admin', auth, role('admin'), getPaymentsForAdmin);
router.patch('/:id/approve', auth, role('admin'), approvePayment);

module.exports = router;
