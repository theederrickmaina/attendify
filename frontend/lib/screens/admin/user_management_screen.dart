import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class UserManagementScreen extends StatefulWidget {
  final ApiService api;
  const UserManagementScreen({super.key, required this.api});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String _roleFilter = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await widget.api.getUsers(
        role: _roleFilter.isEmpty ? null : _roleFilter,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      if (r['_ok'] == true) _users = r['users'] ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final data = <String, String>{};
    String role = 'student';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDState) => AlertDialog(
        title: const Text('Create User'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'lecturer', child: Text('Lecturer')),
                    DropdownMenuItem(value: 'superadmin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setDState(() => role = v ?? 'student'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  onSaved: (v) => data['username'] = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 chars' : null,
                  onSaved: (v) => data['password'] = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  onSaved: (v) => data['first_name'] = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  onSaved: (v) => data['last_name'] = v ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  onSaved: (v) => data['email'] = v ?? '',
                ),
                if (role == 'student') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Registration No.'),
                    validator: (v) => role == 'student' && (v?.isEmpty == true) ? 'Required' : null,
                    onSaved: (v) => data['registration_number'] = v ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Course ID'),
                    keyboardType: TextInputType.number,
                    validator: (v) => role == 'student' && (v?.isEmpty == true) ? 'Required' : null,
                    onSaved: (v) => data['course_id'] = v ?? '',
                  ),
                ],
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              formKey.currentState!.save();
              data['role'] = role;
              final r = await widget.api.createUser(data);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (r['_ok'] == true) {
                _load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User created')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${r['error'] ?? 'Unknown'}')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search users...', prefixIcon: Icon(Icons.search)),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _roleFilter,
                dropdownColor: AttendifyTheme.surfaceLight,
                items: const [
                  DropdownMenuItem(value: '', child: Text('All Roles')),
                  DropdownMenuItem(value: 'superadmin', child: Text('Admin')),
                  DropdownMenuItem(value: 'lecturer', child: Text('Lecturer')),
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                ],
                onChanged: (v) { _roleFilter = v ?? ''; _load(); },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New User'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AttendifyTheme.primary))
              : _users.isEmpty
              ? const Center(child: Text('No users found', style: TextStyle(color: AttendifyTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _users.length,
                  itemBuilder: (ctx, i) => _userTile(_users[i]),
                ),
        ),
      ],
    );
  }

  Widget _userTile(Map<String, dynamic> u) {
    final role = u['role'] ?? '';
    final roleColor = role == 'superadmin' ? AttendifyTheme.error
        : role == 'lecturer' ? const Color(0xFFFF9800)
        : AttendifyTheme.primary;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withValues(alpha: 0.15),
            child: Icon(
              role == 'superadmin' ? Icons.admin_panel_settings
                  : role == 'lecturer' ? Icons.school
                  : Icons.person,
              color: roleColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u['full_name'] ?? '', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('@${u['username']}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AttendifyTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(role.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, color: roleColor)),
          ),
          const SizedBox(width: 8),
          Icon(
            u['is_active'] == true ? Icons.check_circle : Icons.cancel,
            color: u['is_active'] == true ? AttendifyTheme.success : AttendifyTheme.error,
            size: 18,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
