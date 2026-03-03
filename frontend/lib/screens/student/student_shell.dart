import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class StudentShell extends StatefulWidget {
  final ApiService api;
  final VoidCallback onLogout;
  const StudentShell({super.key, required this.api, required this.onLogout});
  @override State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _tab = 0;
  static const _navItems = [
    (icon: Icons.dashboard_rounded, label: 'Dashboard'),
    (icon: Icons.auto_stories_rounded, label: 'My Units'),
    (icon: Icons.fact_check_rounded, label: 'Attendance'),
    (icon: Icons.settings_rounded, label: 'Settings'),
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
        backgroundColor: AttendifyTheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
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
              gradient: LinearGradient(colors: [AttendifyTheme.primary.withValues(alpha: 0.15), AttendifyTheme.accent.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: AttendifyTheme.primary.withValues(alpha: 0.08), blurRadius: 12)],
            ),
            child: const Icon(Icons.face_retouching_natural, color: AttendifyTheme.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GradientText('ATTENDIFY', style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w800)),
            Text('STUDENT PORTAL', style: GoogleFonts.spaceGrotesk(fontSize: 9, color: AttendifyTheme.textSecondary, letterSpacing: 2)),
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
                gradient: LinearGradient(colors: [AttendifyTheme.primary.withValues(alpha: 0.2), AttendifyTheme.accent.withValues(alpha: 0.1)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, size: 16, color: AttendifyTheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.api.fullName, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              Text('Student', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AttendifyTheme.textSecondary)),
            ])),
            IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout, size: 16, color: AttendifyTheme.error)),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0: return _StudentDashboard(api: widget.api);
      case 1: return _MyUnitsScreen(api: widget.api);
      case 2: return _AttendanceScreen(api: widget.api);
      case 3: return _StudentSettings(api: widget.api, onLogout: widget.onLogout);
      default: return _StudentDashboard(api: widget.api);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STUDENT DASHBOARD — with pie chart + animated stats
