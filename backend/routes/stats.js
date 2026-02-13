const express = require('express');
const { getDashboardStats } = require('../controllers/statsController');
const { auth, role } = require('../middleware/auth');

const router = express.Router();

router.get('/dashboard', auth, role('admin'), getDashboardStats);

module.exports = router;
