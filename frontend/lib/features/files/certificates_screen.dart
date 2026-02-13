import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
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
      final data = await ApiService.getMyCertificates();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null || result.files.single.bytes == null) return;
    final file = result.files.single;
    try {
      await ApiService.uploadCertificate(file.bytes!, file.name, title: file.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Certificate uploaded')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Certificates'), actions: [
        IconButton(icon: const Icon(Icons.upload_file), onPressed: _pickAndUpload, tooltip: 'Upload'),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUpload,
        icon: const Icon(Icons.add),
        label: const Text('Upload certificate'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? EmptyStateWithAction(message: 'No certificates uploaded', actionLabel: 'Upload certificate', onAction: _pickAndUpload, icon: Icons.badge)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final c = _list[i] as Map<String, dynamic>;
                      final title = c['title'] as String? ?? 'Certificate';
                      final url = c['fileUrl'] as String? ?? '';
                      final createdAt = c['createdAt'] != null ? DateTime.tryParse(c['createdAt'] as String) : null;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.badge),
                          title: Text(title),
                          subtitle: createdAt != null ? Text(DateFormat.yMd().format(createdAt)) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () {
                              if (url.isNotEmpty) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
