import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/lecturer/lecturer_shell.dart';
import 'screens/student/student_shell.dart';
import 'screens/kiosk/kiosk_screen.dart';

void main() {
  runApp(const AttendifyApp());
}

class AttendifyApp extends StatelessWidget {
  const AttendifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendify — Embu University',
      theme: AttendifyTheme.darkTheme,
      home: const AppRoot(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _api = ApiService();
  bool _ready = false;
  bool _kioskMode = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _api.init();
    // Check if device is in persistent kiosk mode
    final isKiosk = await _api.isKioskMode();
    if (isKiosk) {
      // Re-authenticate to get a fresh token
      final ok = await _api.refreshKioskSession();
      if (ok) _kioskMode = true;
    }
    if (mounted) setState(() => _ready = true);
  }

  void _logout() async {
    await _api.clearToken();
    setState(() {});
  }

  void _enterKiosk() => setState(() => _kioskMode = true);

  void _exitKiosk() async {
    await _api.deactivateKioskMode();
    setState(() => _kioskMode = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AttendifyTheme.primary)),
      );
    }

    // Kiosk mode — full-screen face scanning
    if (_kioskMode) {
      return KioskScreen(
        api: _api,
        onExitKiosk: _exitKiosk,
      );
    }

    // Not logged in — show login
    if (!_api.isLoggedIn) {
      return LoginScreen(
        api: _api,
        onLoggedIn: () => setState(() {}),
        onKioskActivated: _enterKiosk,
      );
    }

    // Route by role
    switch (_api.role) {
      case 'superadmin':
        return AdminShell(api: _api, onLogout: _logout);
      case 'lecturer':
        return LecturerShell(api: _api, onLogout: _logout);
      case 'student':
        return StudentShell(api: _api, onLogout: _logout);
      default:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AttendifyTheme.error),
                const SizedBox(height: 16),
                Text('Unknown role: ${_api.role}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _logout, child: const Text('Logout')),
              ],
            ),
          ),
        );
    }
  }
}
