const express = require('express');
const { getNotices, getNoticeById, createNotice, updateNotice, deleteNotice } = require('../controllers/noticeController');
const { auth, role } = require('../middleware/auth');

const router = express.Router();

router.get('/', auth, getNotices);
router.get('/:id', auth, getNoticeById);
router.post('/', auth, role('admin'), createNotice);
router.patch('/:id', auth, role('admin'), updateNotice);
router.delete('/:id', auth, role('admin'), deleteNotice);

module.exports = router;
