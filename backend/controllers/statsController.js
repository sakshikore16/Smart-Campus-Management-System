const Student = require('../models/Student');
const Faculty = require('../models/Faculty');
const Leave = require('../models/Leave');
const Attendance = require('../models/Attendance');
const Expense = require('../models/Expense');
const FeeReceipt = require('../models/FeeReceipt');

exports.getDashboardStats = async (req, res) => {
  try {
    const [studentCount, facultyCount, pendingLeaves, totalExpenses, recentReceipts] =
      await Promise.all([
        Student.countDocuments(),
        Faculty.countDocuments(),
        Leave.countDocuments({ status: 'Pending' }),
        Expense.aggregate([{ $group: { _id: null, total: { $sum: '$amount' } } }]),
        FeeReceipt.countDocuments(),
      ]);
    res.json({
      students: studentCount,
      faculty: facultyCount,
      pendingLeaves,
      totalExpenses: totalExpenses[0] ? totalExpenses[0].total : 0,
      feeReceiptsCount: recentReceipts,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
