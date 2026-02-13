import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class AdminFeeReceiptRequestsScreen extends StatefulWidget {
  const AdminFeeReceiptRequestsScreen({super.key});

  @override
  State<AdminFeeReceiptRequestsScreen> createState() => _AdminFeeReceiptRequestsScreenState();
}

class _AdminFeeReceiptRequestsScreenState extends State<AdminFeeReceiptRequestsScreen> {
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
      final data = await ApiService.getFeeReceiptRequestsForAdmin();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(String id, String status) async {
    try {
      await ApiService.approveFeeReceiptRequest(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $status')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Receipt Requests')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty ? const EmptyStateMessage(message: 'No fee receipt requests to review.', icon: Icons.receipt_long) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final r = _list[i] as Map<String, dynamic>;
          final student = r['studentId'] is Map ? r['studentId'] as Map<String, dynamic> : null;
          final status = r['status'] as String? ?? '';
          final id = r['_id'] as String?;
          final createdAt = r['createdAt'] != null ? DateTime.tryParse(r['createdAt'] as String) : null;
          final name = student != null ? (student['userId'] is Map ? (student['userId'] as Map)['name'] : '') : 'Student';
          return Card(
            child: ListTile(
              title: Text('$name'),
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
