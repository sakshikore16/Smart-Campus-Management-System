import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class IdCardRequestScreen extends StatefulWidget {
  const IdCardRequestScreen({super.key});

  @override
  State<IdCardRequestScreen> createState() => _IdCardRequestScreenState();
}

class _IdCardRequestScreenState extends State<IdCardRequestScreen> {
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
      final data = await ApiService.getMyIdCardRequests();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showRequestDialog() {
    String issueType = 'lost';
    final descController = TextEditingController();
    String? attachmentUrl;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Request ID / Access Card'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: issueType,
                  decoration: const InputDecoration(labelText: 'Issue type'),
                  items: const [
                    DropdownMenuItem(value: 'lost', child: Text('Lost')),
                    DropdownMenuItem(value: 'cut', child: Text('Cut')),
                    DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                  ],
                  onChanged: (v) => setDialogState(() => issueType = v ?? 'lost'),
                ),
                const SizedBox(height: 12),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: Icon(attachmentUrl != null ? Icons.check_circle : Icons.upload_file),
                  label: Text(attachmentUrl != null ? 'Attachment added' : 'Upload proof/attachment (optional)'),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
                    if (result != null && result.files.single.bytes != null) {
                      try {
                        final url = await ApiService.uploadIdCardAttachment(result.files.single.bytes!, result.files.single.name);
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
                Navigator.pop(ctx);
                try {
                  await ApiService.createIdCardRequest(issueType, description: descController.text.trim(), attachmentUrl: attachmentUrl);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted')));
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
      appBar: AppBar(title: const Text('ID Card Request'), actions: [IconButton(icon: const Icon(Icons.add), onPressed: _showRequestDialog)]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestDialog,
        icon: const Icon(Icons.add),
        label: const Text('Request ID card'),
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty ? EmptyStateWithAction(message: 'No records found', actionLabel: 'Request ID card', onAction: _showRequestDialog, icon: Icons.badge) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final r = _list[i] as Map<String, dynamic>;
          final issueType = r['issueType'] as String? ?? '';
          final status = r['status'] as String? ?? '';
          final createdAt = r['createdAt'] != null ? DateTime.tryParse(r['createdAt'] as String) : null;
          return Card(
            child: ListTile(
              title: Text(issueType),
              subtitle: Text('$status${createdAt != null ? ' • ${DateFormat.yMd().format(createdAt)}' : ''}'),
              trailing: Chip(label: Text(status)),
            ),
          );
        },
      ),
    );
  }
}
