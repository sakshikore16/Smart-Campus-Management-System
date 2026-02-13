import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
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
      final data = await ApiService.getNotices();
      if (mounted) setState(() {
        _list = List<dynamic>.from(data);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices & Events')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? const EmptyStateMessage(message: 'No notices or events yet.', icon: Icons.campaign)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final n = _list[i] as Map<String, dynamic>;
                      final title = n['title'] as String? ?? '';
                      final content = n['content'] as String? ?? '';
                      final type = n['type'] as String? ?? 'notice';
                      final createdAt = n['createdAt'] != null ? DateTime.tryParse(n['createdAt'] as String) : null;
                      return Card(
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text('${type}\n${content.length > 80 ? '${content.substring(0, 80)}...' : content}${createdAt != null ? '\n${DateFormat.yMd().format(createdAt)}' : ''}'),
                          isThreeLine: true,
                          onTap: () => showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(title),
                              content: SingleChildScrollView(child: Text(content)),
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
