const Budget = require('../models/Budget');

exports.getBudgets = async (req, res) => {
  try {
    const filter = req.user.role === 'admin' ? {} : { createdBy: req.user._id };
    const list = await Budget.find(filter).sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createBudget = async (req, res) => {
  try {
    const { department, amount, purpose, documentUrl } = req.body;
    if (!department || amount == null) return res.status(400).json({ message: 'department and amount required.' });
    const budget = await Budget.create({
      department: department.trim(),
      amount: Number(amount),
      purpose: (purpose || '').trim(),
      ...(documentUrl && { documentUrl }),
      createdBy: req.user._id,
    });
    res.status(201).json(budget);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.approveBudget = async (req, res) => {
  try {
    const budget = await Budget.findById(req.params.id);
    if (!budget) return res.status(404).json({ message: 'Budget not found.' });
    const { status } = req.body;
    if (!['Approved', 'Rejected'].includes(status)) return res.status(400).json({ message: 'status must be Approved or Rejected.' });
    budget.status = status;
    budget.approvedBy = req.user._id;
    budget.approvedAt = new Date();
    await budget.save();
    res.json(budget);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
