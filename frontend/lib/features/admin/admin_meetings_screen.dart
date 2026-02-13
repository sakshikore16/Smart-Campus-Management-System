import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class AdminMeetingsScreen extends StatefulWidget {
  const AdminMeetingsScreen({super.key});

  @override
  State<AdminMeetingsScreen> createState() => _AdminMeetingsScreenState();
}

class _AdminMeetingsScreenState extends State<AdminMeetingsScreen> {
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
      final data = await ApiService.getMeetings();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final deptController = TextEditingController();
    DateTime? scheduledAt;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Schedule Meeting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title *')),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                TextField(controller: deptController, decoration: const InputDecoration(labelText: 'Department')),
                ListTile(
                  title: Text(scheduledAt == null ? 'Date & Time *' : DateFormat.yMd().add_Hm().format(scheduledAt!)),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (date == null || !ctx.mounted) return;
                    final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
                    if (time != null) setDialogState(() => scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || scheduledAt == null) return;
                final at = scheduledAt!;
                Navigator.pop(ctx);
                try {
                  await ApiService.createMeeting(titleController.text.trim(), at.toIso8601String(), description: descController.text.trim(), department: deptController.text.trim());
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meeting scheduled')));
                    _load();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meetings'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog)]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Schedule meeting'),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty ? EmptyStateWithAction(message: 'No records found', actionLabel: 'Schedule meeting', onAction: _showCreateDialog, icon: Icons.event) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final m = _list[i] as Map<String, dynamic>;
          final title = m['title'] as String? ?? '';
          final scheduledAt = m['scheduledAt'] != null ? DateTime.tryParse(m['scheduledAt'] as String) : null;
          final department = m['department'] as String? ?? '';
          return Card(
            child: ListTile(
              title: Text(title),
              subtitle: Text('${scheduledAt != null ? DateFormat.yMd().add_Hm().format(scheduledAt) : ''}${department.isNotEmpty ? ' • $department' : ''}'),
            ),
          );
        },
      ),
    );
  }
}
