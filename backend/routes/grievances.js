const express = require('express');
const upload = require('../middleware/upload');
const { auth, role } = require('../middleware/auth');
const {
  createGrievance,
  getMyGrievances,
  getGrievancesForFaculty,
  reviewGrievance,
} = require('../controllers/grievanceController');

const router = express.Router();

router.post('/', auth, role('student'), upload.single('proof'), createGrievance);
router.get('/my', auth, role('student'), getMyGrievances);
router.get('/faculty', auth, role('faculty'), getGrievancesForFaculty);
router.patch('/:id/review', auth, role('faculty'), reviewGrievance);

module.exports = router;
