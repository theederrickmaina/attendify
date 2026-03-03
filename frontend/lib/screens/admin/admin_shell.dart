import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import 'admin_dashboard_screen.dart';
import 'user_management_screen.dart';
import 'student_management_screen.dart';

class AdminShell extends StatefulWidget {
  final ApiService api;
  final VoidCallback onLogout;

  const AdminShell({super.key, required this.api, required this.onLogout});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  static const _navItems = [
    (icon: Icons.dashboard_rounded, label: 'Dashboard'),
    (icon: Icons.people_rounded, label: 'Users'),
    (icon: Icons.school_rounded, label: 'Students'),
    (icon: Icons.auto_stories_rounded, label: 'Academics'),
    (icon: Icons.devices_rounded, label: 'Devices'),
    (icon: Icons.assessment_rounded, label: 'Reports'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 800;
    final body = _buildBody();

    if (wide) {
      return Scaffold(body: Row(children: [
        _sidebar(),
        Container(width: 1, color: AttendifyTheme.divider.withValues(alpha: 0.3)),
        Expanded(child: body),
      ]));
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.face_retouching_natural, color: AttendifyTheme.primary, size: 20),
          const SizedBox(width: 8),
          GradientText('ATTENDIFY', style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.api.fullName, style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AttendifyTheme.textSecondary)),
            IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout, size: 18, color: AttendifyTheme.error), tooltip: 'Logout'),
          ])),
        ],
        backgroundColor: AttendifyTheme.surface, surfaceTintColor: Colors.transparent,
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab > 5 ? 0 : _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: _navItems.map((n) => NavigationDestination(icon: Icon(n.icon), label: n.label)).toList(),
      ),
    );
  }

  Widget _sidebar() {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: AttendifyTheme.surface,
        border: Border(right: BorderSide(color: AttendifyTheme.divider.withValues(alpha: 0.3))),
      ),
      child: Column(children: [
        const SizedBox(height: 24),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AttendifyTheme.primary.withValues(alpha: 0.15), AttendifyTheme.accentPink.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: AttendifyTheme.primary.withValues(alpha: 0.08), blurRadius: 12)],
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: AttendifyTheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GradientText('ATTENDIFY', style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w800)),
            Text('COMMAND CENTER', style: GoogleFonts.spaceGrotesk(fontSize: 9, color: AttendifyTheme.textSecondary, letterSpacing: 2)),
          ]),
        ])),
        const SizedBox(height: 32),
        ...List.generate(_navItems.length, (i) {
          final item = _navItems[i];
          final sel = _tab == i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Material(
              color: sel ? AttendifyTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _tab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: sel ? BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AttendifyTheme.primary.withValues(alpha: 0.15)),
                  ) : null,
                  child: Row(children: [
                    Icon(item.icon, size: 19, color: sel ? AttendifyTheme.primary : AttendifyTheme.textSecondary),
                    const SizedBox(width: 12),
                    Text(item.label, style: GoogleFonts.spaceGrotesk(fontSize: 13,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? AttendifyTheme.primary : AttendifyTheme.textSecondary)),
                  ]),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Container(height: 1, color: AttendifyTheme.divider.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AttendifyTheme.primary.withValues(alpha: 0.2), AttendifyTheme.accentPink.withValues(alpha: 0.1)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, size: 16, color: AttendifyTheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.api.fullName, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              Text('Superadmin', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AttendifyTheme.textSecondary)),
            ])),
            IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout, size: 16, color: AttendifyTheme.error)),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0: return AdminDashboardScreen(api: widget.api);
      case 1: return UserManagementScreen(api: widget.api);
      case 2: return StudentManagementScreen(api: widget.api);
      case 3: return _AcademicsTab(api: widget.api);
      case 4: return _DevicesTab(api: widget.api);
      case 5: return _ReportsTab(api: widget.api);
      default: return AdminDashboardScreen(api: widget.api);
    }
  }
}

