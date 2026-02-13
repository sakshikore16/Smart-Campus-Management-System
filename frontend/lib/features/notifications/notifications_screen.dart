import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
      final data = await ApiService.getNotifications();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
      await ApiService.markAllNotificationsRead();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), actions: [
        IconButton(icon: const Icon(Icons.done_all), onPressed: _load, tooltip: 'Mark all read'),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const EmptyStateMessage(message: 'No notifications yet.', icon: Icons.notifications_none)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _list.length,
                  itemBuilder: (_, i) {
                    final n = _list[i] as Map<String, dynamic>;
                    final msg = n['message'] as String? ?? '';
                    final read = n['isRead'] as bool? ?? false;
                    final createdAt = n['createdAt'] != null ? DateTime.tryParse(n['createdAt'] as String) : null;
                    return Card(
                      color: read ? null : AppTheme.secondary.withValues(alpha: 0.3),
                      child: ListTile(
                        title: Text(msg),
                        subtitle: createdAt != null ? Text(DateFormat.yMd().add_Hm().format(createdAt)) : null,
                      ),
                    );
                  },
                ),
    );
  }
}
