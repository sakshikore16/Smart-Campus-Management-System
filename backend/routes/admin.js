const express = require('express');
const { body } = require('express-validator');
const { adminLogin } = require('../controllers/authController');
const { me } = require('../controllers/authController');
const { getAdmins, addAdmin, updateAdmin, deleteAdmin } = require('../controllers/userController');
const { auth, role } = require('../middleware/auth');

const router = express.Router();

// Admin-only login (rejects non-admin users). No registration — admins are added by other admins.
router.post(
  '/login',
  [
    body('email').isEmail({ require_tld: false }).normalizeEmail(),
    body('password').notEmpty(),
  ],
  adminLogin
);

router.get('/me', auth, role('admin'), me);

// Only authenticated admins can list and add other admins.
router.get('/admins', auth, role('admin'), getAdmins);
router.post(
  '/admins',
  auth,
  role('admin'),
  [
    body('name').trim().notEmpty(),
    body('email').isEmail({ require_tld: false }).normalizeEmail(),
    body('password').isLength({ min: 6 }),
    body('employeeId').trim().notEmpty(),
    body('department').trim().notEmpty(),
  ],
  addAdmin
);

router.patch(
  '/admins/:id',
  auth,
  role('admin'),
  [
    body('name').optional().trim().notEmpty(),
    body('email').optional().isEmail({ require_tld: false }).normalizeEmail(),
    body('password').optional().isLength({ min: 6 }),
    body('employeeId').optional().trim(),
    body('position').optional().trim(),
    body('department').optional().trim(),
  ],
  updateAdmin
);

router.delete('/admins/:id', auth, role('admin'), deleteAdmin);

module.exports = router;
