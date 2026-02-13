import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class FeeReceiptRequestScreen extends StatefulWidget {
  const FeeReceiptRequestScreen({super.key});

  @override
  State<FeeReceiptRequestScreen> createState() => _FeeReceiptRequestScreenState();
}

class _FeeReceiptRequestScreenState extends State<FeeReceiptRequestScreen> {
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
      final data = await ApiService.getMyFeeReceiptRequests();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showRequestDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Fee Receipt'),
        content: TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason (optional)'), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.createFeeReceiptRequest(reason: reasonController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted')));
                  _load();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Receipt Request'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showRequestDialog)]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestDialog,
        icon: const Icon(Icons.add),
        label: const Text('Request fee receipt'),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty ? EmptyStateWithAction(message: 'No records found', actionLabel: 'Request fee receipt', onAction: _showRequestDialog, icon: Icons.receipt_long) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final r = _list[i] as Map<String, dynamic>;
          final status = r['status'] as String? ?? '';
          final createdAt = r['createdAt'] != null ? DateTime.tryParse(r['createdAt'] as String) : null;
          return Card(
            child: ListTile(
              title: Text('Fee receipt request'),
              subtitle: Text('$status${createdAt != null ? ' • ${DateFormat.yMd().format(createdAt)}' : ''}'),
              trailing: Chip(label: Text(status), backgroundColor: status == 'Approved' ? Colors.green.shade100 : status == 'Rejected' ? Colors.red.shade100 : Colors.orange.shade100),
            ),
          );
        },
      ),
    );
  }
}
