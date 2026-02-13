import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
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
      final data = await ApiService.getMyLeaves();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showApplyDialog() {
    final reasonController = TextEditingController();
    DateTime? fromDate;
    DateTime? toDate;
    String? medicalCertUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Apply for Leave'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(fromDate == null ? 'From Date' : DateFormat.yMd().format(fromDate!)),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (d != null) setDialogState(() => fromDate = d);
                  },
                ),
                ListTile(
                  title: Text(toDate == null ? 'To Date' : DateFormat.yMd().format(toDate!)),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: toDate ?? DateTime.now(), firstDate: fromDate ?? DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (d != null) setDialogState(() => toDate = d);
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: Icon(medicalCertUrl != null ? Icons.check_circle : Icons.upload_file),
                  label: Text(medicalCertUrl != null ? 'Medical certificate attached' : 'Upload medical certificate (optional)'),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
                    if (result != null && result.files.single.bytes != null) {
                      try {
                        final url = await ApiService.uploadLeaveMedicalCert(result.files.single.bytes!, result.files.single.name);
                        if (ctx.mounted) setDialogState(() => medicalCertUrl = url);
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
                if (reasonController.text.isEmpty || fromDate == null || toDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields')));
                  return;
                }
                Navigator.pop(ctx);
                try {
                  final from = fromDate!;
                  final to = toDate!;
                  await ApiService.applyLeave(
                    reasonController.text,
                    from.toIso8601String().split('T')[0],
                    to.toIso8601String().split('T')[0],
                    medicalCertificateUrl: medicalCertUrl,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave applied')));
                    _load();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Leaves'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _showApplyDialog, tooltip: 'Apply Leave'),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplyDialog,
        icon: const Icon(Icons.add),
        label: const Text('Apply for leave'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? EmptyStateWithAction(message: 'No records found', actionLabel: 'Apply for leave', onAction: _showApplyDialog, icon: Icons.event_busy)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final l = _list[i] as Map<String, dynamic>;
                      final reason = l['reason'] as String? ?? '';
                      final status = l['status'] as String? ?? '';
                      final from = l['fromDate'] != null ? DateTime.tryParse(l['fromDate'] as String) : null;
                      final to = l['toDate'] != null ? DateTime.tryParse(l['toDate'] as String) : null;
                      Color statusColor = Colors.orange;
                      if (status == 'Approved') statusColor = Colors.green;
                      if (status == 'Rejected') statusColor = Colors.red;
                      return Card(
                        child: ListTile(
                          title: Text(reason),
                          subtitle: Text('${from != null ? DateFormat.yMd().format(from) : ''} - ${to != null ? DateFormat.yMd().format(to) : ''}'),
                          trailing: Chip(label: Text(status), backgroundColor: statusColor.withValues(alpha: 0.2)),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