// ═══════════════════════════════════════════════════════════════════════════
class _StudentDashboard extends StatefulWidget {
  final ApiService api;
  const _StudentDashboard({required this.api});
  @override State<_StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<_StudentDashboard> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await widget.api.getStudentDashboard();
      if (r['_ok'] == true) _data = r;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AttendifyTheme.primary));
    final student = (_data['student'] as Map<String, dynamic>?) ?? {};
    final totalClasses = _data['total_classes'] ?? 0;
    final attended = _data['classes_attended'] ?? 0;
    final missed = totalClasses - attended;
    final rate = (_data['attendance_rate'] ?? 0).toDouble();
    final unitStats = (_data['unit_stats'] as Map<String, dynamic>?) ?? {};
    final recent = (_data['recent_attendance'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _load, color: AttendifyTheme.primary,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        // Greeting
        Text('Welcome back,', style: GoogleFonts.spaceGrotesk(fontSize: 14, color: AttendifyTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(student['first_name'] ?? widget.api.fullName,
            style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Row(children: [
          NeonChip(label: student['registration_number'] ?? '', color: AttendifyTheme.primary),
          const SizedBox(width: 8),
          NeonChip(label: '${student['course_code'] ?? ''}  Y${student['year'] ?? ''}S${student['semester'] ?? ''}', color: AttendifyTheme.accent),
        ]),
        const SizedBox(height: 24),

        // Stats row
        LayoutBuilder(builder: (_, c) {
          final cols = c.maxWidth > 600 ? 3 : 2;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(width: w, child: StatCard(title: 'Total Classes', value: '$totalClasses', icon: Icons.event_note_rounded, color: AttendifyTheme.accent)),
            SizedBox(width: w, child: StatCard(title: 'Attended', value: '$attended', icon: Icons.check_circle_rounded, color: AttendifyTheme.success)),
            SizedBox(width: w, child: StatCard(title: 'Attendance Rate',
                value: '${(rate * 100).toStringAsFixed(0)}%', icon: Icons.trending_up_rounded,
                color: rate >= 0.75 ? AttendifyTheme.success : rate >= 0.5 ? AttendifyTheme.warning : AttendifyTheme.error)),
          ]);
        }),

        // Attendance pie chart
        if (totalClasses > 0) ...[
          const SizedBox(height: 24),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ATTENDANCE OVERVIEW', style: GoogleFonts.orbitron(fontSize: 11, color: AttendifyTheme.primary, letterSpacing: 2, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: Row(children: [
                  Expanded(child: PieChart(PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(value: attended.toDouble(), color: AttendifyTheme.success,
                          title: '$attended', titleStyle: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), radius: 30),
                      if (missed > 0)
                        PieChartSectionData(value: missed.toDouble(), color: AttendifyTheme.error.withValues(alpha: 0.7),
                            title: '$missed', titleStyle: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), radius: 30),
                    ],
                  ))),
                  const SizedBox(width: 24),
                  Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _legendItem('Present', AttendifyTheme.success, attended),
                    const SizedBox(height: 8),
                    _legendItem('Missed', AttendifyTheme.error, missed),
                    const SizedBox(height: 16),
                    Text('${(rate * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.w800, color: rate >= 0.75 ? AttendifyTheme.success : AttendifyTheme.warning)),
                    Text('overall rate', style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AttendifyTheme.textSecondary)),
                  ]),
                ]),
              ),
            ]),
          ),
        ],

        // Unit breakdown with bar-style progress
        if (unitStats.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('UNIT BREAKDOWN', style: GoogleFonts.orbitron(fontSize: 11, color: AttendifyTheme.primary, letterSpacing: 2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...unitStats.entries.map((e) {
            final u = e.value as Map<String, dynamic>;
            final uAttended = u['attended'] ?? 0;
            final uTotal = u['total'] ?? 0;
            final uRate = uTotal > 0 ? uAttended / uTotal : 0.0;
            final barColor = uRate >= 0.75 ? AttendifyTheme.success : uRate >= 0.5 ? AttendifyTheme.warning : AttendifyTheme.error;
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u['unit_name'] ?? e.key, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${e.key}  ·  $uAttended / $uTotal sessions',
                        style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AttendifyTheme.textSecondary)),
                  ])),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(colors: [barColor, barColor.withValues(alpha: 0.7)]).createShader(bounds),
                    child: Text('${(uRate * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: uRate.toDouble(), minHeight: 5,
                      backgroundColor: AttendifyTheme.divider.withValues(alpha: 0.5),
                      valueColor: AlwaysStoppedAnimation(barColor)),
                ),
              ]),
            );
          }),
        ],

        // Recent check-ins
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('RECENT CHECK-INS', style: GoogleFonts.orbitron(fontSize: 11, color: AttendifyTheme.primary, letterSpacing: 2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...recent.map((a) {
            final status = a['status'] ?? '';
            final sc = status == 'present' ? AttendifyTheme.success : status == 'late' ? AttendifyTheme.warning : AttendifyTheme.error;
            return Padding(padding: const EdgeInsets.only(bottom: 4), child: GlassCard(
              padding: const EdgeInsets.all(12), margin: EdgeInsets.zero,
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: sc.withValues(alpha: 0.08), blurRadius: 8)]),
                  child: Icon(status == 'present' ? Icons.check_circle : status == 'late' ? Icons.access_time : Icons.cancel, color: sc, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(a['check_in_time']?.toString().substring(0, 16) ?? '',
                    style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w500))),
                NeonChip(label: status.toUpperCase(), color: sc),
              ]),
            ));
          }),
        ],
      ]),
    );
  }

  Widget _legendItem(String label, Color color, int count) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4)])),
      const SizedBox(width: 8),
      Text('$label ($count)', style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AttendifyTheme.textSecondary)),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MY UNITS (Enrollment)
// ═══════════════════════════════════════════════════════════════════════════
class _MyUnitsScreen extends StatefulWidget {
  final ApiService api;
  const _MyUnitsScreen({required this.api});
  @override State<_MyUnitsScreen> createState() => _MyUnitsScreenState();
}

