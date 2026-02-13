import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/auth_provider.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  Map<String, dynamic> _data = {};
  bool _useMy = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = _useMy ? await ApiService.getMyTimetable() : await ApiService.getTimetable();
      if (mounted) setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const List<String> _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  Future<void> _showEntryDialog([Map<String, dynamic>? entry]) async {
    final isEditing = entry != null;
    final subjectController = TextEditingController(text: entry?['subject'] ?? '');
    final roomController = TextEditingController(text: entry?['room'] ?? '');
    final startTimeController = TextEditingController(text: entry?['startTime'] ?? '');
    final endTimeController = TextEditingController(text: entry?['endTime'] ?? '');
    int dayOfWeek = entry?['dayOfWeek'] ?? 1;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Entry' : 'Add Entry'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: 'Room'),
                ),
                DropdownButtonFormField<int>(
                  value: dayOfWeek,
                  items: List.generate(7, (index) => DropdownMenuItem(value: index, child: Text(_days[index]))),
                  onChanged: (val) {
                    setState(() => dayOfWeek = val!);
                  },
                  decoration: const InputDecoration(labelText: 'Day'),
                ),
                TextField(
                  controller: startTimeController,
                  decoration: const InputDecoration(labelText: 'Start Time (e.g. 10:00)'),
                ),
                TextField(
                  controller: endTimeController,
                  decoration: const InputDecoration(labelText: 'End Time (e.g. 11:00)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final body = {
                    'subject': subjectController.text,
                    'room': roomController.text,
                    'dayOfWeek': dayOfWeek,
                    'startTime': startTimeController.text,
                    'endTime': endTimeController.text,
                  };
                  if (isEditing) {
                    await ApiService.updateTimetableEntry(entry['_id'], body);
                  } else {
                    await ApiService.createTimetableEntry(body);
                  }
                  if (mounted) {
                    Navigator.pop(context);
                    _load();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEntry(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteTimetableEntry(id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final isFaculty = user?.role == 'faculty';
    final canEdit = isFaculty && _useMy; 

    final byDay = _data['byDay'] as Map<String, dynamic>? ?? {};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        actions: [
          IconButton(
            icon: Icon(_useMy ? Icons.person : Icons.list),
            onPressed: () {
              setState(() {
                _useMy = !_useMy;
                _load();
              });
            },
            tooltip: _useMy ? 'My schedule' : 'Full timetable',
          ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () => _showEntryDialog(),
              child: const Icon(Icons.add),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (int d = 0; d <= 6; d++) ...[
                  if ((byDay[d.toString()] ?? byDay[d]) != null && ((byDay[d.toString()] ?? byDay[d]) as List).isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_days[d], style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(height: 8),
                    ...((byDay[d.toString()] ?? byDay[d]) as List<dynamic>? ?? []).map((e) {
                      final entry = e as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(entry['subject'] as String? ?? ''),
                          subtitle: Text('${entry['startTime'] ?? ''} - ${entry['endTime'] ?? ''} • ${entry['room'] ?? ''}'),
                          trailing: canEdit
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _showEntryDialog(entry),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () => _deleteEntry(entry['_id']),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    }),
                  ]
                ],
              ],
            ),
    );
  }
}
