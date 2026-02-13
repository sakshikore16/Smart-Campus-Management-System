import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<dynamic> _list = [];
  double _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getExpenses();
      if (mounted) setState(() {
        _list = data['expenses'] is List ? data['expenses'] as List<dynamic> : [];
        _total = (data['total'] as num?)?.toDouble() ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddDialog() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 16),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (descController.text.isEmpty || amountController.text.isEmpty) return;
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount < 0) return;
              Navigator.pop(ctx);
              try {
                await ApiService.addExpense(descController.text, amount);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense added')));
                  _load();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog, tooltip: 'Add expense'),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Expenses'),
                        Text('₹${_total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _list.isEmpty
                      ? EmptyStateWithAction(message: 'No records found', actionLabel: 'Add expense', onAction: _showAddDialog, icon: Icons.receipt)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _list.length,
                          itemBuilder: (_, i) {
                            final e = _list[i] as Map<String, dynamic>;
                            final desc = e['description'] as String? ?? '';
                            final amount = (e['amount'] as num?)?.toDouble() ?? 0;
                            final createdAt = e['createdAt'] != null ? DateTime.tryParse(e['createdAt'] as String) : null;
                            return Card(
                              child: ListTile(
                                title: Text(desc),
                                subtitle: createdAt != null ? Text(DateFormat.yMd().format(createdAt)) : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('₹${amount.toStringAsFixed(2)}'),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        final id = e['_id'] as String?;
                                        if (id == null) return;
                                        try {
                                          await ApiService.deleteExpense(id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
                                            _load();
                                          }
                                        } catch (err) {
                                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$err')));
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
