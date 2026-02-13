import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class GrievanceReviewScreen extends StatefulWidget {
  const GrievanceReviewScreen({super.key});

  @override
  State<GrievanceReviewScreen> createState() => _GrievanceReviewScreenState();
}

class _GrievanceReviewScreenState extends State<GrievanceReviewScreen> {
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
      final data = await ApiService.getGrievancesForFaculty();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(String id, String status) async {
    try {
      await ApiService.reviewGrievance(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $status')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Correction Requests')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _list.isEmpty ? const EmptyStateMessage(message: 'No pending attendance correction requests.', icon: Icons.gavel) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final g = _list[i] as Map<String, dynamic>;
          final student = g['studentId'] is Map ? g['studentId'] as Map<String, dynamic> : null;
          final subject = g['subject'] as String? ?? '';
          final date = g['date'] != null ? DateTime.tryParse(g['date'] as String) : null;
          final comments = g['comments'] as String? ?? '';
          final id = g['_id'] as String?;
          final proofUrl = g['proofUrl'] as String?;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student: ${student != null ? (student['userId'] is Map ? (student['userId'] as Map)['name'] : '') : ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Subject: $subject'),
                  if (date != null) Text('Date: ${DateFormat.yMd().format(date)}'),
                  if (comments.isNotEmpty) Text('Comments: $comments'),
                  if (proofUrl != null && proofUrl.isNotEmpty)
                    InkWell(
                      onTap: () => launchUrl(Uri.parse(proofUrl!), mode: LaunchMode.externalApplication),
                      child: const Text('View proof / document', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                    ),
                  if (id != null) Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => _review(id, 'Rejected'), child: const Text('Reject')),
                      TextButton(onPressed: () => _review(id, 'Approved'), child: const Text('Approve')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
