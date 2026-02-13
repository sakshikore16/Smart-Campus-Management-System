import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class AdminIdCardRequestsScreen extends StatefulWidget {
  const AdminIdCardRequestsScreen({super.key});

  @override
  State<AdminIdCardRequestsScreen> createState() => _AdminIdCardRequestsScreenState();
}

class _AdminIdCardRequestsScreenState extends State<AdminIdCardRequestsScreen> {
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
      final data = await ApiService.getIdCardRequestsForAdmin();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showResolveDialog(String id) {
    final responseController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Request'),
        content: TextField(controller: responseController, decoration: const InputDecoration(labelText: 'Admin response'), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.resolveIdCardRequest(id, adminResponse: responseController.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request resolved')));
                  _load();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ID Card Requests')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty ? const EmptyStateMessage(message: 'No ID card requests to review.', icon: Icons.badge) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final r = _list[i] as Map<String, dynamic>;
          final faculty = r['facultyId'] is Map ? r['facultyId'] as Map<String, dynamic> : null;
          final issueType = r['issueType'] as String? ?? '';
          final status = r['status'] as String? ?? '';
          final id = r['_id'] as String?;
          final createdAt = r['createdAt'] != null ? DateTime.tryParse(r['createdAt'] as String) : null;
          final name = faculty != null ? (faculty['userId'] is Map ? (faculty['userId'] as Map)['name'] : '') : 'Faculty';
          return Card(
            child: ListTile(
              title: Text('$name • $issueType'),
              subtitle: Text('$status${createdAt != null ? ' • ${DateFormat.yMd().format(createdAt)}' : ''}'),
              trailing: status == 'Pending' && id != null ? ElevatedButton(onPressed: () => _showResolveDialog(id), child: const Text('Resolve')) : Chip(label: Text(status)),
            ),
          );
        },
      ),
    );
  }
}
