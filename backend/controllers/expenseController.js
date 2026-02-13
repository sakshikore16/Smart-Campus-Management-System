const Expense = require('../models/Expense');

exports.getExpenses = async (req, res) => {
  try {
    const expenses = await Expense.find().sort({ createdAt: -1 });
    const total = await Expense.aggregate([{ $group: { _id: null, total: { $sum: '$amount' } } }]);
    res.json({
      expenses,
      total: total[0] ? total[0].total : 0,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.addExpense = async (req, res) => {
  try {
    const { description, amount, category } = req.body;
    if (!description || amount == null) {
      return res.status(400).json({ message: 'description and amount required.' });
    }
    const expense = await Expense.create({
      description,
      amount: Number(amount),
      category: category || '',
      addedBy: req.user._id,
    });
    res.status(201).json(expense);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.deleteExpense = async (req, res) => {
  try {
    const expense = await Expense.findByIdAndDelete(req.params.id);
    if (!expense) return res.status(404).json({ message: 'Expense not found.' });
    res.json({ message: 'Expense deleted.' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
