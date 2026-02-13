import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class AdminLeavesScreen extends StatefulWidget {
  const AdminLeavesScreen({super.key});

  @override
  State<AdminLeavesScreen> createState() => _AdminLeavesScreenState();
}

class _AdminLeavesScreenState extends State<AdminLeavesScreen> {
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
      final data = await ApiService.getAllLeaves();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(String id, String status) async {
    try {
      await ApiService.reviewLeave(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Leave $status')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave Applications')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const EmptyStateMessage(message: 'No leave applications to review.', icon: Icons.event_busy)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final l = _list[i] as Map<String, dynamic>;
                      final user = l['userId'] is Map ? l['userId'] as Map<String, dynamic> : null;
                      final name = user?['name'] ?? '';
                      final reason = l['reason'] as String? ?? '';
                      final status = l['status'] as String? ?? '';
                      final from = l['fromDate'] != null ? DateTime.tryParse(l['fromDate'] as String) : null;
                      final to = l['toDate'] != null ? DateTime.tryParse(l['toDate'] as String) : null;
                      final id = l['_id'] as String?;
                      return Card(
                        child: ListTile(
                          title: Text('$name: $reason'),
                          subtitle: Text('${from != null ? DateFormat.yMd().format(from) : ''} - ${to != null ? DateFormat.yMd().format(to) : ''} • $status'),
                          isThreeLine: true,
                          trailing: status == 'Pending' && id != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(onPressed: () => _review(id, 'Approved'), child: const Text('Approve')),
                                    TextButton(onPressed: () => _review(id, 'Rejected'), child: const Text('Reject')),
                                  ],
                                )
                              : Chip(label: Text(status)),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
