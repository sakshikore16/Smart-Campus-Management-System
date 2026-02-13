import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
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
      final data = await ApiService.getMyAttendance();
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
      appBar: AppBar(title: const Text('My Attendance')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const EmptyStateMessage(message: 'No attendance records yet.', icon: Icons.calendar_today)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final a = _list[i] as Map<String, dynamic>;
                      final subject = a['subject'] as String? ?? '';
                      final date = a['date'] != null ? DateTime.tryParse(a['date'] as String) : null;
                      final status = a['status'] as String? ?? '';
                      return Card(
                        child: ListTile(
                          title: Text(subject),
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