// ── Academics Tab ─────────────────────────────────────────────────────────
class _AcademicsTab extends StatefulWidget {
  final ApiService api;
  const _AcademicsTab({required this.api});
  @override
  State<_AcademicsTab> createState() => _AcademicsTabState();
}

class _AcademicsTabState extends State<_AcademicsTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _departments = [], _courses = [], _units = [], _lecturerUnits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.api.getDepartments(),
        widget.api.getCourses(),
        widget.api.getUnits(),
        widget.api.getLecturerUnits(),
      ]);
      _departments = results[0]['departments'] ?? [];
      _courses = results[1]['courses'] ?? [];
      _units = results[2]['units'] ?? [];
      _lecturerUnits = results[3]['assignments'] ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabCtrl,
          indicatorColor: AttendifyTheme.primary,
          labelColor: AttendifyTheme.primary,
          unselectedLabelColor: AttendifyTheme.textSecondary,
          isScrollable: true,
          tabs: [
            Tab(child: Text('Departments (${_departments.length})', style: GoogleFonts.spaceGrotesk(fontSize: 13))),
            Tab(child: Text('Courses (${_courses.length})', style: GoogleFonts.spaceGrotesk(fontSize: 13))),
            Tab(child: Text('Units (${_units.length})', style: GoogleFonts.spaceGrotesk(fontSize: 13))),
            Tab(child: Text('Assignments (${_lecturerUnits.length})', style: GoogleFonts.spaceGrotesk(fontSize: 13))),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AttendifyTheme.primary))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    // ── Departments ──
                    _buildListWithFAB(
                      items: _departments,
                      onAdd: _showCreateDepartment,
                      emptyLabel: 'No departments yet',
                      builder: (d) => ListTile(
                        leading: const Icon(Icons.business, color: AttendifyTheme.accent),
                        title: Text(d['name'] ?? ''),
                        subtitle: Text('${d['code']}  ·  ${d['description'] ?? ''}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('${d['course_count'] ?? 0} courses',
                              style: const TextStyle(color: AttendifyTheme.textSecondary, fontSize: 12)),
                          const SizedBox(width: 4),
                          IconButton(icon: const Icon(Icons.edit, size: 18, color: AttendifyTheme.accent),
                              onPressed: () => _showEditDepartment(d), tooltip: 'Edit'),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AttendifyTheme.error),
                              onPressed: () => _confirmDelete('department', d['name'] ?? '', () => widget.api.deleteDepartment(d['id'])), tooltip: 'Delete'),
                        ]),
                      ),
                    ),
                    // ── Courses ──
                    _buildListWithFAB(
                      items: _courses,
                      onAdd: _showCreateCourse,
                      emptyLabel: 'No courses yet',
                      builder: (c) => ListTile(
                        leading: const Icon(Icons.menu_book, color: AttendifyTheme.primary),
                        title: Text(c['name'] ?? ''),
                        subtitle: Text('${c['code']}  ·  ${c['department_name'] ?? ''}  ·  ${c['duration_years'] ?? 4} yrs'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('${c['student_count'] ?? 0} students',
                              style: const TextStyle(color: AttendifyTheme.textSecondary, fontSize: 12)),
                          const SizedBox(width: 4),
                          IconButton(icon: const Icon(Icons.edit, size: 18, color: AttendifyTheme.accent),
                              onPressed: () => _showEditCourse(c), tooltip: 'Edit'),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AttendifyTheme.error),
                              onPressed: () => _confirmDelete('course', c['name'] ?? '', () => widget.api.deleteCourse(c['id'])), tooltip: 'Delete'),
                        ]),
                      ),
                    ),
                    // ── Units ──
                    _buildListWithFAB(
                      items: _units,
                      onAdd: _showCreateUnit,
                      emptyLabel: 'No units yet',
                      builder: (u) {
                        final courses = (u['courses'] as List?) ?? [];
                        final courseStr = courses.map((c) =>
                            '${c['course_code']} Y${c['year']}S${c['semester']}').join(', ');
                        return ListTile(
                          leading: const Icon(Icons.class_, color: Color(0xFFE91E63)),
                          title: Text(u['name'] ?? ''),
                          subtitle: Text('${u['code']}  ·  ${courseStr.isNotEmpty ? courseStr : 'No courses linked'}'),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('${u['credit_hours'] ?? 3} CH',
                                style: const TextStyle(color: AttendifyTheme.textSecondary, fontSize: 12)),
                            const SizedBox(width: 4),
                            IconButton(icon: const Icon(Icons.edit, size: 18, color: AttendifyTheme.accent),
                                onPressed: () => _showEditUnit(u), tooltip: 'Edit'),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AttendifyTheme.error),
                                onPressed: () => _confirmDelete('unit', u['name'] ?? '', () => widget.api.deleteUnit(u['id'])), tooltip: 'Delete'),
                          ]),
                        );
                      },
                    ),
                    // ── Lecturer-Unit Assignments ──
                    _buildListWithFAB(
                      items: _lecturerUnits,
                      onAdd: _showAssignLecturer,
                      emptyLabel: 'No assignments yet',
                      addLabel: 'Assign',
                      builder: (a) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.15),
                          child: const Icon(Icons.person, color: Color(0xFFFF9800), size: 20),
                        ),
                        title: Text(a['lecturer_name'] ?? ''),
                        subtitle: Text('${a['unit_code'] ?? ''}  ·  ${a['unit_name'] ?? ''}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(a['academic_year'] ?? '',
                              style: const TextStyle(color: AttendifyTheme.textSecondary, fontSize: 12)),
                          const SizedBox(width: 4),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AttendifyTheme.error),
                              onPressed: () => _confirmDelete('assignment', '${a['lecturer_name']} → ${a['unit_code']}',
                                  () => widget.api.deleteLecturerUnit(a['id'])), tooltip: 'Remove'),
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildListWithFAB({
    required List<dynamic> items,
    required VoidCallback onAdd,
    required String emptyLabel,
    required Widget Function(Map<String, dynamic>) builder,
    String addLabel = 'Create',
  }) {
    return Stack(
      children: [
        items.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inbox, size: 48, color: AttendifyTheme.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text(emptyLabel, style: const TextStyle(color: AttendifyTheme.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(addLabel),
                ),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AttendifyTheme.divider),
                itemBuilder: (_, i) => builder(items[i] as Map<String, dynamic>),
              ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(addLabel),
            backgroundColor: AttendifyTheme.primary,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }

  // ── Confirm Delete Dialog ──
  void _confirmDelete(String type, String name, Future<Map<String, dynamic>> Function() deleteCall) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $type?'),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AttendifyTheme.error),
            onPressed: () async {
              final r = await deleteCall();
              if (ctx.mounted) Navigator.pop(ctx);
              if (r['_ok'] == true) {
                _load();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${r['error'] ?? 'Delete failed'}')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Edit Department Dialog ──
  void _showEditDepartment(Map<String, dynamic> d) {
    final nameCtrl = TextEditingController(text: d['name'] ?? '');
    final codeCtrl = TextEditingController(text: d['code'] ?? '');
    final descCtrl = TextEditingController(text: d['description'] ?? '');
    _showFormDialog(
      title: 'Edit Department',
      fields: [
        _field(nameCtrl, 'Department Name', Icons.business),
        _field(codeCtrl, 'Code', Icons.code),
        _field(descCtrl, 'Description / School', Icons.description),
      ],
      onSubmit: () async {
        if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) return 'Name and code are required';
        final r = await widget.api.updateDepartment(d['id'], {
          'name': nameCtrl.text, 'code': codeCtrl.text, 'description': descCtrl.text,
        });
        if (r['_ok'] == true) { _load(); return null; }
        return r['error']?.toString() ?? 'Failed to update';
      },
    );
  }

  // ── Edit Course Dialog ──
  void _showEditCourse(Map<String, dynamic> c) {
    final nameCtrl = TextEditingController(text: c['name'] ?? '');
    final codeCtrl = TextEditingController(text: c['code'] ?? '');
    final durationCtrl = TextEditingController(text: '${c['duration_years'] ?? 4}');
    int? selectedDeptId = c['department_id'];

    _showFormDialog(
      title: 'Edit Course',
      fields: [
        _field(nameCtrl, 'Course Name', Icons.menu_book),
        _field(codeCtrl, 'Code', Icons.code),
        StatefulBuilder(builder: (ctx, setSt) => DropdownButtonFormField<int>(
          decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business)),
          initialValue: selectedDeptId,
          items: _departments.map<DropdownMenuItem<int>>((d) =>
              DropdownMenuItem(value: d['id'] as int, child: Text('${d['code']} — ${d['name']}'))).toList(),
          onChanged: (v) => selectedDeptId = v,
        )),
        _field(durationCtrl, 'Duration (years)', Icons.timer, inputType: TextInputType.number),
      ],
      onSubmit: () async {
        if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty || selectedDeptId == null) {
          return 'Name, code, and department are required';
        }
        final r = await widget.api.updateCourse(c['id'], {
          'name': nameCtrl.text, 'code': codeCtrl.text,
          'department_id': selectedDeptId,
          'duration_years': int.tryParse(durationCtrl.text) ?? 4,
        });
        if (r['_ok'] == true) { _load(); return null; }
        return r['error']?.toString() ?? 'Failed to update';
      },
    );
  }

  // ── Edit Unit Dialog ──
  void _showEditUnit(Map<String, dynamic> u) {
    final nameCtrl = TextEditingController(text: u['name'] ?? '');
    final codeCtrl = TextEditingController(text: u['code'] ?? '');
    final creditCtrl = TextEditingController(text: '${u['credit_hours'] ?? 3}');
    final existingCourses = (u['courses'] as List?)?.map((c) => {
      'course_id': c['course_id'] as int, 'year': c['year'] as int, 'semester': c['semester'] as int,
    }).toList() ?? [];
    final List<Map<String, int>> courseLinks = existingCourses.isNotEmpty
        ? existingCourses : [{'course_id': 0, 'year': 1, 'semester': 1}];
    bool submitting = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Unit'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Unit Name', Icons.class_),
                const SizedBox(height: 14),
                _field(codeCtrl, 'Unit Code', Icons.code),
                const SizedBox(height: 14),
                _field(creditCtrl, 'Credit Hours', Icons.timer, inputType: TextInputType.number),
                const SizedBox(height: 18),
                Row(children: [
                  const Icon(Icons.link, size: 16, color: AttendifyTheme.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Course Links', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setDialogState(() =>
                        courseLinks.add({'course_id': 0, 'year': 1, 'semester': 1})),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Course'),
                  ),
                ]),
                ...List.generate(courseLinks.length, (i) {
                  final link = courseLinks[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          Expanded(child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Course', isDense: true),
                            initialValue: link['course_id'] == 0 ? null : link['course_id'],
                            items: _courses.map<DropdownMenuItem<int>>((c) =>
                                DropdownMenuItem(value: c['id'] as int,
                                    child: Text('${c['code']}', style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) => setDialogState(() => link['course_id'] = v ?? 0),
                          )),
                          if (courseLinks.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: AttendifyTheme.error, size: 20),
                              onPressed: () => setDialogState(() => courseLinks.removeAt(i)),
                            ),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Year', isDense: true),
                            initialValue: link['year'],
                            items: List.generate(6, (j) => DropdownMenuItem(value: j + 1, child: Text('Y${j + 1}'))),
                            onChanged: (v) => setDialogState(() => link['year'] = v ?? 1),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Semester', isDense: true),
                            initialValue: link['semester'],
                            items: List.generate(3, (j) => DropdownMenuItem(value: j + 1, child: Text('S${j + 1}'))),
                            onChanged: (v) => setDialogState(() => link['semester'] = v ?? 1),
                          )),
                        ]),
                      ]),
                    ),
                  );
                }),
                if (errorMsg != null)
                  Padding(padding: const EdgeInsets.only(top: 8),
                    child: Text(errorMsg!, style: const TextStyle(color: AttendifyTheme.error, fontSize: 13))),
              ],
            )),
          ),
          actions: [
            TextButton(onPressed: submitting ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: submitting ? null : () async {
                if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) {
                  setDialogState(() => errorMsg = 'Name and code are required');
                  return;
                }
                final validLinks = courseLinks.where((l) => (l['course_id'] ?? 0) > 0).toList();
                if (validLinks.isEmpty) {
                  setDialogState(() => errorMsg = 'Add at least one course link');
                  return;
                }
                setDialogState(() { submitting = true; errorMsg = null; });
                final r = await widget.api.updateUnit(u['id'], {
                  'name': nameCtrl.text, 'code': codeCtrl.text,
                  'credit_hours': int.tryParse(creditCtrl.text) ?? 3,
                  'courses': validLinks.map((l) => {
                    'course_id': l['course_id'], 'year': l['year'], 'semester': l['semester'],
                  }).toList(),
                });
                if (r['_ok'] == true) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } else {
                  setDialogState(() { submitting = false; errorMsg = r['error']?.toString() ?? 'Failed'; });
                }
              },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Create Department Dialog ──
  void _showCreateDepartment() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    _showFormDialog(
      title: 'Create Department',
      fields: [
        _field(nameCtrl, 'Department Name', Icons.business),
        _field(codeCtrl, 'Code (e.g. DCIT)', Icons.code),
        _field(descCtrl, 'Description / School', Icons.description),
      ],
      onSubmit: () async {
        if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) return 'Name and code are required';
        final r = await widget.api.createDepartment({
          'name': nameCtrl.text, 'code': codeCtrl.text, 'description': descCtrl.text,
        });
        if (r['_ok'] == true) { _load(); return null; }
        return r['error']?.toString() ?? 'Failed to create department';
      },
    );
  }

  // ── Create Course Dialog ──
  void _showCreateCourse() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '4');
    int? selectedDeptId;

    _showFormDialog(
      title: 'Create Course',
      fields: [
        _field(nameCtrl, 'Course Name', Icons.menu_book),
        _field(codeCtrl, 'Code (e.g. BSCIT)', Icons.code),
        StatefulBuilder(builder: (ctx, setSt) => DropdownButtonFormField<int>(
          decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business)),
          items: _departments.map<DropdownMenuItem<int>>((d) =>
              DropdownMenuItem(value: d['id'] as int, child: Text('${d['code']} — ${d['name']}'))).toList(),
          onChanged: (v) => selectedDeptId = v,
        )),
        _field(durationCtrl, 'Duration (years)', Icons.timer, inputType: TextInputType.number),
      ],
      onSubmit: () async {
        if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty || selectedDeptId == null) {
          return 'Name, code, and department are required';
        }
        final r = await widget.api.createCourse({
          'name': nameCtrl.text, 'code': codeCtrl.text,
          'department_id': selectedDeptId,
          'duration_years': int.tryParse(durationCtrl.text) ?? 4,
        });
        if (r['_ok'] == true) { _load(); return null; }
        return r['error']?.toString() ?? 'Failed to create course';
      },
    );
  }

  // ── Create Unit Dialog (supports multiple courses) ──
  void _showCreateUnit() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final creditCtrl = TextEditingController(text: '3');
    // Each link: {course_id, year, semester}
    final List<Map<String, int>> courseLinks = [{'course_id': 0, 'year': 1, 'semester': 1}];
    bool submitting = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Unit'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameCtrl, 'Unit Name', Icons.class_),
                const SizedBox(height: 14),
                _field(codeCtrl, 'Unit Code (e.g. CIT101)', Icons.code),
                const SizedBox(height: 14),
                _field(creditCtrl, 'Credit Hours', Icons.timer, inputType: TextInputType.number),
                const SizedBox(height: 18),
                Row(children: [
                  const Icon(Icons.link, size: 16, color: AttendifyTheme.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Course Links', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setDialogState(() =>
                        courseLinks.add({'course_id': 0, 'year': 1, 'semester': 1})),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Course'),
                  ),
                ]),
                ...List.generate(courseLinks.length, (i) {
                  final link = courseLinks[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          Expanded(child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Course', isDense: true),
                            value: link['course_id'] == 0 ? null : link['course_id'],
                            items: _courses.map<DropdownMenuItem<int>>((c) =>
                                DropdownMenuItem(value: c['id'] as int,
                                    child: Text('${c['code']}', style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: (v) => setDialogState(() => link['course_id'] = v ?? 0),
                          )),
                          if (courseLinks.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: AttendifyTheme.error, size: 20),
                              onPressed: () => setDialogState(() => courseLinks.removeAt(i)),
                            ),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Year', isDense: true),
                            value: link['year'],
                            items: List.generate(6, (j) => DropdownMenuItem(value: j + 1, child: Text('Y${j + 1}'))),
                            onChanged: (v) => setDialogState(() => link['year'] = v ?? 1),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Semester', isDense: true),
                            value: link['semester'],
                            items: List.generate(3, (j) => DropdownMenuItem(value: j + 1, child: Text('S${j + 1}'))),
                            onChanged: (v) => setDialogState(() => link['semester'] = v ?? 1),
                          )),
                        ]),
                      ]),
                    ),
                  );
                }),
                if (errorMsg != null)
                  Padding(padding: const EdgeInsets.only(top: 8),
                    child: Text(errorMsg!, style: const TextStyle(color: AttendifyTheme.error, fontSize: 13))),
              ],
            )),
          ),
          actions: [
            TextButton(onPressed: submitting ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: submitting ? null : () async {
                if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) {
                  setDialogState(() => errorMsg = 'Name and code are required');
                  return;
                }
                final validLinks = courseLinks.where((l) => (l['course_id'] ?? 0) > 0).toList();
                if (validLinks.isEmpty) {
                  setDialogState(() => errorMsg = 'Add at least one course link');
                  return;
                }
                setDialogState(() { submitting = true; errorMsg = null; });
                final r = await widget.api.createUnit({
                  'name': nameCtrl.text, 'code': codeCtrl.text,
                  'credit_hours': int.tryParse(creditCtrl.text) ?? 3,
                  'courses': validLinks.map((l) => {
                    'course_id': l['course_id'], 'year': l['year'], 'semester': l['semester'],
                  }).toList(),
                });
                if (r['_ok'] == true) {
                  if (ctx.mounted) Navigator.pop(ctx);
                  _load();
                } else {
                  setDialogState(() { submitting = false; errorMsg = r['error']?.toString() ?? 'Failed'; });
                }
              },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Assign Lecturer to Unit Dialog ──
  void _showAssignLecturer() async {
    // Fetch lecturers
    final lecRes = await widget.api.getUsers(role: 'lecturer');
    final lecturers = (lecRes['users'] as List?) ?? [];
    if (!mounted) return;

    int? selectedLecturerId;
    int? selectedUnitId;

    _showFormDialog(
      title: 'Assign Lecturer → Unit',
      fields: [
        StatefulBuilder(builder: (ctx, setSt) => DropdownButtonFormField<int>(
          decoration: const InputDecoration(labelText: 'Lecturer', prefixIcon: Icon(Icons.person)),
          items: lecturers.map<DropdownMenuItem<int>>((l) =>
              DropdownMenuItem(value: l['id'] as int,
                  child: Text('${l['first_name']} ${l['last_name']} (${l['username']})'))).toList(),
          onChanged: (v) => selectedLecturerId = v,
        )),
        StatefulBuilder(builder: (ctx, setSt) => DropdownButtonFormField<int>(
          decoration: const InputDecoration(labelText: 'Unit', prefixIcon: Icon(Icons.class_)),
          items: _units.map<DropdownMenuItem<int>>((u) =>
              DropdownMenuItem(value: u['id'] as int,
                  child: Text('${u['code']} — ${u['name']}'))).toList(),
          onChanged: (v) => selectedUnitId = v,
        )),
      ],
      onSubmit: () async {
        if (selectedLecturerId == null || selectedUnitId == null) {
          return 'Select both a lecturer and a unit';
        }
        final r = await widget.api.assignLecturerUnit({
          'lecturer_id': selectedLecturerId,
          'unit_id': selectedUnitId,
        });
        if (r['_ok'] == true) { _load(); return null; }
        return r['error']?.toString() ?? 'Failed to assign';
      },
    );
  }

  // ── Reusable Form Dialog ──
  void _showFormDialog({
    required String title,
    required List<Widget> fields,
    required Future<String?> Function() onSubmit,
  }) {
    bool submitting = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...fields.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: f,
                  )),
                  if (errorMsg != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(errorMsg!, style: const TextStyle(color: AttendifyTheme.error, fontSize: 13)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: submitting ? null : () async {
                setDialogState(() { submitting = true; errorMsg = null; });
                final err = await onSubmit();
                if (err == null) {
                  if (ctx.mounted) Navigator.pop(ctx);
                } else {
                  setDialogState(() { submitting = false; errorMsg = err; });
                }
              },
              child: submitting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
}

// ── Devices Tab ──────────────────────────────────────────────────────────
class _DevicesTab extends StatefulWidget {
  final ApiService api;
  const _DevicesTab({required this.api});
  @override
  State<_DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends State<_DevicesTab> {
  List<dynamic> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await widget.api.getDevices();
    if (r['_ok'] == true) _devices = r['devices'] ?? [];
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Kiosk Devices',
                  style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  final r = await widget.api.createDevice({
                    'name': 'New Kiosk', 'location': 'TBD'});
                  if (r['_ok'] == true) {
                    _load();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Device created. Key: ${r['device_key']}')));
                    }
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add Device', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AttendifyTheme.primary))
                : _devices.isEmpty
                ? Center(child: Text('No devices registered', style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary)))
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (_, i) {
                      final d = _devices[i] as Map<String, dynamic>;
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
                                color: (d['is_active'] == true ? AttendifyTheme.success : AttendifyTheme.error).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.devices_rounded, size: 20,
                                    color: d['is_active'] == true ? AttendifyTheme.success : AttendifyTheme.error)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d['name'] ?? '', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
                                Text(d['location'] ?? 'No location',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AttendifyTheme.textSecondary)),
                              ],
                            )),
                            NeonChip(label: d['is_active'] == true ? 'ACTIVE' : 'INACTIVE',
                                color: d['is_active'] == true ? AttendifyTheme.success : AttendifyTheme.error),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Reports Tab ─────────────────────────────────────────────────────────
