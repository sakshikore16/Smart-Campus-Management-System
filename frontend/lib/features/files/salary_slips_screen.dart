import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class SalarySlipsScreen extends StatefulWidget {
  const SalarySlipsScreen({super.key});

  @override
  State<SalarySlipsScreen> createState() => _SalarySlipsScreenState();
}

class _SalarySlipsScreenState extends State<SalarySlipsScreen> {
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
      final data = await ApiService.getMySalarySlips();
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
      appBar: AppBar(title: const Text('Salary Slips')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const EmptyStateMessage(message: 'No salary slips yet.', icon: Icons.payment)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final s = _list[i] as Map<String, dynamic>;
                      final title = s['title'] as String? ?? 'Salary Slip';
                      final url = s['fileUrl'] as String? ?? '';
                      final createdAt = s['createdAt'] != null ? DateTime.tryParse(s['createdAt'] as String) : null;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.payments),
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
