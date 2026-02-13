require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const Student = require('../models/Student');
const Faculty = require('../models/Faculty');
const Admin = require('../models/Admin');
const Notice = require('../models/Notice');
const Timetable = require('../models/Timetable');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/smartcampusapp';

async function seed() {
  await mongoose.connect(MONGO_URI);
  await User.deleteMany({});
  await Student.deleteMany({});
  await Faculty.deleteMany({});
  await Admin.deleteMany({});
  await Notice.deleteMany({});
  await Timetable.deleteMany({});

  const adminUser = await User.create({
    name: 'Admin User',
    email: 'admin@campus.com',
    password: 'admin123',
    role: 'admin',
  });
  await Admin.create({
    userId: adminUser._id,
    employeeId: 'ADM001',
    position: 'Admin',
    department: 'General',
  });

  const facultyUser = await User.create({
    name: 'Dr. Jane Smith',
    email: 'faculty@campus.com',
    password: 'faculty123',
    role: 'faculty',
  });
  const faculty = await Faculty.create({
    userId: facultyUser._id,
    employeeId: 'FAC001',
    department: 'CSE',
    subjects: ['DBMS', 'OS'],
  });

  const studentUser = await User.create({
    name: 'John Doe',
    email: 'student@campus.com',
    password: 'student123',
    role: 'student',
  });
  const student = await Student.create({
    userId: studentUser._id,
    rollNo: 'CSE101',
    department: 'CSE',
    course: 'B.Tech',
  });

  await Notice.create({
    title: 'Welcome to Smart Campus',
    content: 'This is the first notice. All students and faculty are requested to check notices regularly.',
    type: 'notice',
    createdBy: adminUser._id,
  });

  await Timetable.create([
    { subject: 'DBMS', dayOfWeek: 1, startTime: '09:00', endTime: '10:00', room: 'R101', facultyId: faculty._id },
    { subject: 'OS', dayOfWeek: 2, startTime: '10:00', endTime: '11:00', room: 'R102', facultyId: faculty._id },
  ]);

  console.log('Seed complete.');
  console.log('Admin: admin@campus.com / admin123');
  console.log('Faculty: faculty@campus.com / faculty123');
  console.log('Student: student@campus.com / student123');
  process.exit(0);
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
