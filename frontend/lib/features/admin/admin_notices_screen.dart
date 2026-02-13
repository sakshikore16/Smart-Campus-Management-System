import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class AdminNoticesScreen extends StatefulWidget {
  const AdminNoticesScreen({super.key});

  @override
  State<AdminNoticesScreen> createState() => _AdminNoticesScreenState();
}

class _AdminNoticesScreenState extends State<AdminNoticesScreen> {
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
      final data = await ApiService.getNotices();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateDialog() {
    final title = TextEditingController();
    final content = TextEditingController();
    String type = 'notice';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Post Notice / Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 16),
                TextField(controller: content, decoration: const InputDecoration(labelText: 'Content'), maxLines: 4),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: type,
                  items: const [DropdownMenuItem(value: 'notice', child: Text('Notice')), DropdownMenuItem(value: 'event', child: Text('Event'))],
                  onChanged: (v) => setDialogState(() => type = v ?? 'notice'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (title.text.isEmpty || content.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.createNotice(title.text, content.text, type: type);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice posted')));
                    _load();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices & Events'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Post notice'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? EmptyStateWithAction(message: 'No records found', actionLabel: 'Post notice', onAction: _showCreateDialog, icon: Icons.campaign)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final n = _list[i] as Map<String, dynamic>;
                      final title = n['title'] as String? ?? '';
                      final type = n['type'] as String? ?? 'notice';
                      final id = n['_id'] as String?;
                      final createdAt = n['createdAt'] != null ? DateTime.tryParse(n['createdAt'] as String) : null;
                      return Card(
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text('$type${createdAt != null ? ' • ${DateFormat.yMd().format(createdAt)}' : ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: id == null ? null : () async {
                              if (await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete notice?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes'))])) != true) return;
                              try {
                                await ApiService.deleteNotice(id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
                                  _load();
                                }
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
