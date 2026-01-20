import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../utils/api_service.dart';
import '../utils/ui.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _api = APIService();
  bool _loading = true;
  int _total = 0;
  int _present = 0;
  int _absent = 0;
  Map<int, Map<String, int>> _byClass = {};
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
    final res = await _api.adminReports();
    setState(() {
      _loading = false;
      _total = (res['total_records'] as int?) ?? 0;
      _present = (res['present'] as int?) ?? 0;
      _absent = (res['absent'] as int?) ?? 0;
      final bc = res['by_class'] as Map<String, dynamic>? ?? {};
      _byClass = bc.map((k, v) {
        final mv = v as Map<String, dynamic>;
        return MapEntry(int.tryParse(k) ?? 0, {
          'present': (mv['present'] as int?) ?? 0,
          'absent': (mv['absent'] as int?) ?? 0,
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embuAppBar(
        'Admin Dashboard${_username.isNotEmpty ? ' - $_username' : ''}',
      ),
      body: EmbuBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        NeumoCard(
                          child: _StatCard(
                            label: 'Total',
                            value: _total.toString(),
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        NeumoCard(
                          child: _StatCard(
                            label: 'Present',
                            value: _present.toString(),
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        NeumoCard(
                          child: _StatCard(
                            label: 'Absent',
                            value: _absent.toString(),
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0.0),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: _byClass.entries
                            .map(
                              (e) => NeumoCard(
                                child: ListTile(
                                  title: Text('Class ${e.key}'),
                                  subtitle: Text(
                                    'Present: ${e.value['present']}  |  Absent: ${e.value['absent']}',
                                  ),
                                ),
                              ).animate().fadeIn(),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
