import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
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
      final data = await ApiService.getAttendanceAdmin();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Attendance')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const EmptyStateMessage(message: 'No attendance records.', icon: Icons.calendar_today)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final a = _list[i] as Map<String, dynamic>;
                      final student = a['studentId'] is Map ? a['studentId'] as Map<String, dynamic> : null;
                      final subject = a['subject'] as String? ?? '';
                      final date = a['date'] != null ? DateTime.tryParse(a['date'] as String) : null;
                      final status = a['status'] as String? ?? '';
                      final name = student != null ? (student['userId'] is Map ? (student['userId'] as Map)['name'] : null) : null;
                      return Card(
                        child: ListTile(
                          title: Text('$subject • ${name ?? 'Student'}'),
                          subtitle: date != null ? Text(DateFormat.yMd().format(date)) : null,
                          trailing: Chip(
                            label: Text(status),
                            backgroundColor: status == 'Present' ? Colors.green.shade100 : Colors.red.shade100,
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
