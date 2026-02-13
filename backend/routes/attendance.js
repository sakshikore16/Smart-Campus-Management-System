const express = require('express');
const {
  getStudentsForAttendance,
  getMyAttendance,
  getAttendanceByStudent,
  markAttendance,
  bulkMarkAttendance,
} = require('../controllers/attendanceController');
const { auth, role } = require('../middleware/auth');

const router = express.Router();

router.get('/students', auth, role('faculty', 'admin'), getStudentsForAttendance);
router.get('/my', auth, role('student'), getMyAttendance);
router.get('/', auth, role('admin'), getAttendanceByStudent);
router.post('/mark', auth, role('faculty'), markAttendance);
router.post('/mark/bulk', auth, role('faculty'), bulkMarkAttendance);

module.exports = router;
