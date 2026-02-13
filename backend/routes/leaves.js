const express = require('express');
const { body } = require('express-validator');
const {
  getMyLeaves,
  applyLeave,
  getAllLeaves,
  getStudentLeavesForFaculty,
  getFacultyLeavesForAdmin,
  reviewLeave,
} = require('../controllers/leaveController');
const { auth, role } = require('../middleware/auth');

const router = express.Router();

router.get('/my', auth, getMyLeaves);
router.post(
  '/',
  auth,
  role('student', 'faculty'),
  [
    body('reason').trim().notEmpty(),
    body('fromDate').isISO8601(),
    body('toDate').isISO8601(),
  ],
  applyLeave
);

router.get('/all', auth, role('admin'), getAllLeaves);
router.get('/student-leaves', auth, role('faculty'), getStudentLeavesForFaculty);
router.get('/faculty-leaves', auth, role('admin'), getFacultyLeavesForAdmin);
router.patch('/:id/review', auth, role('faculty', 'admin'), reviewLeave);

module.exports = router;
