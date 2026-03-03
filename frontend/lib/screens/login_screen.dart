import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final ApiService api;
  final VoidCallback onLoggedIn;
  final VoidCallback? onKioskActivated;

  const LoginScreen({super.key, required this.api, required this.onLoggedIn, this.onKioskActivated});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  void _showKioskSetup() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String? kioskError;
    bool kioskLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AttendifyTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AttendifyTheme.accent.withValues(alpha: 0.1), blurRadius: 12)],
              ),
              child: const Icon(Icons.tv, color: AttendifyTheme.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Kiosk Setup', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
          ]),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AttendifyTheme.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AttendifyTheme.accent.withValues(alpha: 0.15)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: AttendifyTheme.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Enter admin credentials to activate this device as an attendance kiosk.',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AttendifyTheme.textSecondary),
                    )),
                  ]),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Admin Username',
                    prefixIcon: Icon(Icons.admin_panel_settings),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Admin Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (kioskError != null) ...[
                  const SizedBox(height: 12),
                  Text(kioskError!, style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.error, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: kioskLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: kioskLoading ? null : () async {
                final u = userCtrl.text.trim();
                final p = passCtrl.text;
                if (u.isEmpty || p.isEmpty) {
                  setDialogState(() => kioskError = 'Enter both username and password');
                  return;
                }
                setDialogState(() { kioskLoading = true; kioskError = null; });
                try {
                  final r = await widget.api.activateKioskMode(u, p);
                  if (r['_ok'] == true) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    widget.onKioskActivated?.call();
                  } else {
                    setDialogState(() {
                      kioskError = r['error'] == 'invalid_credentials'
                          ? 'Invalid credentials' : 'Login failed';
                    });
                  }
                } catch (e) {
                  setDialogState(() => kioskError = 'Connection error');
                } finally {
                  if (ctx.mounted) setDialogState(() => kioskLoading = false);
                }
              },
              icon: kioskLoading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.tv, size: 18),
              label: const Text('Activate Kiosk'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    final u = _usernameCtrl.text.trim();
    final p = _passwordCtrl.text;
    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = 'Please enter username and password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final r = await widget.api.login(u, p);
      if (r['_ok'] == true) {
        widget.onLoggedIn();
      } else {
        setState(() => _error = r['error'] == 'invalid_credentials'
            ? 'Invalid username or password'
            : r['error'] == 'account_disabled'
            ? 'Account is disabled. Contact admin.'
            : 'Login failed');
      }
    } catch (e) {
      setState(() => _error = 'Connection error. Is the server running?');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      body: ParticleBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: wide ? _wideLayout() : _narrowLayout(),
          ),
        ),
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _branding().animate().fadeIn(duration: 800.ms).slideX(begin: -0.08),
        const SizedBox(width: 80),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 420, child: _loginCard()),
            const SizedBox(height: 16),
            _kioskSetupButton(),
          ],
        ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideX(begin: 0.08),
      ],
    );
  }

  Widget _narrowLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _brandingCompact().animate().fadeIn(duration: 600.ms),
        const SizedBox(height: 36),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _loginCard(),
        ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.04),
        const SizedBox(height: 16),
        _kioskSetupButton().animate().fadeIn(duration: 600.ms, delay: 400.ms),
      ],
    );
  }

  Widget _branding() {
    return SizedBox(
      width: 380,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glowing icon
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AttendifyTheme.primary.withValues(alpha: 0.15),
                  AttendifyTheme.accent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: AttendifyTheme.primary.withValues(alpha: 0.15), blurRadius: 30),
              ],
            ),
            child: const Icon(Icons.face_retouching_natural,
                size: 52, color: AttendifyTheme.primary),
          ),
          const SizedBox(height: 28),
          // Gradient title
          GradientText('ATTENDIFY',
            style: GoogleFonts.orbitron(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const SizedBox(height: 10),
          Text('EMBU UNIVERSITY',
            style: GoogleFonts.spaceGrotesk(fontSize: 16, color: AttendifyTheme.accent,
                fontWeight: FontWeight.w600, letterSpacing: 4)),
          const SizedBox(height: 20),
          // Feature badges
          Row(children: [
            _featureBadge(Icons.face, 'AI Recognition'),
            const SizedBox(width: 8),
            _featureBadge(Icons.bolt, 'Real-time'),
            const SizedBox(width: 8),
            _featureBadge(Icons.shield, 'Secure'),
          ]),
          const SizedBox(height: 20),
          Text(
            'Next-generation facial recognition attendance system. '
            'Fast, secure, and intelligent.',
            style: GoogleFonts.spaceGrotesk(fontSize: 14, color: AttendifyTheme.textSecondary,
                height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _featureBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AttendifyTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AttendifyTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AttendifyTheme.primary),
        const SizedBox(width: 5),
        Text(text, style: GoogleFonts.spaceGrotesk(
          fontSize: 11, color: AttendifyTheme.primary, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _brandingCompact() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AttendifyTheme.primary.withValues(alpha: 0.12),
                AttendifyTheme.accent.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: AttendifyTheme.primary.withValues(alpha: 0.12), blurRadius: 24),
            ],
          ),
          child: const Icon(Icons.face_retouching_natural,
              size: 42, color: AttendifyTheme.primary),
        ),
        const SizedBox(height: 14),
        GradientText('ATTENDIFY',
          style: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 3)),
        const SizedBox(height: 4),
        Text('EMBU UNIVERSITY',
          style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AttendifyTheme.accent,
              fontWeight: FontWeight.w600, letterSpacing: 3)),
      ],
    );
  }

  Widget _loginCard() {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sign In',
            style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700,
                color: AttendifyTheme.textPrimary)),
          const SizedBox(height: 6),
          Text('Enter your credentials to access the system',
            style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 28),
          TextField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    size: 20, color: AttendifyTheme.textSecondary),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _login(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AttendifyTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AttendifyTheme.error.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Icon(Icons.error_outline, color: AttendifyTheme.error.withValues(alpha: 0.8), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.error, fontSize: 13))),
              ]),
            ),
          ],
          const SizedBox(height: 26),
          // Glowing sign-in button
          Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AttendifyTheme.primary.withValues(alpha: _loading ? 0.0 : 0.25),
                  blurRadius: 16, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF050510)))
                  : Text('SIGN IN', style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 2)),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text('v3.0  ·  AI-Powered Attendance',
              style: GoogleFonts.spaceGrotesk(fontSize: 10,
                  color: AttendifyTheme.textSecondary.withValues(alpha: 0.4), letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _kioskSetupButton() {
    if (widget.onKioskActivated == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AttendifyTheme.accent.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        onTap: _showKioskSetup,
        borderRadius: BorderRadius.circular(10),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.tv, size: 16, color: AttendifyTheme.accent.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Text('Set Up as Kiosk Device',
              style: GoogleFonts.spaceGrotesk(
                color: AttendifyTheme.accent.withValues(alpha: 0.7), fontSize: 12,
                fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}
