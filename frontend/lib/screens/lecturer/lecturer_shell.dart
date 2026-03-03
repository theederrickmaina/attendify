import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class LecturerShell extends StatefulWidget {
  final ApiService api;
  final VoidCallback onLogout;
  const LecturerShell({super.key, required this.api, required this.onLogout});
  @override State<LecturerShell> createState() => _LecturerShellState();
}

class _LecturerShellState extends State<LecturerShell> {
  int _tab = 0;
  static const _navItems = [
    (icon: Icons.dashboard_rounded, label: 'Dashboard'),
    (icon: Icons.auto_stories_rounded, label: 'My Units'),
    (icon: Icons.calendar_month_rounded, label: 'Sessions'),
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
        backgroundColor: AttendifyTheme.surface, surfaceTintColor: Colors.transparent,
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
              gradient: LinearGradient(colors: [AttendifyTheme.accent.withValues(alpha: 0.15), AttendifyTheme.primary.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: AttendifyTheme.accent.withValues(alpha: 0.08), blurRadius: 12)],
            ),
            child: const Icon(Icons.school_rounded, color: AttendifyTheme.accent, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GradientText('ATTENDIFY', style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w800)),
            Text('LECTURER PORTAL', style: GoogleFonts.spaceGrotesk(fontSize: 9, color: AttendifyTheme.textSecondary, letterSpacing: 2)),
          ]),
        ])),
        const SizedBox(height: 32),
        ...List.generate(_navItems.length, (i) {
          final item = _navItems[i];
          final sel = _tab == i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Material(
              color: sel ? AttendifyTheme.accent.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _tab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: sel ? BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AttendifyTheme.accent.withValues(alpha: 0.15)),
                  ) : null,
                  child: Row(children: [
                    Icon(item.icon, size: 19, color: sel ? AttendifyTheme.accent : AttendifyTheme.textSecondary),
                    const SizedBox(width: 12),
                    Text(item.label, style: GoogleFonts.spaceGrotesk(fontSize: 13,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? AttendifyTheme.accent : AttendifyTheme.textSecondary)),
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
                gradient: LinearGradient(colors: [AttendifyTheme.accent.withValues(alpha: 0.2), AttendifyTheme.primary.withValues(alpha: 0.1)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, size: 16, color: AttendifyTheme.accent),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.api.fullName, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              Text('Lecturer', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AttendifyTheme.textSecondary)),
            ])),
            IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout, size: 16, color: AttendifyTheme.error)),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case 0: return _LecturerDashboard(api: widget.api);
      case 1: return _MyUnitsScreen(api: widget.api);
      case 2: return _SessionsScreen(api: widget.api);
      case 3: return _SettingsScreen(api: widget.api, onLogout: widget.onLogout);
      default: return _LecturerDashboard(api: widget.api);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  LECTURER DASHBOARD — with bar chart analytics + today's sessions