class _ReportsTab extends StatefulWidget {
  final ApiService api;
  const _ReportsTab({required this.api});
  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  Map<String, dynamic> _data = {};
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      widget.api.getReports(),
      widget.api.getAuditLog(limit: 30),
    ]);
    _data = results[0];
    _logs = results[1]['logs'] ?? [];
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AttendifyTheme.primary));
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Reports & Analytics',
            style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        GlassCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SYSTEM SUMMARY', style: GoogleFonts.orbitron(fontSize: 11, color: AttendifyTheme.primary, letterSpacing: 2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _row('Total Students', '${_data['total_students'] ?? 0}'),
            _row('Face Enrollment Rate', '${((_data['face_enrollment_rate'] ?? 0) * 100).toStringAsFixed(1)}%'),
            _row('Today Attendance', '${_data['today_attendance'] ?? 0}'),
          ],
        )),
        const SizedBox(height: 16),
        Text('AUDIT LOG', style: GoogleFonts.orbitron(fontSize: 11, color: AttendifyTheme.primary, letterSpacing: 2, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._logs.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(
                    color: AttendifyTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.history, size: 14, color: AttendifyTheme.accent)),
                const SizedBox(width: 8),
                Expanded(child: Text('${l['action']}  ·  ${l['user_name'] ?? 'system'}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500))),
                Text(l['created_at']?.toString().substring(0, 16) ?? '',
                    style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AttendifyTheme.textSecondary)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary, fontSize: 13)),
      Text(value, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
    ]),
  );
}
