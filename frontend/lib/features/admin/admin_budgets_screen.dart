import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class AdminBudgetsScreen extends StatefulWidget {
  const AdminBudgetsScreen({super.key});

  @override
  State<AdminBudgetsScreen> createState() => _AdminBudgetsScreenState();
}

class _AdminBudgetsScreenState extends State<AdminBudgetsScreen> {
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

  void _showCreateDialog() {
    final deptController = TextEditingController();
    final amountController = TextEditingController();
    final purposeController = TextEditingController();
    String? documentUrl;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: deptController, decoration: const InputDecoration(labelText: 'Department *')),
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount *'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose')),
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
                if (deptController.text.isEmpty || amountController.text.isEmpty) return;
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount < 0) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.createBudget(deptController.text.trim(), amount, purpose: purposeController.text.trim(), documentUrl: documentUrl);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Budget added')));
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
      ),
    );
  }

  Future<void> _approve(String id, String status) async {
    try {
      await ApiService.approveBudget(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Budget $status')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog)]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add budget'),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty ? EmptyStateWithAction(message: 'No records found', actionLabel: 'Add budget', onAction: _showCreateDialog, icon: Icons.account_balance_wallet) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final b = _list[i] as Map<String, dynamic>;
          final department = b['department'] as String? ?? '';
          final amount = (b['amount'] as num?)?.toDouble() ?? 0;
          final status = b['status'] as String? ?? '';
          final id = b['_id'] as String?;
          final createdAt = b['createdAt'] != null ? DateTime.tryParse(b['createdAt'] as String) : null;
          return Card(
            child: ListTile(
              title: Text('$department • ₹${amount.toStringAsFixed(2)}'),
              subtitle: Text('$status${createdAt != null ? ' • ${DateFormat.yMd().format(createdAt)}' : ''}'),
              trailing: status == 'Pending' && id != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(onPressed: () => _approve(id, 'Approved'), child: const Text('Approve')),
                        TextButton(onPressed: () => _approve(id, 'Rejected'), child: const Text('Reject')),
                      ],
                    )
                  : Chip(label: Text(status)),
            ),
          );
        },
      ),
    );
  }
}
