const Notification = require('../models/Notification');

const createNotification = async (userId, message) => {
  await Notification.create({ userId, message });
};

module.exports = { createNotification };
