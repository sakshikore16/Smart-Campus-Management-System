const express = require('express');
const {
  getTimetable,
  getMyTimetable,
  createTimetableEntry,
  updateTimetableEntry,
  deleteTimetableEntry,
} = require('../controllers/timetableController');
const { auth, role } = require('../middleware/auth');

const router = express.Router();

router.get('/', auth, getTimetable);
router.get('/my', auth, getMyTimetable);
router.post('/', auth, role('admin', 'faculty'), createTimetableEntry);
router.patch('/:id', auth, role('admin', 'faculty'), updateTimetableEntry);
router.delete('/:id', auth, role('admin', 'faculty'), deleteTimetableEntry);

module.exports = router;
