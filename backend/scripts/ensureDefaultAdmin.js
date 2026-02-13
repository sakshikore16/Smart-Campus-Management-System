const User = require('../models/User');
const Admin = require('../models/Admin');

const DEFAULT_ADMIN_EMAIL = process.env.DEFAULT_ADMIN_EMAIL || 'admin@campus.com';
const DEFAULT_ADMIN_PASSWORD = process.env.DEFAULT_ADMIN_PASSWORD || 'admin123';
const DEFAULT_ADMIN_NAME = process.env.DEFAULT_ADMIN_NAME || 'Admin User';

/**
 * Creates a default admin if no admins exist. Run after DB connect on server startup.
 */
async function ensureDefaultAdmin() {
  const adminCount = await Admin.countDocuments();
  if (adminCount > 0) return;

  const existingUser = await User.findOne({ email: DEFAULT_ADMIN_EMAIL.toLowerCase().trim() });
  if (existingUser) return;

  const adminUser = await User.create({
    name: DEFAULT_ADMIN_NAME.trim(),
    email: DEFAULT_ADMIN_EMAIL.toLowerCase().trim(),
    password: DEFAULT_ADMIN_PASSWORD,
    role: 'admin',
  });
  await Admin.create({
    userId: adminUser._id,
    employeeId: 'ADM001',
    position: 'Admin',
    department: 'General',
  });
  console.log(`Default admin created: ${DEFAULT_ADMIN_EMAIL} (change password after first login in production)`);
}

module.exports = { ensureDefaultAdmin };
