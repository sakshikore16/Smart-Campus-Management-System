import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class UploadMarksScreen extends StatefulWidget {
  const UploadMarksScreen({super.key});

  @override
  State<UploadMarksScreen> createState() => _UploadMarksScreenState();
}

class _UploadMarksScreenState extends State<UploadMarksScreen> {
  List<dynamic> _students = [];
  bool _loading = true;
  String? _studentId;
  final _subjectController = TextEditingController();
  final _marksController = TextEditingController();
  final _examTypeController = TextEditingController();
  final _maxMarksController = TextEditingController(text: '100');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _marksController.dispose();
    _examTypeController.dispose();
    _maxMarksController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getStudentsList();
      if (mounted) setState(() {
        _students = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_studentId == null || _subjectController.text.trim().isEmpty || _marksController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select student, subject and marks')));
      return;
    }
    final marks = num.tryParse(_marksController.text);
    if (marks == null) return;
    final maxMarks = num.tryParse(_maxMarksController.text);
    try {
      await ApiService.uploadMarks(
        _studentId!,
        _subjectController.text.trim(),
        marks,
        examType: _examTypeController.text.trim().isEmpty ? null : _examTypeController.text.trim(),
        maxMarks: maxMarks,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks uploaded')));
        _marksController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Marks')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  value: _studentId,
                  decoration: const InputDecoration(labelText: 'Student *'),
                  items: _students.map((s) {
                    final map = s as Map<String, dynamic>;
                    final id = map['_id'] as String?;
                    final user = map['userId'] is Map ? map['userId'] as Map<String, dynamic> : null;
                    final rollNo = map['rollNo'] ?? '';
                    final name = user?['name'] ?? rollNo;
                    return DropdownMenuItem(value: id, child: Text('$name ($rollNo)'));
                  }).toList(),
                  onChanged: (v) => setState(() => _studentId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: _subjectController, decoration: const InputDecoration(labelText: 'Subject *')),
                const SizedBox(height: 12),
                TextField(controller: _examTypeController, decoration: const InputDecoration(labelText: 'Exam type (e.g. Mid-term)')),
                const SizedBox(height: 12),
                TextField(controller: _marksController, decoration: const InputDecoration(labelText: 'Marks *'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                TextField(controller: _maxMarksController, decoration: const InputDecoration(labelText: 'Max marks'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _submit, child: const Text('Upload Marks')),
              ],
            ),
    );
  }
}
