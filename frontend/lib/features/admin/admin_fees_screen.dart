import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class AdminFeesScreen extends StatefulWidget {
  const AdminFeesScreen({super.key});

  @override
  State<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends State<AdminFeesScreen> {
  List<dynamic> _students = [];
  List<dynamic> _faculty = [];
  List<dynamic> _feeReceipts = [];
  List<dynamic> _salarySlips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final students = await ApiService.getStudents();
      final faculty = await ApiService.getFaculty();
      final receipts = await ApiService.getFeeReceiptsAdmin();
      final slips = await ApiService.getSalarySlipsAdmin();
      if (mounted) setState(() {
        _students = students;
        _faculty = faculty;
        _feeReceipts = receipts;
        _salarySlips = slips;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadFeeReceipt(String studentId) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null || result.files.single.bytes == null) return;
    final file = result.files.single;
    try {
      await ApiService.uploadFeeReceipt(studentId, file.bytes!, file.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee receipt uploaded')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _uploadSalarySlip(String facultyId) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null || result.files.single.bytes == null) return;
    final file = result.files.single;
    try {
      await ApiService.uploadSalarySlip(facultyId, file.bytes!, file.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salary slip uploaded')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fees & Salaries')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Upload Fee'),
                      Tab(text: 'Upload Salary'),
                      Tab(text: 'Fee Receipts'),
                      Tab(text: 'Salary Slips'),
                    ],
                    isScrollable: true,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          itemBuilder: (_, i) {
                            final s = _students[i] as Map<String, dynamic>;
                            final user = s['userId'] is Map ? s['userId'] as Map<String, dynamic> : null;
                            final name = user?['name'] ?? '';
                            final rollNo = s['rollNo'] ?? '';
                            final id = s['_id'] as String?;
                            return Card(
                              child: ListTile(
                                title: Text('$name ($rollNo)'),
                                trailing: id != null ? ElevatedButton(onPressed: () => _uploadFeeReceipt(id), child: const Text('Upload')) : null,
                              ),
                            );
                          },
                        ),
                        ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _faculty.length,
                          itemBuilder: (_, i) {
                            final f = _faculty[i] as Map<String, dynamic>;
                            final user = f['userId'] is Map ? f['userId'] as Map<String, dynamic> : null;
                            final name = user?['name'] ?? '';
                            final id = f['_id'] as String?;
                            return Card(
                              child: ListTile(
                                title: Text(name),
                                trailing: id != null ? ElevatedButton(onPressed: () => _uploadSalarySlip(id), child: const Text('Upload')) : null,
                              ),
                            );
                          },
                        ),
                        _feeReceipts.isEmpty
                            ? const EmptyStateMessage(message: 'No fee receipts.', icon: Icons.receipt_long)
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _feeReceipts.length,
                                itemBuilder: (_, i) {
                                  final r = _feeReceipts[i] as Map<String, dynamic>;
                                  final title = r['title'] as String? ?? '';
                                  final url = r['fileUrl'] as String? ?? '';
                                  final createdAt = r['createdAt'] != null ? DateTime.tryParse(r['createdAt'] as String) : null;
                                  return Card(
                                    child: ListTile(
                                      title: Text(title),
                                      subtitle: createdAt != null ? Text(DateFormat.yMd().format(createdAt)) : null,
                                      trailing: IconButton(icon: const Icon(Icons.download), onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)),
                                    ),
                                  );
                                },
                              ),
                        _salarySlips.isEmpty
                            ? const EmptyStateMessage(message: 'No salary slips.', icon: Icons.payment)
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _salarySlips.length,
                                itemBuilder: (_, i) {
                                  final s = _salarySlips[i] as Map<String, dynamic>;
                                  final title = s['title'] as String? ?? '';
                                  final url = s['fileUrl'] as String? ?? '';
                                  final createdAt = s['createdAt'] != null ? DateTime.tryParse(s['createdAt'] as String) : null;
                                  return Card(
                                    child: ListTile(
                                      title: Text(title),
                                      subtitle: createdAt != null ? Text(DateFormat.yMd().format(createdAt)) : null,
                                      trailing: IconButton(icon: const Icon(Icons.download), onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