class _MyUnitsScreenState extends State<_MyUnitsScreen> {
  List<dynamic> _enrolled = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { final r = await widget.api.getMyUnits(); if (r['_ok'] == true) _enrolled = r['units'] ?? []; } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showEnrollDialog() async {
    final r = await widget.api.getAvailableUnits();
    if (r['_ok'] != true || !mounted) return;
    final units = (r['units'] as List?) ?? [];
    final year = r['student_year']; final sem = r['student_semester']; final course = r['course_code'] ?? '';
    if (!mounted) return;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
              color: AttendifyTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.auto_stories_rounded, color: AttendifyTheme.primary, size: 20)),
          const SizedBox(width: 12),
          Text('Enroll — $course Y${year}S$sem', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        ]),
        content: SizedBox(width: 420, height: 400,
          child: units.isEmpty
              ? Center(child: Text('No units available', style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary)))
              : ListView.separated(itemCount: units.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AttendifyTheme.divider),
                  itemBuilder: (_, i) {
                    final u = units[i] as Map<String, dynamic>;
                    final enrolled = u['enrolled'] == true;
                    final lecturers = (u['lecturers'] as List?)?.join(', ') ?? 'TBA';
                    return ListTile(
                      leading: Icon(enrolled ? Icons.check_circle : Icons.auto_stories_rounded,
                          color: enrolled ? AttendifyTheme.success : AttendifyTheme.accent),
                      title: Text(u['name'] ?? '', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
                      subtitle: Text('${u['code']}  ·  ${u['credit_hours'] ?? 3} CH  ·  $lecturers',
                          style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AttendifyTheme.textSecondary)),
                      trailing: enrolled
                          ? NeonChip(label: 'ENROLLED', color: AttendifyTheme.success)
                          : ElevatedButton(
                              onPressed: () async {
                                final res = await widget.api.enrollUnit(u['id']);
                                if (res['_ok'] == true) { u['enrolled'] = true; setDialogState(() {}); _load(); }
                                else if (ctx.mounted) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed'))); }
                              },
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  textStyle: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600)),
                              child: const Text('Enroll'),
                            ),
                    );
                  }),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AttendifyTheme.primary));
    return RefreshIndicator(onRefresh: _load, color: AttendifyTheme.primary,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('My Units', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${_enrolled.length} units enrolled this semester',
                style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary, fontSize: 12)),
          ])),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AttendifyTheme.primary.withValues(alpha: 0.15), blurRadius: 12)]),
            child: ElevatedButton.icon(onPressed: _showEnrollDialog,
                icon: const Icon(Icons.add, size: 18), label: const Text('Enroll')),
          ),
        ]),
        const SizedBox(height: 20),
        if (_enrolled.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.auto_stories_rounded, size: 48, color: AttendifyTheme.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No units enrolled yet', style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: _showEnrollDialog, icon: const Icon(Icons.add, size: 18), label: const Text('Browse Units')),
          ]))),
        ..._enrolled.map((u) {
          final attended = u['sessions_attended'] ?? 0;
          final total = u['total_sessions'] ?? 0;
          final rate = (u['attendance_rate'] ?? 0).toDouble();
          final lecturers = (u['lecturers'] as List?)?.join(', ') ?? 'TBA';
          final barColor = rate >= 0.75 ? AttendifyTheme.success : rate >= 0.5 ? AttendifyTheme.warning : AttendifyTheme.error;
          return GlassCard(
            margin: const EdgeInsets.only(bottom: 12), glowColor: barColor.withValues(alpha: 0.3),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [barColor.withValues(alpha: 0.15), barColor.withValues(alpha: 0.05)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: barColor.withValues(alpha: 0.1), blurRadius: 8)]),
                    child: Icon(Icons.auto_stories_rounded, color: barColor, size: 20)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u['unit_name'] ?? '', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${u['unit_code']}  ·  ${u['credit_hours'] ?? 3} CH',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AttendifyTheme.textSecondary)),
                  Text(lecturers, style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AttendifyTheme.accent.withValues(alpha: 0.8))),
                ])),
                Column(children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(colors: [barColor, barColor.withValues(alpha: 0.7)]).createShader(bounds),
                    child: Text('${(rate * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  Text('$attended/$total', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AttendifyTheme.textSecondary)),
                ]),
              ]),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: rate, minHeight: 5,
                    backgroundColor: AttendifyTheme.divider.withValues(alpha: 0.5), valueColor: AlwaysStoppedAnimation(barColor))),
            ]),
          );
        }),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ATTENDANCE HISTORY
