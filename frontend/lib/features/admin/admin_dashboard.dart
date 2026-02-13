import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  bool _wasCurrent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getDashboardStats();
      if (mounted) setState(() {
        _stats = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (isCurrent && !_wasCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _wasCurrent = true);
          _load();
        }
      });
    } else if (!isCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _wasCurrent = false);
      });
    }
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn || auth.user?.role != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/admin-login'));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/admin/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              context.go('/admin-login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Panel', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(title: 'Students', value: '${_stats['students'] ?? 0}', icon: Icons.people),
                    _StatCard(title: 'Faculty', value: '${_stats['faculty'] ?? 0}', icon: Icons.school),
                    _StatCard(title: 'Pending Leaves', value: '${_stats['pendingLeaves'] ?? 0}', icon: Icons.pending_actions),
                    _StatCard(title: 'Total Expenses', value: '₹${_stats['totalExpenses'] ?? 0}', icon: Icons.attach_money),
                  ],
                ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DashboardCard(icon: Icons.people, title: 'Manage Students', onTap: () => context.push('/admin/students')),
                  _DashboardCard(icon: Icons.school, title: 'Manage Faculty', onTap: () => context.push('/admin/faculty')),
                  _DashboardCard(icon: Icons.admin_panel_settings, title: 'Manage Admins', onTap: () => context.push('/admin/admins')),
                  _DashboardCard(icon: Icons.how_to_reg, title: 'Attendance', onTap: () => context.push('/admin/attendance')),
                  _DashboardCard(icon: Icons.campaign, title: 'Notices', onTap: () => context.push('/admin/notices')),
                  _DashboardCard(icon: Icons.pending_actions, title: 'Leaves', onTap: () => context.push('/admin/leaves')),
                  _DashboardCard(icon: Icons.people_outline, title: 'Faculty Leaves', onTap: () => context.push('/admin/faculty-leaves')),
                  _DashboardCard(icon: Icons.payments, title: 'Fees & Salaries', onTap: () => context.push('/admin/fees')),
                  _DashboardCard(icon: Icons.payment, title: 'Fee Payments', onTap: () => context.push('/admin/fee-payments')),
                  _DashboardCard(icon: Icons.request_page, title: 'Fee Receipt Requests', onTap: () => context.push('/admin/fee-receipt-requests')),
                  _DashboardCard(icon: Icons.receipt, title: 'Expenses', onTap: () => context.push('/admin/expenses')),
                  _DashboardCard(icon: Icons.account_balance_wallet, title: 'Budgets', onTap: () => context.push('/admin/budgets')),
                  _DashboardCard(icon: Icons.badge, title: 'ID Card Requests', onTap: () => context.push('/admin/id-card-requests')),
                  _DashboardCard(icon: Icons.report_problem, title: 'Complaints', onTap: () => context.push('/admin/complaints')),
                  _DashboardCard(icon: Icons.notifications_active, title: 'Send Notification', onTap: () => context.push('/admin/send-notification')),
                  // _DashboardCard(icon: Icons.notifications, title: 'Notifications', onTap: () => context.push('/admin/notifications')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppTheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ],
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
