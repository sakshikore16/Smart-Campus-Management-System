const express = require('express');
const { body } = require('express-validator');
const {
  getStudents,
  getStudentById,
  getStudentsList,
  addStudent,
  updateStudent,
  deleteStudent,
  getFaculty,
  getFacultyById,
  getFacultyList,
  addFaculty,
  updateFaculty,
  deleteFaculty,
  updateMyProfile,
} = require('../controllers/userController');
const { auth, role } = require('../middleware/auth');

const router = express.Router();

router.get('/faculty-list', auth, getFacultyList);
router.get('/students-list', auth, role('faculty', 'admin'), getStudentsList);

// Student/faculty can update their own profile
router.patch('/me/profile', auth, role('student', 'faculty'), updateMyProfile);

router.use(auth, role('admin'));

router.get('/students', getStudents);
router.get('/students/:id', getStudentById);
router.post(
  '/students',
  [
    body('name').trim().notEmpty(),
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 }),
    body('rollNo').trim().notEmpty(),
    body('department').trim().notEmpty(),
    body('course').trim().notEmpty(),
  ],
  addStudent
);
router.patch('/students/:id', updateStudent);
router.delete('/students/:id', deleteStudent);

router.get('/faculty', getFaculty);
router.get('/faculty/:id', getFacultyById);
router.post(
  '/faculty',
  [
    body('name').trim().notEmpty(),
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 }),
  ],
  addFaculty
);
router.patch('/faculty/:id', updateFaculty);
router.delete('/faculty/:id', deleteFaculty);

module.exports = router;