// ═══════════════════════════════════════════════════════════════════════════
class _LecturerDashboard extends StatefulWidget {
  final ApiService api;
  const _LecturerDashboard({required this.api});
  @override State<_LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<_LecturerDashboard> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await widget.api.getLecturerDashboard();
      if (r['_ok'] == true) _data = r;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(String? s) => switch (s) {
    'active' => AttendifyTheme.success,
    'completed' => AttendifyTheme.accent,
    'cancelled' => AttendifyTheme.error,
    _ => AttendifyTheme.warning,
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AttendifyTheme.primary));
    final units = (_data['units'] as List?) ?? [];
    final todaySessions = (_data['today_sessions'] as List?) ?? [];
    final totalSessions = _data['total_sessions'] ?? 0;

    // Build bar chart data from units
    final barGroups = <BarChartGroupData>[];
    final unitNames = <String>[];
    for (var i = 0; i < units.length && i < 8; i++) {
      final u = units[i] as Map<String, dynamic>;
      unitNames.add(u['unit_code'] ?? 'U${i + 1}');
      final sessions = (u['total_sessions'] ?? 0).toDouble();
      barGroups.add(BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: sessions > 0 ? sessions : 0.5,
          width: 18,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [AttendifyTheme.accent.withValues(alpha: 0.6), AttendifyTheme.primary]),
        ),
      ]));
    }

    return RefreshIndicator(
      onRefresh: _load, color: AttendifyTheme.primary,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        // Greeting
        Text('Welcome back,', style: GoogleFonts.spaceGrotesk(fontSize: 14, color: AttendifyTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(widget.api.fullName, style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        NeonChip(label: 'LECTURER DASHBOARD', color: AttendifyTheme.accent),
        const SizedBox(height: 24),

        // Stats
        LayoutBuilder(builder: (_, c) {
          final cols = c.maxWidth > 600 ? 3 : 2;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(width: w, child: StatCard(title: 'My Units', value: '${units.length}', icon: Icons.auto_stories_rounded, color: AttendifyTheme.accent)),
            SizedBox(width: w, child: StatCard(title: 'Today', value: '${todaySessions.length}', icon: Icons.today_rounded, color: AttendifyTheme.primary)),
            SizedBox(width: w, child: StatCard(title: 'Total Sessions', value: '$totalSessions', icon: Icons.calendar_month_rounded, color: AttendifyTheme.accentPink)),
          ]);
        }),

        // Bar chart — sessions per unit
        if (barGroups.isNotEmpty) ...[
          const SizedBox(height: 24),
          GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SESSIONS PER UNIT', style: GoogleFonts.orbitron(fontSize: 11, color: AttendifyTheme.accent, letterSpacing: 2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: barGroups.fold<double>(0, (m, g) => g.barRods.first.toY > m ? g.barRods.first.toY : m) + 2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gIdx, rod, rIdx) {
                      final name = gIdx < unitNames.length ? unitNames[gIdx] : '';
                      return BarTooltipItem('$name\n${rod.toY.toInt()} sessions',
                          GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600));
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32,
                      getTitlesWidget: (v, meta) {
                        final idx = v.toInt();
                        return SideTitleWidget(meta: meta,
                          child: Text(idx < unitNames.length ? unitNames[idx] : '',
                              style: GoogleFonts.spaceGrotesk(fontSize: 9, color: AttendifyTheme.textSecondary)));
                      })),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                      getTitlesWidget: (v, meta) => Text('${v.toInt()}',
                          style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AttendifyTheme.textSecondary)))),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(color: AttendifyTheme.divider.withValues(alpha: 0.3), strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              )),
            ),
          ])),
        ],

        // Today's sessions
        if (todaySessions.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text("TODAY'S SESSIONS", style: GoogleFonts.orbitron(fontSize: 11, color: AttendifyTheme.primary, letterSpacing: 2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...todaySessions.map((s) {
            final sc = _statusColor(s['status']);
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 8), glowColor: sc.withValues(alpha: 0.15),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: sc.withValues(alpha: 0.08), blurRadius: 8)]),
                    child: Icon(Icons.access_time_rounded, color: sc, size: 20)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s['unit_name'] ?? '', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
                  Text('${s['start_time']?.toString().substring(0, 5) ?? ''} — ${s['end_time']?.toString().substring(0, 5) ?? ''}  ·  ${s['venue'] ?? ''}',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AttendifyTheme.textSecondary)),
                ])),
                NeonChip(label: (s['status'] ?? '').toString().toUpperCase(), color: sc),
              ]),
            );
          }),
        ],

        // Units overview
        if (units.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('UNIT OVERVIEW', style: GoogleFonts.orbitron(fontSize: 11, color: AttendifyTheme.accent, letterSpacing: 2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...units.map((u) {
            final uu = u as Map<String, dynamic>;
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AttendifyTheme.accent.withValues(alpha: 0.15), AttendifyTheme.accent.withValues(alpha: 0.05)]),
                    borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.auto_stories_rounded, color: AttendifyTheme.accent, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(uu['unit_name'] ?? '', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${uu['unit_code'] ?? ''}  ·  ${uu['academic_year'] ?? ''}',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AttendifyTheme.textSecondary)),
                ])),
                Text('${uu['total_sessions'] ?? 0}', style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w700, color: AttendifyTheme.primary)),
                Text(' sess', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AttendifyTheme.textSecondary)),
              ]),
            );
          }),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MY UNITS
// ═══════════════════════════════════════════════════════════════════════════
class _MyUnitsScreen extends StatefulWidget {
  final ApiService api;
  const _MyUnitsScreen({required this.api});
  @override State<_MyUnitsScreen> createState() => _MyUnitsScreenState();
}

