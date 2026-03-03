import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final ApiService api;
  const AdminDashboardScreen({super.key, required this.api});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await widget.api.getAdminDashboard();
      if (r['_ok'] == true) setState(() => _data = r);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AttendifyTheme.primary));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AttendifyTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Welcome back,', style: GoogleFonts.spaceGrotesk(fontSize: 14, color: AttendifyTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(widget.api.fullName, style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          NeonChip(label: 'COMMAND CENTER', color: AttendifyTheme.primary),
          const SizedBox(height: 24),
          _statsGrid(),
          const SizedBox(height: 24),
          _metricsCard(),
        ],
      ),
    );
  }

  Widget _statsGrid() {
    final stats = [
      ('Students', '${_data['students'] ?? 0}', Icons.school_rounded, AttendifyTheme.primary),
      ('Face IDs', '${_data['enrolled_faces'] ?? 0}', Icons.face_rounded, AttendifyTheme.accent),
      ('Lecturers', '${_data['lecturers'] ?? 0}', Icons.person_rounded, AttendifyTheme.accentPink),
      ('Departments', '${_data['departments'] ?? 0}', Icons.business_rounded, const Color(0xFF9C27B0)),
      ('Courses', '${_data['courses'] ?? 0}', Icons.menu_book_rounded, const Color(0xFF2196F3)),
      ('Units', '${_data['units'] ?? 0}', Icons.auto_stories_rounded, const Color(0xFFE91E63)),
      ('Devices', '${_data['active_devices'] ?? 0}', Icons.devices_rounded, const Color(0xFF00BCD4)),
      ('Today Attendance', '${_data['today_attendance'] ?? 0}', Icons.check_circle_rounded, AttendifyTheme.success),
    ];

    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 600 ? 3 : 2;
      return Wrap(
        spacing: 12, runSpacing: 12,
        children: stats.map((s) {
          final w = (constraints.maxWidth - (cols - 1) * 12) / cols;
          return SizedBox(width: w, child: StatCard(
            title: s.$1, value: s.$2, icon: s.$3, color: s.$4));
        }).toList(),
      );
    });
  }

  Widget _metricsCard() {
    final m = (_data['metrics'] as Map<String, dynamic>?) ?? {};
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RECOGNITION METRICS', style: GoogleFonts.orbitron(fontSize: 11, color: AttendifyTheme.accent, letterSpacing: 2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _metricRow('Total Attempts', '${m['total_attempts'] ?? 0}'),
          _metricRow('Successful Matches', '${m['successful_matches'] ?? 0}'),
          _metricRow('Failed Matches', '${m['failed_matches'] ?? 0}'),
          _metricRow('Low Quality Rejects', '${m['low_quality_rejects'] ?? 0}'),
          _metricRow('Liveness Failures', '${m['liveness_failures'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary, fontSize: 13)),
          Text(value, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}
