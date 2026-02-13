const express = require('express');
const { auth, role } = require('../middleware/auth');
const {
  createRequest,
  getMyRequests,
  getRequestsForAdmin,
  resolveRequest,
} = require('../controllers/idCardRequestController');

const router = express.Router();

router.post('/', auth, role('faculty'), createRequest);
router.get('/my', auth, role('faculty'), getMyRequests);
router.get('/admin', auth, role('admin'), getRequestsForAdmin);
router.patch('/:id/resolve', auth, role('admin'), resolveRequest);

module.exports = router;
