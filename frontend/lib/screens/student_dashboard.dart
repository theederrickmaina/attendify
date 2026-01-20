import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../utils/api_service.dart';
import '../utils/ui.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _api = APIService();
  List<Map<String, dynamic>> _logs = [];
  int _present = 0;
  int _absent = 0;
  bool _loading = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await _api.getToken();
    if (token != null) {
      try {
        final payload = Jwt.parseJwt(token);
        _username = payload['username']?.toString() ?? '';
      } catch (_) {}
    }
    final res = await _api.studentAttendance();
    final logs = (res['logs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final summary = res['summary'] as Map<String, dynamic>? ?? {};
    setState(() {
      _logs = logs;
      _present = (summary['present'] as int?) ?? 0;
      _absent = (summary['absent'] as int?) ?? 0;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      PieChartSectionData(
        value: _present.toDouble(),
        title: 'Present',
        color: Colors.green,
      ),
      PieChartSectionData(
        value: _absent.toDouble(),
        title: 'Absent',
        color: Colors.red,
      ),
    ];

    return Scaffold(
      appBar: embuAppBar(
        'Student Dashboard${_username.isNotEmpty ? ' - $_username' : ''}',
      ),
      body: EmbuBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    NeumoCard(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: sections,
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0.0),
                    const SizedBox(height: 8),
                    ..._logs.map(
                      (e) => NeumoCard(
                        child: ListTile(
                          leading: Icon(
                            e['status'] == 'present'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: e['status'] == 'present'
                                ? Colors.green
                                : Colors.red,
                          ),
                          title: Text('Class ${e['class_id']}'),
                          subtitle: Text(e['timestamp']),
                          trailing: Text(
                            e['status'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ).animate().fadeIn().slideX(begin: 0.2, end: 0.0),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
