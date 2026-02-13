import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class AdminSendNotificationScreen extends StatefulWidget {
  const AdminSendNotificationScreen({super.key});

  @override
  State<AdminSendNotificationScreen> createState() => _AdminSendNotificationScreenState();
}

class _AdminSendNotificationScreenState extends State<AdminSendNotificationScreen> {
  final _messageController = TextEditingController();
  String _target = 'all';
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter message')));
      return;
    }
    setState(() => _sending = true);
    try {
      switch (_target) {
        case 'all':
          await ApiService.sendNotificationToAll(msg);
          break;
        case 'students':
          await ApiService.sendNotificationToStudents(msg);
          break;
        case 'faculty':
          await ApiService.sendNotificationToFaculty(msg);
          break;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent')));
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Notification')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Target audience'),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'all', label: Text('All')),
                ButtonSegment(value: 'students', label: Text('Students')),
                ButtonSegment(value: 'faculty', label: Text('Faculty')),
              ],
              selected: {_target},
              onSelectionChanged: (s) => setState(() => _target = s.first),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Message', alignLabelWithHint: true),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _sending ? null : _send,
              child: _sending ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
