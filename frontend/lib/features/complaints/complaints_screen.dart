import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
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
      final data = await ApiService.getMyComplaints();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSubmitDialog() {
    final subjectController = TextEditingController();
    final descController = TextEditingController();
    String? attachmentUrl;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Submit Complaint'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: subjectController, decoration: const InputDecoration(labelText: 'Subject')),
                const SizedBox(height: 16),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 4),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: Icon(attachmentUrl != null ? Icons.check_circle : Icons.upload_file),
                  label: Text(attachmentUrl != null ? 'Attachment added' : 'Upload attachment (optional)'),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
                    if (result != null && result.files.single.bytes != null) {
                      try {
                        final url = await ApiService.uploadComplaintAttachment(result.files.single.bytes!, result.files.single.name);
                        if (ctx.mounted) setDialogState(() => attachmentUrl = url);
                      } catch (_) {}
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
                if (subjectController.text.isEmpty || descController.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.submitComplaint(subjectController.text, descController.text, attachmentUrl: attachmentUrl);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint submitted')));
                    _load();
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
      appBar: AppBar(title: const Text('My Complaints'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _showSubmitDialog, tooltip: 'Submit complaint'),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitDialog,
        icon: const Icon(Icons.add),
        label: const Text('Submit complaint'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? EmptyStateWithAction(message: 'No records found', actionLabel: 'Submit complaint', onAction: _showSubmitDialog, icon: Icons.report_problem)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final c = _list[i] as Map<String, dynamic>;
                      final subject = c['subject'] as String? ?? '';
                      final status = c['status'] as String? ?? '';
                      final createdAt = c['createdAt'] != null ? DateTime.tryParse(c['createdAt'] as String) : null;
                      return Card(
                        child: ListTile(
                          title: Text(subject),
                          subtitle: Text('${status}${createdAt != null ? ' • ${DateFormat.yMd().format(createdAt)}' : ''}'),
                          onTap: () => showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(subject),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(c['description'] as String? ?? ''),
                                    if (c['attachmentUrl'] != null && (c['attachmentUrl'] as String).isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      const Text('Attachment:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      InkWell(
                                        onTap: () => launchUrl(Uri.parse(c['attachmentUrl'] as String), mode: LaunchMode.externalApplication),
                                        child: const Text('View attachment', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                      ),
                                    ],
                                    if (c['adminResponse'] != null && (c['adminResponse'] as String).isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      const Text('Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(c['adminResponse'] as String),
                                    ],
                                  ],
                                ),
                              ),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
