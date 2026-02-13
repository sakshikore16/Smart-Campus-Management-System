const express = require('express');
const { auth, role } = require('../middleware/auth');
const {
  uploadMarks,
  getMyMarks,
  getMarksByStudent,
} = require('../controllers/marksController');

const router = express.Router();

router.post('/', auth, role('faculty'), uploadMarks);
router.get('/my', auth, role('student'), getMyMarks);
router.get('/', auth, role('faculty', 'admin'), getMarksByStudent);

module.exports = router;
