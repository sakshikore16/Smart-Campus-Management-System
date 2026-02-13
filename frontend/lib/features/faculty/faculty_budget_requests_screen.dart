import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class FacultyBudgetRequestsScreen extends StatefulWidget {
  const FacultyBudgetRequestsScreen({super.key});

  @override
  State<FacultyBudgetRequestsScreen> createState() => _FacultyBudgetRequestsScreenState();
}

class _FacultyBudgetRequestsScreenState extends State<FacultyBudgetRequestsScreen> {
  List<dynamic> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getBudgets();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showRequestDialog() {
    final deptController = TextEditingController();
    final amountController = TextEditingController();
    final purposeController = TextEditingController();
    String? documentUrl;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Request Budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: deptController, decoration: const InputDecoration(labelText: 'Department *')),
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount (₹) *'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose / What for *'), maxLines: 2),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: Icon(documentUrl != null ? Icons.check_circle : Icons.upload_file),
                  label: Text(documentUrl != null ? 'Document attached' : 'Upload document (optional)'),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
                    if (result != null && result.files.single.bytes != null) {
                      try {
                        final url = await ApiService.uploadBudgetDocument(result.files.single.bytes!, result.files.single.name);
                        if (ctx.mounted) setDialogState(() => documentUrl = url);
                      } catch (_) {}
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (deptController.text.isEmpty || amountController.text.isEmpty || purposeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill department, amount and purpose')));
                  return;
                }
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ApiService.createBudget(
                    deptController.text.trim(),
                    amount,
                    purpose: purposeController.text.trim(),
                    documentUrl: documentUrl,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Budget request submitted')));
                    _load();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Submit request'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Budget Requests'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showRequestDialog)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestDialog,
        icon: const Icon(Icons.add),
        label: const Text('Request budget'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? EmptyStateWithAction(
                  message: 'No budget requests yet.',
                  actionLabel: 'Request budget',
                  onAction: _showRequestDialog,
                  icon: Icons.account_balance_wallet,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _list.length,
                  itemBuilder: (_, i) {
                    final b = _list[i] as Map<String, dynamic>;
                    final department = b['department'] as String? ?? '';
                    final amount = (b['amount'] as num?)?.toDouble() ?? 0;
                    final purpose = b['purpose'] as String? ?? '';
                    final status = b['status'] as String? ?? '';
                    final createdAt = b['createdAt'] != null ? DateTime.tryParse(b['createdAt'] as String) : null;
                    Color statusColor = Colors.orange;
                    if (status == 'Approved') statusColor = Colors.green;
                    if (status == 'Rejected') statusColor = Colors.red;
                    return Card(
                      child: ListTile(
                        title: Text(department),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (purpose.isNotEmpty) Text(purpose),
                            Text('₹${amount.toStringAsFixed(2)}${createdAt != null ? ' • ${DateFormat.yMd().format(createdAt)}' : ''}'),
                          ],
                        ),
                        trailing: Chip(label: Text(status), backgroundColor: statusColor.withValues(alpha: 0.2)),
                      ),
                    );
                  },
                ),
    );
  }
}
