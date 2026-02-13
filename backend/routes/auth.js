const express = require('express');
const { body } = require('express-validator');
const { checkEmail, register, login, me } = require('../controllers/authController');
const { auth } = require('../middleware/auth');

const router = express.Router();

router.get('/check-email', checkEmail);

router.post(
  '/register',
  [
    body('name').trim().notEmpty(),
    body('email').isEmail({ require_tld: false }).normalizeEmail(),
    body('password').isLength({ min: 6 }),
    body('role').isIn(['student', 'faculty']),
  ],
  register
);

router.post(
  '/login',
  [
    body('email').isEmail({ require_tld: false }).normalizeEmail(),
    body('password').notEmpty(),
  ],
  login
);

router.get('/me', auth, me);

module.exports = router;
