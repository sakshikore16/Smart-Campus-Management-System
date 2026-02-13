import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<dynamic> _students = [];
  String _subject = '';
  DateTime _date = DateTime.now();
  final Map<String, String> _status = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAttendanceStudents();
      if (mounted) setState(() {
        _students = data;
        _loading = false;
        final auth = context.read<AuthProvider>();
        final subs = auth.facultyProfile?.subjects ?? [];
        if (_subject.isEmpty && subs.isNotEmpty) _subject = subs.first;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select subject')));
      return;
    }
    setState(() => _saving = true);
    try {
      final dateStr = '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
      final entries = _students.map((s) {
        final id = (s as Map<String, dynamic>)['_id'] as String?;
        return {'studentId': id, 'status': _status[id] ?? 'Present'};
      }).toList();
      await ApiService.bulkMarkAttendance(_subject, dateStr, entries);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance saved')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final subjects = auth.facultyProfile?.subjects ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (subjects.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _subject.isEmpty ? null : _subject,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _subject = v ?? ''),
                    )
                  else
                    TextField(
                      onChanged: (v) => setState(() => _subject = v),
                      decoration: const InputDecoration(labelText: 'Subject'),
                    ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('Date: ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                    trailing: TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 30)));
                        if (d != null) setState(() => _date = d);
                      },
                      child: const Text('Change'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._students.map((s) {
                    final map = s as Map<String, dynamic>;
                    final id = map['_id'] as String?;
                    final user = map['userId'] is Map ? map['userId'] as Map<String, dynamic> : null;
                    final name = user?['name'] ?? map['rollNo'] ?? 'Student';
                    final rollNo = map['rollNo'] ?? '';
                    final current = _status[id] ?? 'Present';
                    return Card(
                      child: ListTile(
                        title: Text('$name ($rollNo)'),
                        trailing: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Present', label: Text('P')),
                            ButtonSegment(value: 'Absent', label: Text('A')),
                          ],
                          selected: {current},
                          onSelectionChanged: (v) => setState(() => _status[id ?? ''] = v.first),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Attendance'),
                  ),
                ],
              ),
            ),
    );
  }
}
