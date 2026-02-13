const express = require('express');
const { body } = require('express-validator');
const {
  getMyComplaints,
  submitComplaint,
  getAllComplaints,
  updateComplaint,
} = require('../controllers/complaintController');
const { auth, role } = require('../middleware/auth');

const router = express.Router();

router.get('/my', auth, getMyComplaints);
router.post(
  '/',
  auth,
  role('student', 'faculty'),
  [body('subject').trim().notEmpty(), body('description').trim().notEmpty()],
  submitComplaint
);

router.get('/all', auth, role('admin'), getAllComplaints);
router.patch('/:id', auth, role('admin'), updateComplaint);

module.exports = router;
