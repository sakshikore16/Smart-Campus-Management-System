const express = require('express');
const {
  getMyNotifications,
  markAsRead,
  markAllAsRead,
  getUnreadCount,
} = require('../controllers/notificationController');
const {
  sendToAll,
  sendToStudents,
  sendToFaculty,
  sendToUser,
} = require('../controllers/adminNotificationController');
const { auth, role } = require('../middleware/auth');

const router = express.Router();

router.get('/', auth, getMyNotifications);
router.get('/unread-count', auth, getUnreadCount);
router.patch('/:id/read', auth, markAsRead);
router.patch('/read-all', auth, markAllAsRead);

router.post('/admin/send-all', auth, role('admin'), sendToAll);
router.post('/admin/send-students', auth, role('admin'), sendToStudents);
router.post('/admin/send-faculty', auth, role('admin'), sendToFaculty);
router.post('/admin/send-user', auth, role('admin'), sendToUser);

module.exports = router;
