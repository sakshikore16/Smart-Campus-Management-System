import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class AdminFeePaymentsScreen extends StatefulWidget {
  const AdminFeePaymentsScreen({super.key});

  @override
  State<AdminFeePaymentsScreen> createState() => _AdminFeePaymentsScreenState();
}

class _AdminFeePaymentsScreenState extends State<AdminFeePaymentsScreen> {
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
      final data = await ApiService.getFeePaymentsForAdmin();
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
      await ApiService.approveFeePayment(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment $status')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Payments Approval')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty ? const EmptyStateMessage(message: 'No fee payments to review.', icon: Icons.payment) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final p = _list[i] as Map<String, dynamic>;
          final student = p['studentId'] is Map ? p['studentId'] as Map<String, dynamic> : null;
          final amount = (p['amount'] as num?)?.toDouble() ?? 0;
          final status = p['status'] as String? ?? '';
          final id = p['_id'] as String?;
          final createdAt = p['createdAt'] != null ? DateTime.tryParse(p['createdAt'] as String) : null;
          final name = student != null ? (student['userId'] is Map ? (student['userId'] as Map)['name'] : '') : 'Student';
          return Card(
            child: ListTile(
              title: Text('$name • ₹${amount.toStringAsFixed(2)}'),
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
