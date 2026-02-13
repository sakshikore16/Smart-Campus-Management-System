const express = require('express');
const { auth, role } = require('../middleware/auth');
const {
  createRequest,
  getMyRequests,
  getRequestsForAdmin,
  approveRequest,
} = require('../controllers/feeReceiptRequestController');

const router = express.Router();

router.post('/', auth, role('student'), createRequest);
router.get('/my', auth, role('student'), getMyRequests);
router.get('/admin', auth, role('admin'), getRequestsForAdmin);
router.patch('/:id/approve', auth, role('admin'), approveRequest);

module.exports = router;
