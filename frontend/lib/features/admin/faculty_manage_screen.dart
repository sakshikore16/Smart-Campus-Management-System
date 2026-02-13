import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class FacultyManageScreen extends StatefulWidget {
  const FacultyManageScreen({super.key});

  @override
  State<FacultyManageScreen> createState() => _FacultyManageScreenState();
}

class _FacultyManageScreenState extends State<FacultyManageScreen> {
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
      final data = await ApiService.getFaculty();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _facultyIdFromMap(Map<String, dynamic> f) {
    final id = f['_id'];
    if (id == null) return null;
    if (id is String) return id.trim().isEmpty ? null : id;
    if (id is Map) {
      final oid = id['\$oid'] ?? id['oid'];
      if (oid is String) return oid.trim().isEmpty ? null : oid;
    }
    return id.toString().trim().isEmpty ? null : id.toString();
  }

  void _showEditDialog(Map<String, dynamic> f) {
    final user = f['userId'] is Map ? f['userId'] as Map<String, dynamic> : null;
    final name = TextEditingController(text: user?['name']?.toString() ?? '');
    final employeeId = TextEditingController(text: (f['employeeId'] ?? '').toString());
    final department = TextEditingController(text: (f['department'] ?? '').toString());
    final subjects = TextEditingController(
      text: f['subjects'] is List ? (f['subjects'] as List).join(', ') : (f['subjects'] ?? '').toString(),
    );
    final id = _facultyIdFromMap(f);
    if (id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Faculty'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
              TextField(controller: employeeId, decoration: const InputDecoration(labelText: 'Employee ID')),
              TextField(controller: department, decoration: const InputDecoration(labelText: 'Department')),
              TextField(controller: subjects, decoration: const InputDecoration(labelText: 'Subjects (comma separated)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                return;
              }
              Navigator.pop(ctx);
              try {
                final subjList = subjects.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                await ApiService.updateFaculty(id, {
                  'name': name.text.trim(),
                  'employeeId': employeeId.text.trim(),
                  'department': department.text.trim(),
                  'subjects': subjList,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faculty updated')));
                  _load();
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

  void _showAddDialog() {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final subjects = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Faculty'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              TextField(controller: password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              TextField(controller: subjects, decoration: const InputDecoration(labelText: 'Subjects (comma separated)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (name.text.isEmpty || email.text.isEmpty || password.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name, email, password (min 6) required')));
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiService.addFaculty({
                  'name': name.text,
                  'email': email.text,
                  'password': password.text,
                  'subjects': subjects.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faculty added')));
                  _load();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Faculty'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add faculty'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? EmptyStateWithAction(message: 'No records found', actionLabel: 'Add faculty', onAction: _showAddDialog, icon: Icons.person_add)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final f = _list[i] as Map<String, dynamic>;
                      final user = f['userId'] is Map ? f['userId'] as Map<String, dynamic> : null;
                      final name = user?['name'] ?? '';
                      final email = user?['email'] ?? '';
                      final subj = f['subjects'] is List ? (f['subjects'] as List).join(', ') : '';
                      final id = _facultyIdFromMap(f);
                      return Card(
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text('$email\n$subj'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                                onPressed: id == null ? null : () => _showEditDialog(f),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: id == null ? null : () async {
                              if (await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete faculty?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes'))])) != true) return;
                              try {
                                await ApiService.deleteFaculty(id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
                                  _load();
                                }
                              } catch (e) {
                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                              }
                            },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
