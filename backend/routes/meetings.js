const express = require('express');
const { auth, role } = require('../middleware/auth');
const {
  getMeetings,
  createMeeting,
  updateMeeting,
  deleteMeeting,
} = require('../controllers/meetingController');

const router = express.Router();

router.get('/', auth, getMeetings);
router.post('/', auth, role('admin'), createMeeting);
router.patch('/:id', auth, role('admin'), updateMeeting);
router.delete('/:id', auth, role('admin'), deleteMeeting);

module.exports = router;
