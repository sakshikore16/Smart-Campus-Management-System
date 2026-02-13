import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/empty_state_with_action.dart';

class StudentsManageScreen extends StatefulWidget {
  const StudentsManageScreen({super.key});

  @override
  State<StudentsManageScreen> createState() => _StudentsManageScreenState();
}

class _StudentsManageScreenState extends State<StudentsManageScreen> {
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
      final data = await ApiService.getStudents();
      if (mounted) setState(() {
        _list = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _studentIdFromMap(Map<String, dynamic> s) {
    final id = s['_id'];
    if (id == null) return null;
    if (id is String) return id.trim().isEmpty ? null : id;
    if (id is Map) {
      final oid = id['\$oid'] ?? id['oid'];
      if (oid is String) return oid.trim().isEmpty ? null : oid;
    }
    return id.toString().trim().isEmpty ? null : id.toString();
  }

  void _showEditDialog(Map<String, dynamic> s) {
    final user = s['userId'] is Map ? s['userId'] as Map<String, dynamic> : null;
    final name = TextEditingController(text: user?['name']?.toString() ?? '');
    final rollNo = TextEditingController(text: (s['rollNo'] ?? '').toString());
    final department = TextEditingController(text: (s['department'] ?? '').toString());
    final course = TextEditingController(text: (s['course'] ?? '').toString());
    final id = _studentIdFromMap(s);
    if (id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Student'),
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
                await ApiService.updateStudent(id, {
                  'name': name.text.trim(),
                  'rollNo': rollNo.text.trim(),
                  'department': department.text.trim(),
                  'course': course.text.trim(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student updated')));
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
    final rollNo = TextEditingController();
    final department = TextEditingController();
    final course = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              TextField(controller: password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              TextField(controller: rollNo, decoration: const InputDecoration(labelText: 'Roll No')),
              TextField(controller: department, decoration: const InputDecoration(labelText: 'Department')),
              TextField(controller: course, decoration: const InputDecoration(labelText: 'Course')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (name.text.isEmpty || email.text.isEmpty || password.text.length < 6 || rollNo.text.isEmpty || department.text.isEmpty || course.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields, password min 6')));
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiService.addStudent({
                  'name': name.text,
                  'email': email.text,
                  'password': password.text,
                  'rollNo': rollNo.text,
                  'department': department.text,
                  'course': course.text,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student added')));
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
      appBar: AppBar(title: const Text('Manage Students'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add student'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? EmptyStateWithAction(message: 'No records found', actionLabel: 'Add student', onAction: _showAddDialog, icon: Icons.person_add)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) {
                      final s = _list[i] as Map<String, dynamic>;
                      final user = s['userId'] is Map ? s['userId'] as Map<String, dynamic> : null;
                      final name = user?['name'] ?? '';
                      final email = user?['email'] ?? '';
                      final rollNo = s['rollNo'] ?? '';
                      final id = _studentIdFromMap(s);
                      return Card(
                        child: ListTile(
                          title: Text('$name ($rollNo)'),
                          subtitle: Text(email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                                onPressed: id == null ? null : () => _showEditDialog(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: id == null
                                ? null
                                : () async {
                                    if (await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Delete student?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes'))])) != true) return;
                                    try {
                                      await ApiService.deleteStudent(id);
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
