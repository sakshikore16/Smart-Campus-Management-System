import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class FeeReceiptsScreen extends StatefulWidget {
  const FeeReceiptsScreen({super.key});

  @override
  State<FeeReceiptsScreen> createState() => _FeeReceiptsScreenState();
}

class _FeeReceiptsScreenState extends State<FeeReceiptsScreen> {
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
      final data = await ApiService.getMyFeeReceipts();
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
      appBar: AppBar(title: const Text('Fee Receipts')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const EmptyStateMessage(message: 'No fee receipts yet.', icon: Icons.receipt_long)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final r = _list[i] as Map<String, dynamic>;
                      final title = r['title'] as String? ?? 'Receipt';
                      final url = r['fileUrl'] as String? ?? '';
                      final createdAt = r['createdAt'] != null ? DateTime.tryParse(r['createdAt'] as String) : null;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long),
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
