import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.prefilledEmail});

  final String? prefilledEmail;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String _role = 'student';
  TextEditingController? _rollNoController;
  TextEditingController? _departmentController;
  TextEditingController? _courseController;
  TextEditingController? _employeeIdController;
  TextEditingController? _positionController;
  TextEditingController? _subjectsController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');
    _passwordController = TextEditingController();
    _rollNoController = TextEditingController();
    _departmentController = TextEditingController();
    _courseController = TextEditingController();
    _employeeIdController = TextEditingController();
    _positionController = TextEditingController();
    _subjectsController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rollNoController?.dispose();
    _departmentController?.dispose();
    _courseController?.dispose();
    _employeeIdController?.dispose();
    _positionController?.dispose();
    _subjectsController?.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildBody() {
    final body = <String, dynamic>{
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'role': _role,
    };
    if (_role == 'student') {
      body['rollNo'] = _rollNoController!.text.trim();
      body['department'] = _departmentController!.text.trim();
      body['course'] = _courseController!.text.trim();
    } else if (_role == 'faculty') {
      body['employeeId'] = _employeeIdController!.text.trim();
      body['department'] = _departmentController!.text.trim();
      body['subjects'] = _subjectsController!.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return body;
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) return false;
    if (_emailController.text.trim().isEmpty) return false;
    if (_passwordController.text.length < 6) return false;
    if (_role == 'student') {
      if (_rollNoController!.text.trim().isEmpty || _departmentController!.text.trim().isEmpty || _courseController!.text.trim().isEmpty) return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all required fields. Password min 6 characters.')));
      return;
    }
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.registerAndLogin(_buildBody());
    if (!mounted) return;
    if (ok) {
      switch (auth.user!.role) {
        case 'student':
          context.go('/student');
          break;
        case 'faculty':
          context.go('/faculty');
          break;
        default:
          context.go('/student');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Register'), backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (auth.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(auth.error!, style: TextStyle(color: Colors.red.shade700))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email *'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password (min 6) *',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Role *', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'student', label: Text('Student')),
                      ButtonSegment(value: 'faculty', label: Text('Faculty')),
                    ],
                    selected: {_role},
                    onSelectionChanged: (s) => setState(() => _role = s.first),
                  ),
                  const SizedBox(height: 16),
                  if (_role == 'student') ...[
                    TextFormField(controller: _rollNoController, decoration: const InputDecoration(labelText: 'Roll Number *')),
                    const SizedBox(height: 12),
                    TextFormField(controller: _departmentController, decoration: const InputDecoration(labelText: 'Department *')),
                    const SizedBox(height: 12),
                    TextFormField(controller: _courseController, decoration: const InputDecoration(labelText: 'Course *')),
                  ] else if (_role == 'faculty') ...[
                    TextFormField(controller: _employeeIdController, decoration: const InputDecoration(labelText: 'Employee ID')),
                    const SizedBox(height: 12),
                    TextFormField(controller: _departmentController, decoration: const InputDecoration(labelText: 'Department')),
                    const SizedBox(height: 12),
                    TextFormField(controller: _subjectsController, decoration: const InputDecoration(labelText: 'Subjects (comma separated)')),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: auth.loading ? null : _submit,
                    child: auth.loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Register'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(onPressed: () => context.go('/login'), child: const Text('Already have an account? Login')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
