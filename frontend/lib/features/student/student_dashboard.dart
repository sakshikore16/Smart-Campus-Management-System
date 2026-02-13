import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _unreadCount = 0;

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final name = TextEditingController(text: auth.user?.name ?? '');
    final rollNo = TextEditingController(text: auth.studentProfile?.rollNo ?? '');
    final department = TextEditingController(text: auth.studentProfile?.department ?? '');
    final course = TextEditingController(text: auth.studentProfile?.course ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
              TextField(controller: rollNo, decoration: const InputDecoration(labelText: 'Roll No *')),
              TextField(controller: department, decoration: const InputDecoration(labelText: 'Department *')),
              TextField(controller: course, decoration: const InputDecoration(labelText: 'Course *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (name.text.trim().isEmpty || rollNo.text.trim().isEmpty || department.text.trim().isEmpty || course.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required')));
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiService.updateMyProfile({
                  'name': name.text.trim(),
                  'rollNo': rollNo.text.trim(),
                  'department': department.text.trim(),
                  'course': course.text.trim(),
                });
                if (mounted) {
                  await auth.fetchMe();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                  setState(() {});
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : '$e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    try {
      final data = await ApiService.getUnreadCount();
      if (mounted) setState(() => _unreadCount = (data['count'] as num?)?.toInt() ?? 0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn || auth.user?.role != 'student') {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final name = auth.user?.name ?? 'Student';
    final profile = auth.studentProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              context.push('/student/notifications');
              _loadUnread();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await auth.fetchMe();
          _loadUnread();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome, $name 👋', style: Theme.of(context).textTheme.titleLarge),
              if (profile != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Profile', style: Theme.of(context).textTheme.titleMedium),
                            TextButton.icon(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit profile'),
                              onPressed: () => _showEditProfileDialog(context, auth),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Roll No: ${profile.rollNo}'),
                        Text('Department: ${profile.department}'),
                        Text('Course: ${profile.course}'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DashboardCard(
                    icon: Icons.calendar_today,
                    title: 'Attendance',
                    onTap: () => context.push('/student/attendance'),
                  ),
                  _DashboardCard(
                    icon: Icons.gavel,
                    title: 'Attendance Grievance',
                    onTap: () => context.push('/student/attendance-grievance'),
                  ),
                  _DashboardCard(
                    icon: Icons.payment,
                    title: 'Pay Fees',
                    onTap: () => context.push('/student/fee-payment'),
                  ),
                  _DashboardCard(
                    icon: Icons.receipt_long,
                    title: 'Fee Receipt',
                    onTap: () => context.push('/student/fee-receipts'),
                  ),
                  _DashboardCard(
                    icon: Icons.request_page,
                    title: 'Fee Receipt Request',
                    onTap: () => context.push('/student/fee-receipt-request'),
                  ),
                  _DashboardCard(
                    icon: Icons.grade,
                    title: 'Marks',
                    onTap: () => context.push('/student/marks'),
                  ),
                  _DashboardCard(
                    icon: Icons.event_busy,
                    title: 'Apply Leave',
                    onTap: () => context.push('/student/leaves'),
                  ),
                  _DashboardCard(
                    icon: Icons.badge,
                    title: 'Upload Certificate',
                    onTap: () => context.push('/student/certificates'),
                  ),
                  _DashboardCard(
                    icon: Icons.schedule,
                    title: 'Timetable',
                    onTap: () => context.push('/student/timetable'),
                  ),
                  _DashboardCard(
                    icon: Icons.campaign,
                    title: 'Notices',
                    onTap: () => context.push('/student/notices'),
                  ),
                  _DashboardCard(
                    icon: Icons.report_problem,
                    title: 'Complaints',
                    onTap: () => context.push('/student/complaints'),
                  ),
                  // _DashboardCard(
                  //   icon: Icons.notifications,
                  //   title: 'Notifications',
                  //   onTap: () {
                  //     context.push('/student/notifications');
                  //     _loadUnread();
                  //   },
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardCard({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: SizedBox(
          width: 140,
          height: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppTheme.primary),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