class _MyUnitsScreenState extends State<_MyUnitsScreen> {
  List<dynamic> _units = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await widget.api.getLecturerMyUnits();
    if (r['_ok'] == true) _units = r['units'] ?? [];
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AttendifyTheme.primary));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('My Units', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('${_units.length} units assigned', style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary, fontSize: 12)),
      const SizedBox(height: 16),
      if (_units.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_stories_rounded, size: 48, color: AttendifyTheme.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No units assigned', style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary)),
        ]))),
      ..._units.map((u) => GlassCard(
        margin: const EdgeInsets.only(bottom: 10), glowColor: AttendifyTheme.accent.withValues(alpha: 0.15),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AttendifyTheme.accent.withValues(alpha: 0.15), AttendifyTheme.accent.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AttendifyTheme.accent.withValues(alpha: 0.08), blurRadius: 8)]),
              child: const Icon(Icons.auto_stories_rounded, color: AttendifyTheme.accent, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u['unit_name'] ?? '', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text('${u['unit_code'] ?? ''}  ·  ${u['academic_year'] ?? ''}',
                style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AttendifyTheme.textSecondary)),
          ])),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AttendifyTheme.accent.withValues(alpha: 0.1), blurRadius: 8)]),
            child: TextButton.icon(
              onPressed: () => _viewStudents(u),
              icon: const Icon(Icons.people_rounded, size: 16),
              label: Text('Students', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
        ]),
      )),
    ]);
  }

  void _viewStudents(Map<String, dynamic> unit) async {
    final unitId = unit['unit_id'];
    if (unitId == null) return;
    final r = await widget.api.getUnitStudents(unitId);
    if (!mounted) return;
    final students = (r['students'] as List?) ?? [];
    final totalSessions = r['total_sessions'] ?? 0;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
            color: AttendifyTheme.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.people_rounded, color: AttendifyTheme.accent, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Text('${unit['unit_name']} — Students', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16))),
      ]),
      content: SizedBox(width: 500, height: 400,
        child: students.isEmpty
            ? Center(child: Text('No students enrolled', style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary)))
            : ListView.builder(itemCount: students.length, itemBuilder: (_, i) {
                final s = students[i] as Map<String, dynamic>;
                final rate = ((s['attendance_rate'] ?? 0) * 100).toStringAsFixed(0);
                final rateVal = int.tryParse(rate) ?? 0;
                final rc = rateVal >= 75 ? AttendifyTheme.success : rateVal >= 50 ? AttendifyTheme.warning : AttendifyTheme.error;
                return ListTile(
                  leading: Container(width: 32, height: 32, alignment: Alignment.center,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AttendifyTheme.accent.withValues(alpha: 0.15), AttendifyTheme.accent.withValues(alpha: 0.05)]),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('${i + 1}', style: GoogleFonts.orbitron(fontSize: 11, color: AttendifyTheme.accent, fontWeight: FontWeight.w700))),
                  title: Text(s['name'] ?? '', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Text('${s['registration_number']}  ·  ${s['sessions_attended']}/$totalSessions',
                      style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AttendifyTheme.textSecondary)),
                  trailing: ShaderMask(
                    shaderCallback: (b) => LinearGradient(colors: [rc, rc.withValues(alpha: 0.7)]).createShader(b),
                    child: Text('$rate%', style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                );
              }),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SESSIONS
