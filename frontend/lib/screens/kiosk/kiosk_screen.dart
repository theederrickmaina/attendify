import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/capture_service.dart';
import '../../widgets/face_scan_painter.dart';

class KioskScreen extends StatefulWidget {
  final ApiService api;
  final VoidCallback onExitKiosk;

  const KioskScreen({super.key, required this.api, required this.onExitKiosk});

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> with TickerProviderStateMixin {
  String _status = 'initializing';
  Map<String, dynamic>? _matchedStudent;
  double _similarity = 0;
  String? _attendanceStatus;
  List<dynamic> _markedSessions = [];
  List<dynamic> _skippedSessions = [];
  String? _errorMsg;
  Timer? _resetTimer;

  CaptureService? _camera;
  bool _cameraReady = false;

  String _timeStr = '';
  String _dateStr = '';
  Timer? _clockTimer;

  // Animations
  late AnimationController _scanLineCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _statusCtrl;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());

    _scanLineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _statusCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _initCamera();
  }

  void _updateClock() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    final months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    if (mounted) setState(() {
      _timeStr = '$h:$m:$s';
      _dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
    });
  }

  Future<void> _initCamera() async {
    try {
      _camera = CaptureService();
      final ok = await _camera!.startLiveCamera();
      if (!ok) throw Exception('Camera init failed');
      if (mounted) setState(() { _cameraReady = true; _status = 'ready'; });
    } catch (e) {
      if (mounted) setState(() { _status = 'error'; _errorMsg = 'Camera access denied or unavailable.'; });
    }
  }

  void _resetAfterDelay() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() {
        _status = 'ready'; _matchedStudent = null; _similarity = 0;
        _attendanceStatus = null; _errorMsg = null;
      });
    });
  }

  Future<void> _scanFace() async {
    if (_camera == null || !_cameraReady) return;
    setState(() { _status = 'scanning'; _errorMsg = null; _matchedStudent = null; });
    _statusCtrl.forward(from: 0);

    final dataUrl = await _camera!.captureLiveSnapshot();
    if (dataUrl == null) {
      setState(() { _status = 'error'; _errorMsg = 'Failed to capture frame'; });
      _resetAfterDelay(); return;
    }

    try {
      final r = await widget.api.recognize(dataUrl, autoMark: true);
      if (!mounted) return;
      if (r['status'] == 'matched') {
        final student = r['student'] as Map<String, dynamic>? ?? {};
        final att = r['attendance'] as Map<String, dynamic>?;
        final marked = (att?['marked'] as List?) ?? [];
        final skipped = (att?['skipped'] as List?) ?? [];
        setState(() {
          _status = 'matched'; _matchedStudent = student;
          _similarity = (r['similarity'] ?? 0).toDouble();
          _markedSessions = marked; _skippedSessions = skipped;
          if (marked.isNotEmpty) {
            _attendanceStatus = marked.first['status'] ?? 'present';
          } else if (skipped.any((s) => s['reason'] == 'already_marked')) {
            _attendanceStatus = 'already_marked';
          } else {
            _attendanceStatus = 'no_session';
          }
        });
      } else if (r['status'] == 'no_match') {
        setState(() { _status = 'no_match'; _errorMsg = r['message'] ?? 'Face not recognized'; });
      } else {
        setState(() { _status = r['_ok'] == true ? 'no_match' : 'error'; _errorMsg = r['message'] ?? r['error'] ?? 'Recognition failed'; });
      }
    } catch (e) {
      if (mounted) setState(() { _status = 'error'; _errorMsg = 'Connection error'; });
    }
    _statusCtrl.forward(from: 0);
    _resetAfterDelay();
  }

  void _showExitDialog() {
    final passCtrl = TextEditingController();
    String? exitError;
    bool exitLoading = false;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AttendifyTheme.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AttendifyTheme.warning.withValues(alpha: 0.1), blurRadius: 12)],
              ),
              child: const Icon(Icons.lock_outline, color: AttendifyTheme.warning, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Admin Authentication', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
          ]),
          content: SizedBox(width: 320, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AttendifyTheme.warning.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AttendifyTheme.warning.withValues(alpha: 0.15)),
              ),
              child: Text('Enter admin password to exit kiosk mode.',
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AttendifyTheme.textSecondary)),
            ),
            const SizedBox(height: 20),
            TextField(controller: passCtrl, obscureText: true, autofocus: true,
                decoration: const InputDecoration(labelText: 'Admin Password', prefixIcon: Icon(Icons.lock_outline))),
            if (exitError != null) ...[const SizedBox(height: 12),
              Text(exitError!, style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.error, fontSize: 13))],
          ])),
          actions: [
            TextButton(onPressed: exitLoading ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: exitLoading ? null : () async {
                if (passCtrl.text.isEmpty) { setDialogState(() => exitError = 'Enter password'); return; }
                setDialogState(() { exitLoading = true; exitError = null; });
                try {
                  final ok = await widget.api.verifyKioskPassword(passCtrl.text);
                  if (ok) { if (ctx.mounted) Navigator.pop(ctx); widget.onExitKiosk(); }
                  else { setDialogState(() => exitError = 'Incorrect password'); }
                } catch (e) { setDialogState(() => exitError = 'Failed'); }
                finally { if (ctx.mounted) setDialogState(() => exitLoading = false); }
              },
              icon: exitLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.logout, size: 18),
              label: const Text('Exit Kiosk'),
              style: ElevatedButton.styleFrom(backgroundColor: AttendifyTheme.error, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final wide = size.width > 900;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AttendifyTheme.backgroundGradient),
        child: SafeArea(child: Column(children: [
          _header(wide),
          Expanded(child: wide
              ? Row(children: [Expanded(flex: 3, child: _scanArea(wide)), Expanded(flex: 2, child: _resultPanel(wide))])
              : Column(children: [Expanded(flex: 3, child: _scanArea(wide)), Expanded(flex: 2, child: _resultPanel(wide))])),
          _footer(),
        ])),
      ),
    );
  }

  Widget _header(bool wide) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 20, vertical: 14),
      child: Row(children: [
        // Logo with glow
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AttendifyTheme.primary.withValues(alpha: 0.15),
              AttendifyTheme.accent.withValues(alpha: 0.08),
            ]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AttendifyTheme.primary.withValues(alpha: 0.12), blurRadius: 16)],
          ),
          child: const Icon(Icons.face_retouching_natural, color: AttendifyTheme.primary, size: 26),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GradientText('ATTENDIFY', style: GoogleFonts.orbitron(fontSize: wide ? 20 : 16, fontWeight: FontWeight.w800)),
          Text('ATTENDANCE KIOSK',
              style: GoogleFonts.spaceGrotesk(fontSize: wide ? 11 : 9, color: AttendifyTheme.textSecondary,
                  letterSpacing: 3, fontWeight: FontWeight.w600)),
        ]),
        const Spacer(),
        // Date
        if (wide) ...[
          Text(_dateStr, style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AttendifyTheme.textSecondary, letterSpacing: 1)),
          const SizedBox(width: 16),
        ],
        // Clock with glow
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: AttendifyTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AttendifyTheme.primary.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: AttendifyTheme.primary.withValues(alpha: 0.06), blurRadius: 12)],
          ),
          child: Text(_timeStr, style: GoogleFonts.orbitron(
              fontSize: wide ? 24 : 18, fontWeight: FontWeight.w400,
              color: AttendifyTheme.primary, letterSpacing: 3)),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: _showExitDialog,
          icon: Icon(Icons.lock_outline, color: AttendifyTheme.textSecondary.withValues(alpha: 0.5), size: 20),
          tooltip: 'Admin Exit',
        ),
      ]),
    );
  }

  Widget _scanArea(bool wide) {
    final camSize = wide ? min(420.0, MediaQuery.of(context).size.height * 0.65) : min(320.0, MediaQuery.of(context).size.width * 0.8);
    final glowColor = _status == 'scanning' ? AttendifyTheme.primary
        : _status == 'matched' ? AttendifyTheme.success
        : _status == 'no_match' || _status == 'error' ? AttendifyTheme.error
        : AttendifyTheme.primary;

    return Center(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Camera container with face overlay
        Stack(alignment: Alignment.center, children: [
          // Outer glow ring
          if (_status == 'scanning' || _status == 'matched')
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: camSize + 16, height: camSize + 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(
                    color: glowColor.withValues(alpha: 0.15 + _pulseCtrl.value * 0.15),
                    blurRadius: 30 + _pulseCtrl.value * 20, spreadRadius: 2,
                  )],
                ),
              ),
            ),
          // Camera viewport
          Container(
            width: camSize, height: camSize,
            decoration: BoxDecoration(
              color: const Color(0xFF050510),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: glowColor.withValues(alpha: _status == 'ready' ? 0.15 : 0.5),
                width: _status == 'ready' || _status == 'initializing' ? 1 : 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _cameraReady && _camera != null
                ? Stack(fit: StackFit.expand, children: [
                    _camera!.buildLivePreview(),
                    // Face scan overlay (always visible)
                    AnimatedBuilder(
                      animation: Listenable.merge([_scanLineCtrl, _pulseCtrl]),
                      builder: (_, __) => CustomPaint(
                        painter: FaceScanPainter(
                          scanLineProgress: _scanLineCtrl.value,
                          bracketColor: glowColor,
                          pulseValue: _pulseCtrl.value,
                        ),
                      ),
                    ),
                    // Status-specific overlays
                    if (_status == 'scanning')
                      AnimatedBuilder(
                        animation: _statusCtrl,
                        builder: (_, __) => CustomPaint(
                          painter: FaceStatusPainter(
                            status: 'scanning', progress: _scanLineCtrl.value,
                            color: AttendifyTheme.primary,
                          ),
                        ),
                      ),
                    if (_status == 'matched')
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => CustomPaint(
                          painter: FaceStatusPainter(
                            status: 'matched', progress: _pulseCtrl.value,
                            color: AttendifyTheme.success,
                          ),
                        ),
                      ),
                    // HUD labels
                    Positioned(top: 12, left: 12, child: _hudLabel(
                      _status == 'scanning' ? 'ANALYZING...'
                          : _status == 'matched' ? 'MATCH FOUND'
                          : _status == 'no_match' ? 'NO MATCH'
                          : 'READY', glowColor)),
                    Positioned(top: 12, right: 12, child: _hudLabel('LIVE', AttendifyTheme.error)),
                    if (_status == 'matched' && _matchedStudent != null)
                      Positioned(bottom: 12, left: 12, right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_matchedStudent!['name']}  ·  ${(_similarity * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AttendifyTheme.success, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ])
                : _cameraPlaceholder(),
          ),
        ]),
        const SizedBox(height: 24),
        // Scan button with glow
        if (_status != 'scanning' && _status != 'initializing')
          Container(
            width: wide ? 280 : 220,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                color: AttendifyTheme.primary.withValues(alpha: 0.2),
                blurRadius: 16, offset: const Offset(0, 4),
              )],
            ),
            child: ElevatedButton.icon(
              onPressed: _scanFace,
              icon: const Icon(Icons.radar, size: 20),
              label: Text('SCAN FACE', style: GoogleFonts.spaceGrotesk(
                  fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        if (_status == 'scanning')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('Processing facial data...', style: GoogleFonts.spaceGrotesk(
                fontSize: 13, color: AttendifyTheme.primary.withValues(alpha: 0.7))),
          ),
      ]),
    ));
  }

  Widget _hudLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(
          color: color, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
        )),
        const SizedBox(width: 5),
        Text(text, style: GoogleFonts.orbitron(fontSize: 9, color: color, fontWeight: FontWeight.w600, letterSpacing: 1)),
      ]),
    );
  }

  Widget _cameraPlaceholder() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (_status == 'initializing') ...[
        SizedBox(width: 40, height: 40, child: CircularProgressIndicator(
            color: AttendifyTheme.primary.withValues(alpha: 0.5), strokeWidth: 2)),
        const SizedBox(height: 16),
        Text('INITIALIZING CAMERA', style: GoogleFonts.spaceGrotesk(
            fontSize: 12, color: AttendifyTheme.textSecondary, letterSpacing: 2)),
      ] else ...[
        Icon(Icons.videocam_off, size: 40, color: AttendifyTheme.textSecondary.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text('CAMERA UNAVAILABLE', style: GoogleFonts.spaceGrotesk(
            fontSize: 12, color: AttendifyTheme.textSecondary, letterSpacing: 2)),
      ],
    ]));
  }

  Widget _resultPanel(bool wide) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _status == 'matched' && _matchedStudent != null ? _matchResult(wide)
          : _status == 'no_match' ? _noMatchResult()
          : _status == 'error' && _errorMsg != null ? _errorResult()
          : _idleResult(wide),
    );
  }

  Widget _matchResult(bool wide) {
    final s = _matchedStudent!;
    final hasMarked = _markedSessions.isNotEmpty;
    final isAlreadyMarked = _attendanceStatus == 'already_marked';

    final Color statusColor;
    final String statusText;
    final IconData statusIcon;
    if (hasMarked) {
      statusColor = _attendanceStatus == 'late' ? AttendifyTheme.warning : AttendifyTheme.success;
      statusText = _attendanceStatus == 'late' ? 'ATTENDANCE MARKED — LATE' : 'ATTENDANCE MARKED';
      statusIcon = Icons.check_circle;
    } else if (isAlreadyMarked) {
      statusColor = AttendifyTheme.accent;
      statusText = 'ALREADY CHECKED IN';
      statusIcon = Icons.verified;
    } else {
      statusColor = AttendifyTheme.warning;
      statusText = 'NO ACTIVE SESSION';
      statusIcon = Icons.info_outline;
    }

    return GlassCard(
      padding: const EdgeInsets.all(24), glowColor: statusColor,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [statusColor.withValues(alpha: 0.2), statusColor.withValues(alpha: 0.0)]),
            boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.2), blurRadius: 20)],
          ),
          child: Icon(statusIcon, size: 40, color: statusColor),
        ),
        const SizedBox(height: 14),
        Text(statusText, style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor, letterSpacing: 2)),
        const SizedBox(height: 14),
        Text(s['name'] ?? '', style: GoogleFonts.spaceGrotesk(fontSize: wide ? 22 : 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(s['registration_number'] ?? '', style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 4),
        Text('${s['course'] ?? s['course_code'] ?? ''}  ·  Year ${s['year'] ?? ''}  ·  Sem ${s['semester'] ?? ''}',
            style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 14),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
          NeonChip(label: '${(_similarity * 100).toStringAsFixed(0)}% MATCH', color: AttendifyTheme.primary, icon: Icons.verified),
          if (hasMarked)
            NeonChip(label: _attendanceStatus == 'late' ? 'LATE' : 'PRESENT',
                color: _attendanceStatus == 'late' ? AttendifyTheme.warning : AttendifyTheme.success),
          if (isAlreadyMarked)
            NeonChip(label: 'ALREADY MARKED', color: AttendifyTheme.accent),
        ]),
        if (hasMarked) ...[
          const SizedBox(height: 14),
          Container(height: 1, color: AttendifyTheme.divider),
          const SizedBox(height: 10),
          ..._markedSessions.map((ms) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.class_, size: 14, color: AttendifyTheme.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Flexible(child: Text('${ms['unit_code']} — ${ms['unit_name']}  (${ms['time'] ?? ''})',
                  style: GoogleFonts.spaceGrotesk(fontSize: 12), textAlign: TextAlign.center)),
            ]),
          )),
        ],
        if (!hasMarked && !isAlreadyMarked) ...[
          const SizedBox(height: 10),
          Text('No session within check-in window right now.\nWindow: 15 min before → 20 min after start.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AttendifyTheme.textSecondary)),
        ],
      ]),
    );
  }

  Widget _noMatchResult() {
    return GlassCard(
      padding: const EdgeInsets.all(24), glowColor: AttendifyTheme.error,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [AttendifyTheme.error.withValues(alpha: 0.15), Colors.transparent]),
            boxShadow: [BoxShadow(color: AttendifyTheme.error.withValues(alpha: 0.15), blurRadius: 20)]),
          child: const Icon(Icons.person_off, size: 40, color: AttendifyTheme.error),
        ),
        const SizedBox(height: 14),
        Text('FACE NOT RECOGNIZED', style: GoogleFonts.orbitron(fontSize: 11, color: AttendifyTheme.error, fontWeight: FontWeight.w600, letterSpacing: 2)),
        const SizedBox(height: 10),
        Text('Please contact the administrator to enroll your face.',
            textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(color: AttendifyTheme.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _errorResult() {
    return GlassCard(
      padding: const EdgeInsets.all(24), glowColor: AttendifyTheme.error,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 40, color: AttendifyTheme.error.withValues(alpha: 0.8)),
        const SizedBox(height: 14),
        Text(_errorMsg ?? 'An error occurred', textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(fontSize: 14, color: AttendifyTheme.error)),
      ]),
    );
  }

  Widget _idleResult(bool wide) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: RadialGradient(colors: [AttendifyTheme.primary.withValues(alpha: 0.1), Colors.transparent]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.face_retouching_natural, size: 32, color: AttendifyTheme.primary.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 14),
          Text('INSTRUCTIONS', style: GoogleFonts.orbitron(fontSize: 11, color: AttendifyTheme.primary, letterSpacing: 3, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _step('01', 'Position yourself in front of the camera'),
          _step('02', 'Ensure your face is clearly visible'),
          _step('03', 'Press SCAN FACE to mark attendance'),
        ]),
      ),
    ]);
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AttendifyTheme.primary.withValues(alpha: 0.3)),
          ),
          child: Center(child: Text(num, style: GoogleFonts.orbitron(
              color: AttendifyTheme.primary, fontWeight: FontWeight.w600, fontSize: 10))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: GoogleFonts.spaceGrotesk(
            color: AttendifyTheme.textSecondary, fontSize: 13))),
      ]),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.shield, size: 12, color: AttendifyTheme.primary.withValues(alpha: 0.2)),
        const SizedBox(width: 6),
        Text('POWERED BY ATTENDIFY AI  ·  EMBU UNIVERSITY',
            style: GoogleFonts.spaceGrotesk(fontSize: 9, letterSpacing: 2,
                color: AttendifyTheme.textSecondary.withValues(alpha: 0.3), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _clockTimer?.cancel();
    _scanLineCtrl.dispose();
    _pulseCtrl.dispose();
    _statusCtrl.dispose();
    _camera?.disposeLiveCamera();
    super.dispose();
  }
}
