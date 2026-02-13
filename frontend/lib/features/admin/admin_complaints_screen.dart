import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
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
      final data = await ApiService.getAllComplaints();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showResponseDialog(Map<String, dynamic> complaint) {
    final id = complaint['_id'] as String?;
    if (id == null) return;
    final responseController = TextEditingController(text: complaint['adminResponse'] as String? ?? '');
    String status = complaint['status'] as String? ?? 'Open';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Handle Complaint'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(complaint['subject'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(complaint['description'] as String? ?? ''),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'Open', child: Text('Open')),
                    DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                  ],
                  onChanged: (v) => setDialogState(() => status = v ?? status),
                ),
                const SizedBox(height: 8),
                TextField(controller: responseController, decoration: const InputDecoration(labelText: 'Admin Response'), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ApiService.updateComplaint(id, {'status': status, 'adminResponse': responseController.text});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated')));
                    _load();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const EmptyStateMessage(message: 'No complaints to review.', icon: Icons.report_problem)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final c = _list[i] as Map<String, dynamic>;
                      final user = c['userId'] is Map ? c['userId'] as Map<String, dynamic> : null;
                      final name = user?['name'] ?? '';
                      final subject = c['subject'] as String? ?? '';
                      final status = c['status'] as String? ?? '';
                      final createdAt = c['createdAt'] != null ? DateTime.tryParse(c['createdAt'] as String) : null;
                      return Card(
                        child: ListTile(
                          title: Text('$name: $subject'),
                          subtitle: Text('$status${createdAt != null ? ' • ${DateFormat.yMd().format(createdAt)}' : ''}'),
                          onTap: () => _showResponseDialog(c),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
