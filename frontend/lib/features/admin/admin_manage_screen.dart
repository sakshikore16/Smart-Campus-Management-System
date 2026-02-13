import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

/// Only existing admins can add other admins (no public registration).

/// Extracts the Admin document _id (not the user id). Handles string or Map with $oid.
String? _adminIdFromMap(Map<String, dynamic> a) {
  final id = a['_id'];
  if (id == null) return null;
  if (id is String) return id.trim().isEmpty ? null : id;
  if (id is Map) {
    final oid = id['\$oid'] ?? id['oid'];
    if (oid is String) return oid.trim().isEmpty ? null : oid;
  }
  return id.toString().trim().isEmpty ? null : id.toString();
}

class AdminManageScreen extends StatefulWidget {
  const AdminManageScreen({super.key});

  @override
  State<AdminManageScreen> createState() => _AdminManageScreenState();
}

class _AdminManageScreenState extends State<AdminManageScreen> {
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
      final data = await ApiService.getAdmins();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddDialog() {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final employeeId = TextEditingController();
    final position = TextEditingController();
    final department = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email *'), keyboardType: TextInputType.emailAddress),
              TextField(controller: password, decoration: const InputDecoration(labelText: 'Password (min 6) *'), obscureText: true),
              TextField(controller: employeeId, decoration: const InputDecoration(labelText: 'Employee ID *')),
              TextField(controller: position, decoration: const InputDecoration(labelText: 'Position')),
              TextField(controller: department, decoration: const InputDecoration(labelText: 'Department *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (name.text.trim().isEmpty ||
                  email.text.trim().isEmpty ||
                  password.text.length < 6 ||
                  employeeId.text.trim().isEmpty ||
                  department.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name, email, password (min 6), employee ID, and department are required')),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiService.addAdmin({
                  'name': name.text.trim(),
                  'email': email.text.trim(),
                  'password': password.text,
                  'employeeId': employeeId.text.trim(),
                  'position': position.text.trim(),
                  'department': department.text.trim(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin added')));
                  _load();
                }
              } catch (e) {
                if (mounted) {
                  final msg = e is ApiException ? e.message : '$e';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> a) {
    final user = a['userId'] is Map ? a['userId'] as Map<String, dynamic> : null;
    final name = TextEditingController(text: user?['name']?.toString() ?? '');
    final email = TextEditingController(text: user?['email']?.toString() ?? '');
    final password = TextEditingController(); // optional: leave blank to keep current
    final employeeId = TextEditingController(text: (a['employeeId'] ?? '').toString());
    final position = TextEditingController(text: (a['position'] ?? '').toString());
    final department = TextEditingController(text: (a['department'] ?? '').toString());
    final adminId = _adminIdFromMap(a);
    if (adminId == null || adminId.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email *'), keyboardType: TextInputType.emailAddress),
              TextField(controller: password, decoration: const InputDecoration(labelText: 'New password (leave blank to keep current)'), obscureText: true),
              TextField(controller: employeeId, decoration: const InputDecoration(labelText: 'Employee ID *')),
              TextField(controller: position, decoration: const InputDecoration(labelText: 'Position')),
              TextField(controller: department, decoration: const InputDecoration(labelText: 'Department *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (name.text.trim().isEmpty || email.text.trim().isEmpty || employeeId.text.trim().isEmpty || department.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name, email, employee ID, and department are required')));
                return;
              }
              if (password.text.isNotEmpty && password.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
                return;
              }
              Navigator.pop(ctx);
              try {
                final body = <String, dynamic>{
                  'name': name.text.trim(),
                  'email': email.text.trim(),
                  'employeeId': employeeId.text.trim(),
                  'position': position.text.trim(),
                  'department': department.text.trim(),
                };
                if (password.text.isNotEmpty) body['password'] = password.text;
                await ApiService.updateAdmin(adminId, body);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin updated')));
                  _load();
                }
              } catch (e) {
                if (mounted) {
                  final msg = e is ApiException ? e.message : '$e';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> a) async {
    final user = a['userId'] is Map ? a['userId'] as Map<String, dynamic> : null;
    final name = user?['name'] ?? 'Admin';
    final adminId = _adminIdFromMap(a);
    if (adminId == null || adminId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text('Remove admin "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.deleteAdmin(adminId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin deleted')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : '$e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Admins'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin')),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add admin'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? EmptyStateWithAction(
                    message: 'No admins yet. Add the first admin from here.',
                    actionLabel: 'Add admin',
                    onAction: _showAddDialog,
                    icon: Icons.admin_panel_settings,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final a = _list[i] as Map<String, dynamic>;
                      final user = a['userId'] is Map ? a['userId'] as Map<String, dynamic> : null;
                      final name = user?['name'] ?? '';
                      final email = user?['email'] ?? '';
                      final empId = a['employeeId'] ?? '';
                      final dept = a['department'] ?? '';
                      final pos = a['position'] ?? '';
                      final adminId = _adminIdFromMap(a);
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings)),
                          title: Text(name),
                          subtitle: Text('$email\n$empId · ${dept.isNotEmpty ? dept : ''}${pos.toString().isNotEmpty ? ' · $pos' : ''}'),
                          isThreeLine: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          trailing: SizedBox(
                            width: 88,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit admin',
                                onPressed: adminId == null ? null : () => _showEditDialog(a),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete admin',
                                onPressed: adminId == null ? null : () => _confirmDelete(a),
                              ),
                            ],
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
