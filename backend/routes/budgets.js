const express = require('express');
const { auth, role } = require('../middleware/auth');
const { getBudgets, createBudget, approveBudget } = require('../controllers/budgetController');

const router = express.Router();

router.use(auth);
router.get('/', role('admin', 'faculty'), getBudgets);
router.post('/', role('admin', 'faculty'), createBudget);
router.patch('/:id/approve', role('admin'), approveBudget);

module.exports = router;
