import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key});

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
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
      final data = await ApiService.getMyMarks();
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
      appBar: AppBar(title: const Text('My Marks')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty ? const EmptyStateMessage(message: 'No marks uploaded yet.', icon: Icons.assignment) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final m = _list[i] as Map<String, dynamic>;
          final subject = m['subject'] as String? ?? '';
          final marks = (m['marks'] as num?)?.toDouble() ?? 0;
          final maxMarks = (m['maxMarks'] as num?)?.toDouble() ?? 100;
          final examType = m['examType'] as String? ?? '';
          final createdAt = m['createdAt'] != null ? DateTime.tryParse(m['createdAt'] as String) : null;
          return Card(
            child: ListTile(
              title: Text('$subject${examType.isNotEmpty ? ' ($examType)' : ''}'),
              subtitle: createdAt != null ? Text(DateFormat.yMd().format(createdAt)) : null,
              trailing: Text('$marks / $maxMarks', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}