// ═══════════════════════════════════════════════════════════════════════════
class _SessionsScreen extends StatefulWidget {
  final ApiService api;
  const _SessionsScreen({required this.api});
  @override State<_SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<_SessionsScreen> {
  List<dynamic> _sessions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await widget.api.getLecturerSessions();
    if (r['_ok'] == true) _sessions = r['sessions'] ?? [];
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(String? s) => switch (s) {
    'active' => AttendifyTheme.success,
    'completed' => AttendifyTheme.accent,
    'cancelled' => AttendifyTheme.error,
    _ => AttendifyTheme.warning,
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AttendifyTheme.primary));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Class Sessions', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${_sessions.length} sessions total', style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary, fontSize: 12)),
        ])),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AttendifyTheme.accent.withValues(alpha: 0.15), blurRadius: 12)]),
          child: ElevatedButton.icon(onPressed: _showCreate,
              icon: const Icon(Icons.add, size: 18), label: const Text('New Session')),
        ),
      ]),
      const SizedBox(height: 16),
      if (_sessions.isEmpty)
        Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_month_rounded, size: 48, color: AttendifyTheme.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No sessions yet', style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary)),
        ]))),
      ..._sessions.map((s) {
        final sc = _statusColor(s['status']);
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 8), glowColor: sc.withValues(alpha: 0.1),
          child: Column(children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: sc.withValues(alpha: 0.08), blurRadius: 8)]),
                  child: Icon(Icons.event_rounded, color: sc, size: 20)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['unit_name'] ?? '', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${s['session_date']}  ·  ${s['start_time']?.toString().substring(0, 5) ?? ''}-${s['end_time']?.toString().substring(0, 5) ?? ''}  ·  ${s['venue'] ?? ''}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AttendifyTheme.textSecondary)),
              ])),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${s['attendance_count'] ?? 0}', style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w700, color: AttendifyTheme.primary)),
                const SizedBox(width: 4),
                const Icon(Icons.people_rounded, size: 14, color: AttendifyTheme.textSecondary),
              ]),
              const SizedBox(width: 12),
              NeonChip(label: (s['status'] ?? '').toString().toUpperCase(), color: sc),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton.icon(
                onPressed: () => _showEditSession(s),
                icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                label: Text('Reschedule', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: AttendifyTheme.accent),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _confirmDeleteSession(s),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text('Delete', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(foregroundColor: AttendifyTheme.error),
              ),
            ]),
          ]),
        );
      }),
    ]);
  }

  void _showCreate() async {
    final unitsRes = await widget.api.getLecturerMyUnits();
    final myUnits = (unitsRes['units'] as List?) ?? [];
    if (!mounted) return;

    int? selectedUnitId;
    final dateCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    bool creating = false;
    String? createError;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
              color: AttendifyTheme.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_circle_rounded, color: AttendifyTheme.accent, size: 20)),
          const SizedBox(width: 12),
          Text('Create Session', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
        ]),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Unit'),
            items: myUnits.map<DropdownMenuItem<int>>((u) =>
              DropdownMenuItem(value: u['unit_id'] as int,
                child: Text('${u['unit_code']} — ${u['unit_name']}', style: GoogleFonts.spaceGrotesk(fontSize: 13)))).toList(),
            onChanged: (v) => selectedUnitId = v,
          ),
          const SizedBox(height: 12),
          TextField(controller: dateCtrl,
            decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', prefixIcon: Icon(Icons.calendar_today)),
            onTap: () async {
              final d = await showDatePicker(context: ctx,
                  initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) dateCtrl.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            }, readOnly: true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: startCtrl,
                decoration: const InputDecoration(labelText: 'Start (HH:MM)'),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 8, minute: 0));
                  if (t != null) startCtrl.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                }, readOnly: true)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: endCtrl,
                decoration: const InputDecoration(labelText: 'End (HH:MM)'),
                onTap: () async {
                  final t = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 10, minute: 0));
                  if (t != null) endCtrl.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                }, readOnly: true)),
          ]),
          const SizedBox(height: 12),
          TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'Venue', prefixIcon: Icon(Icons.location_on))),
          if (createError != null) ...[
            const SizedBox(height: 12),
            Text(createError!, style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.error, fontSize: 12)),
          ],
        ])),
        actions: [
          TextButton(onPressed: creating ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: creating ? null : () async {
              if (selectedUnitId == null || dateCtrl.text.isEmpty || startCtrl.text.isEmpty || endCtrl.text.isEmpty) {
                setDialogState(() => createError = 'Fill in all required fields');
                return;
              }
              setDialogState(() { creating = true; createError = null; });
              final r = await widget.api.createSession({
                'unit_id': selectedUnitId,
                'session_date': dateCtrl.text,
                'start_time': startCtrl.text,
                'end_time': endCtrl.text,
                'venue': venueCtrl.text,
              });
              if (r['_ok'] == true) { if (ctx.mounted) Navigator.pop(ctx); _load(); }
              else { setDialogState(() { creating = false; createError = r['error'] ?? 'Failed to create session'; }); }
            },
            child: creating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text('Create', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ));
  }

  // ── Edit / Reschedule Session ──
  void _showEditSession(Map<String, dynamic> s) {
    final dateCtrl = TextEditingController(text: s['session_date'] ?? '');
    final startCtrl = TextEditingController(text: (s['start_time'] ?? '').toString().substring(0, 5));
    final endCtrl = TextEditingController(text: (s['end_time'] ?? '').toString().substring(0, 5));
    final venueCtrl = TextEditingController(text: s['venue'] ?? '');
    String status = s['status'] ?? 'scheduled';
    bool saving = false;
    String? saveError;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
              color: AttendifyTheme.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit_calendar_rounded, color: AttendifyTheme.accent, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Edit Session', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
            Text(s['unit_name'] ?? '', style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AttendifyTheme.textSecondary)),
          ])),
        ]),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.flag)),
            initialValue: status,
            items: const [
              DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
            onChanged: (v) => status = v ?? status,
          ),
          const SizedBox(height: 12),
          TextField(controller: dateCtrl,
            decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', prefixIcon: Icon(Icons.calendar_today)),
            onTap: () async {
              final initial = DateTime.tryParse(dateCtrl.text) ?? DateTime.now();
              final d = await showDatePicker(context: ctx,
                  initialDate: initial, firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) dateCtrl.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            }, readOnly: true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: startCtrl,
                decoration: const InputDecoration(labelText: 'Start (HH:MM)'),
                onTap: () async {
                  final parts = startCtrl.text.split(':');
                  final init = TimeOfDay(hour: int.tryParse(parts.firstOrNull ?? '') ?? 8, minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0);
                  final t = await showTimePicker(context: ctx, initialTime: init);
                  if (t != null) startCtrl.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                }, readOnly: true)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: endCtrl,
                decoration: const InputDecoration(labelText: 'End (HH:MM)'),
                onTap: () async {
                  final parts = endCtrl.text.split(':');
                  final init = TimeOfDay(hour: int.tryParse(parts.firstOrNull ?? '') ?? 10, minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0);
                  final t = await showTimePicker(context: ctx, initialTime: init);
                  if (t != null) endCtrl.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                }, readOnly: true)),
          ]),
          const SizedBox(height: 12),
          TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: 'Venue', prefixIcon: Icon(Icons.location_on))),
          if (saveError != null) ...[
            const SizedBox(height: 12),
            Text(saveError!, style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.error, fontSize: 12)),
          ],
        ])),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: saving ? null : () async {
              if (dateCtrl.text.isEmpty || startCtrl.text.isEmpty || endCtrl.text.isEmpty) {
                setDialogState(() => saveError = 'Date and time fields are required');
                return;
              }
              setDialogState(() { saving = true; saveError = null; });
              final r = await widget.api.updateSession(s['id'], {
                'session_date': dateCtrl.text,
                'start_time': startCtrl.text,
                'end_time': endCtrl.text,
                'venue': venueCtrl.text,
                'status': status,
              });
              if (r['_ok'] == true) { if (ctx.mounted) Navigator.pop(ctx); _load(); }
              else { setDialogState(() { saving = false; saveError = r['error'] ?? 'Failed to update session'; }); }
            },
            child: saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text('Save', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ));
  }

  // ── Delete Session ──
  void _confirmDeleteSession(Map<String, dynamic> s) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Session?'),
      content: Text('Delete the ${s['unit_name']} session on ${s['session_date']}?\nThis cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AttendifyTheme.error),
          onPressed: () async {
            final r = await widget.api.deleteSession(s['id']);
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
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SETTINGS
// ═══════════════════════════════════════════════════════════════════════════
class _SettingsScreen extends StatefulWidget {
  final ApiService api;
  final VoidCallback onLogout;
  const _SettingsScreen({required this.api, required this.onLogout});
  @override State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
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
        ElevatedButton(onPressed: _loading ? null : _changePassword,
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Update Password', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700))),
      ])),
      const SizedBox(height: 16),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Account', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AttendifyTheme.accent.withValues(alpha: 0.15), AttendifyTheme.primary.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person, color: AttendifyTheme.accent, size: 20)),
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

  Future<void> _changePassword() async {
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
