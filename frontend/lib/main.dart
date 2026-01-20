import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/enrollment.dart';
import 'screens/recognition.dart';
import 'screens/student_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/consent.dart';
import 'utils/api_service.dart';
import 'utils/secure_store.dart';
import 'package:jwt_decode/jwt_decode.dart';

/// Attendify Flutter Frontend
/// --------------------------
/// To run: `flutter run`
///
/// Configures the MaterialApp with University of Embu theme colors
/// and Roboto font. Pages and navigation will be added in subsequent steps.
void main() {
  runApp(const AttendifyApp());
}

class AttendifyApp extends StatelessWidget {
  const AttendifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF006400); // #006400
    const Color secondaryNavy = Color(0xFF003366); // #003366

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
    ).copyWith(secondary: secondaryNavy);

    final ThemeData theme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: scheme,
      primaryColor: primaryGreen,
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primaryGreen,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? Colors.white : secondaryNavy);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(color: selected ? Colors.white : secondaryNavy);
        }),
        backgroundColor: const Color(0xFFEFF7EF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: secondaryNavy),
      ),
    );

    return MaterialApp(
      title: 'Attendify',
      theme: theme,
      home: const RootShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// RootShell manages auth then shows bottom navigation.
class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final _api = APIService();
  final _store = SecureStore();
  String? _token;
  int _tab = 0;
  bool _adminMode = true; // demo: admin by default after login sample
  bool _consentAccepted = false;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadConsent();
  }

  Future<void> _loadToken() async {
    final t = await _api.getToken();
    setState(() {
      _token = t;
      _updateRoleFromToken();
    });
  }

  Future<void> _loadConsent() async {
    final c = await _store.getConsentAccepted();
    setState(() => _consentAccepted = c);
  }

  void _onLoggedIn() async {
    final t = await _api.getToken();
    setState(() {
      _token = t;
      _updateRoleFromToken();
    });
  }

  void _logout() async {
    await _api.clearToken();
    setState(() => _token = null);
  }

  void _updateRoleFromToken() {
    if (_token == null) return;
    try {
      final Map<String, dynamic> payload = Jwt.parseJwt(_token!);
      final role = payload['role']?.toString();
      _adminMode = role == 'admin';
    } catch (_) {
      _adminMode = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_consentAccepted) {
      return ConsentScreen(
        onAccepted: () async {
          await _store.setConsentAccepted(true);
          setState(() => _consentAccepted = true);
        },
      );
    }
    if (_token == null) {
      return LoginScreen(onLoggedIn: _onLoggedIn);
    }
    final pages = [
      const EnrollmentScreen(),
      const RecognitionScreen(),
      _adminMode ? const AdminDashboard() : const StudentDashboard(),
      const SizedBox.shrink(),
    ];
    return Scaffold(
      body: pages[_tab],
      floatingActionButton: _adminMode
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() => _adminMode = !_adminMode);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_adminMode ? 'Admin view' : 'Student view'),
                  ),
                );
              },
              icon: const Icon(Icons.swap_horiz),
              label: Text(_adminMode ? 'Admin' : 'Student'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          if (i == 3) {
            _logout();
          } else {
            setState(() => _tab = i);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_add_alt),
            label: 'Enroll',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.logout), label: 'Logout'),
        ],
      ),
    );
  }
}
