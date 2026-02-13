import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class AttendanceGrievanceScreen extends StatefulWidget {
  const AttendanceGrievanceScreen({super.key});

  @override
  State<AttendanceGrievanceScreen> createState() => _AttendanceGrievanceScreenState();
}

class _AttendanceGrievanceScreenState extends State<AttendanceGrievanceScreen> {
  List<dynamic> _list = [];
  List<dynamic> _faculty = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getMyGrievances();
      final faculty = await ApiService.getFacultyList();
      if (mounted) setState(() {
        _list = data;
        _faculty = faculty;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateDialog() {
    String? facultyId;
    final subjectController = TextEditingController();
    DateTime? date;
    final commentsController = TextEditingController();
    List<int>? proofBytes;
    String? proofName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Attendance Correction Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: facultyId,
                  decoration: const InputDecoration(labelText: 'Concerned Faculty *'),
                  items: _faculty.map((f) {
                    final map = f as Map<String, dynamic>;
                    final id = map['_id'] as String?;
                    final user = map['userId'] is Map ? map['userId'] as Map<String, dynamic> : null;
                    final name = user?['name'] ?? 'Faculty';
                    return DropdownMenuItem(value: id, child: Text(name));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => facultyId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject *')),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(date == null ? 'Select Date *' : DateFormat.yMd().format(date!)),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now());
                    if (d != null) setDialogState(() => date = d);
                  },
                ),
                TextField(controller: commentsController, decoration: const InputDecoration(labelText: 'Comments'), maxLines: 2),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: Text(proofName ?? 'Upload proof (optional)'),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
                    if (result != null && result.files.single.bytes != null) {
                      setDialogState(() {
                        proofBytes = result.files.single.bytes;
                        proofName = result.files.single.name;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (facultyId == null || subjectController.text.trim().isEmpty || date == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill faculty, subject and date')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  final dateStr = date!.toIso8601String().split('T')[0];
                  if (proofBytes != null && proofName != null) {
                    await ApiService.createGrievance(facultyId!, subjectController.text.trim(), dateStr, comments: commentsController.text.trim(), proofFileBytes: proofBytes, proofFileName: proofName);
                  } else {
                    await ApiService.createGrievance(facultyId!, subjectController.text.trim(), dateStr, comments: commentsController.text.trim());
                  }
                  if (mounted) {
                    await _load();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted')));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Grievance'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showCreateDialog)]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Raise grievance'),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty ? EmptyStateWithAction(message: 'No records found', actionLabel: 'Raise grievance', onAction: _showCreateDialog, icon: Icons.gavel) : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _list.length,
          itemBuilder: (_, i) {
            final g = _list[i] as Map<String, dynamic>;
            final subject = g['subject'] as String? ?? '';
            final status = g['status'] as String? ?? 'Pending';
            final date = g['date'] != null ? DateTime.tryParse(g['date'] as String) : null;
            final createdAt = g['createdAt'] != null ? DateTime.tryParse(g['createdAt'] as String) : null;
            final hasProof = g['proofUrl'] != null && (g['proofUrl'] as String).isNotEmpty;
            return Card(
              child: ListTile(
                title: Text(subject),
                subtitle: Text('${date != null ? DateFormat.yMd().format(date) : ''} • $status${hasProof ? ' • Proof attached' : ''}${createdAt != null ? '\n${DateFormat.yMd().format(createdAt)}' : ''}'),
                isThreeLine: true,
              ),
            );
          },
        ),
      ),
    );
  }
}