// ═══════════════════════════════════════════════════════════════════════════
class _AttendanceScreen extends StatefulWidget {
  final ApiService api;
  const _AttendanceScreen({required this.api});
  @override State<_AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<_AttendanceScreen> {
  List<dynamic> _records = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await widget.api.getStudentAttendance();
    if (r['_ok'] == true) _records = r['attendance'] ?? [];
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AttendifyTheme.primary));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Attendance History', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('${_records.length} records', style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary, fontSize: 12)),
      const SizedBox(height: 16),
      if (_records.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.event_busy_rounded, size: 48, color: AttendifyTheme.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No attendance records yet', style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary)),
        ]))),
      ..._records.map((a) {
        final status = a['status'] ?? '';
        final sc = status == 'present' ? AttendifyTheme.success : status == 'late' ? AttendifyTheme.warning : AttendifyTheme.error;
        return GlassCard(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: sc.withValues(alpha: 0.08), blurRadius: 8)]),
                child: Icon(status == 'present' ? Icons.check_circle : status == 'late' ? Icons.access_time : Icons.cancel, color: sc, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a['check_in_time']?.toString().substring(0, 16) ?? '',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 13)),
              if (a['verification_method'] != null)
                Text('via ${a['verification_method']}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AttendifyTheme.textSecondary)),
            ])),
            NeonChip(label: status.toUpperCase(), color: sc),
            if (a['confidence_score'] != null) ...[
              const SizedBox(width: 8),
              Text('${(a['confidence_score'] * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AttendifyTheme.textSecondary)),
            ],
          ]),
        );
      }),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SETTINGS
// ═══════════════════════════════════════════════════════════════════════════
class _StudentSettings extends StatefulWidget {
  final ApiService api;
  final VoidCallback onLogout;
  const _StudentSettings({required this.api, required this.onLogout});
  @override State<_StudentSettings> createState() => _StudentSettingsState();
}

class _StudentSettingsState extends State<_StudentSettings> {
  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Settings', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 24),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Change Password', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 16),
        TextField(controller: _currentPw, obscureText: true,
            decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock_outline))),
        const SizedBox(height: 12),
        TextField(controller: _newPw, obscureText: true,
            decoration: const InputDecoration(labelText: 'New Password (min 6 chars)', prefixIcon: Icon(Icons.lock_reset))),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _loading ? null : _change,
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Update Password', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700))),
      ])),
      const SizedBox(height: 16),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Account', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AttendifyTheme.primary.withValues(alpha: 0.15), AttendifyTheme.accent.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person, color: AttendifyTheme.primary, size: 20)),
          title: Text(widget.api.fullName, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
          subtitle: Text('@${widget.api.username}', style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary, fontSize: 12)),
        ),
        Container(height: 1, color: AttendifyTheme.divider.withValues(alpha: 0.3)),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
              color: AttendifyTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout, color: AttendifyTheme.error, size: 20)),
          title: Text('Sign Out', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
          onTap: widget.onLogout,
        ),
      ])),
    ]);
  }

  Future<void> _change() async {
    if (_currentPw.text.isEmpty || _newPw.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 6 characters')));
      return;
    }
    setState(() => _loading = true);
    final r = await widget.api.changePassword(_currentPw.text, _newPw.text);
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['_ok'] == true ? 'Password changed!' : 'Error: ${r['error'] ?? r['message']}')));
      if (r['_ok'] == true) { _currentPw.clear(); _newPw.clear(); }
    }
  }

  @override
  void dispose() { _currentPw.dispose(); _newPw.dispose(); super.dispose(); }
}
