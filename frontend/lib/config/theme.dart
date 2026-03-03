import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Attendify — Futuristic Neon Design System
/// Electric cyan + violet neon on deep space black
class AttendifyTheme {
  // ── Core palette ──
  static const Color primary = Color(0xFF00F0FF);       // Electric cyan
  static const Color primaryDark = Color(0xFF0891B2);
  static const Color accent = Color(0xFF8B5CF6);         // Neon violet
  static const Color accentPink = Color(0xFFEC4899);     // Neon pink
  static const Color surface = Color(0xFF0A0F1E);        // Deep space
  static const Color surfaceLight = Color(0xFF111827);   // Lighter space
  static const Color card = Color(0xFF1F2937);           // Card bg
  static const Color background = Color(0xFF050510);     // Near-black
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color divider = Color(0xFF1E293B);

  // ── Gradient presets ──
  static const LinearGradient cyanGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF0891B2)],
  );
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
  );
  static const LinearGradient cyanPurpleGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF8B5CF6)],
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF050510), Color(0xFF0A0F1E), Color(0xFF0F172A)],
  );

  static TextStyle get orbitron => GoogleFonts.orbitron();
  static TextStyle get spaceGrotesk => GoogleFonts.spaceGrotesk();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      cardColor: card,
      dividerColor: divider,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: divider.withValues(alpha: 0.5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF050510),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: GoogleFonts.spaceGrotesk(color: textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.spaceGrotesk(color: textSecondary.withValues(alpha: 0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: textSecondary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: primary.withValues(alpha: 0.2),
        side: BorderSide(color: divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: GoogleFonts.spaceGrotesk(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0A0F1E),
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return GoogleFonts.spaceGrotesk(
            color: states.contains(WidgetState.selected) ? primary : textSecondary,
            fontSize: 11, fontWeight: FontWeight.w600,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Color(0xFF050510),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surfaceLight),
        dataRowColor: WidgetStateProperty.all(Colors.transparent),
        dividerThickness: 0.5,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Color(0xFF0F172A)),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Glassmorphism card with optional neon border glow
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final Color? glowColor;

  const GlassCard({super.key, required this.child, this.padding, this.margin,
    this.width, this.height, this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            AttendifyTheme.surfaceLight.withValues(alpha: 0.8),
            AttendifyTheme.surfaceLight.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: glowColor?.withValues(alpha: 0.3) ??
              AttendifyTheme.divider.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.08),
              blurRadius: 24, spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Stat card with neon glow icon and gradient accent
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const StatCard({super.key, required this.title, required this.value,
    required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AttendifyTheme.primary;
    return GlassCard(
      glowColor: c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.withValues(alpha: 0.2), c.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: c.withValues(alpha: 0.15), blurRadius: 12),
                ],
              ),
              child: Icon(icon, color: c, size: 22),
            ),
            const Spacer(),
          ]),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [c, c.withValues(alpha: 0.7)],
            ).createShader(bounds),
            child: Text(value,
              style: GoogleFonts.orbitron(
                fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 4),
          Text(title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12, color: AttendifyTheme.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Neon-bordered status chip
class NeonChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const NeonChip({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
        ],
        Text(label, style: GoogleFonts.spaceGrotesk(
          fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
      ]),
    );
  }
}

/// Animated ring pulse (for kiosk / scanning states)
class PulseRing extends StatefulWidget {
  final double size;
  final Color color;
  final Widget? child;

  const PulseRing({super.key, required this.size, this.color = AttendifyTheme.primary, this.child});

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final v = _ctrl.value;
        return CustomPaint(
          painter: _PulseRingPainter(progress: v, color: widget.color),
          child: SizedBox(width: widget.size, height: widget.size, child: child),
        );
      },
      child: widget.child,
    );
  }
}

class _PulseRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _PulseRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = min(size.width, size.height) / 2;

    for (int i = 0; i < 3; i++) {
      final p = (progress + i * 0.33) % 1.0;
      final radius = maxR * (0.5 + p * 0.5);
      final alpha = (1 - p) * 0.3;
      canvas.drawCircle(
        Offset(cx, cy), radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_PulseRingPainter old) => progress != old.progress;
}

/// Gradient text utility
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const GradientText(this.text, {super.key, required this.style,
    this.gradient = AttendifyTheme.cyanPurpleGradient});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

/// Animated background with subtle floating particles
class ParticleBackground extends StatefulWidget {
  final Widget child;
  const ParticleBackground({super.key, required this.child});
  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(30, (_) => _Particle(rng));
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Gradient background
      Container(decoration: const BoxDecoration(gradient: AttendifyTheme.backgroundGradient)),
      // Particles
      AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _ParticlePainter(_particles, _ctrl.value),
          size: Size.infinite,
        ),
      ),
      widget.child,
    ]);
  }
}

class _Particle {
  final double x, y, speed, size;
  final Color color;
  _Particle(Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        speed = 0.2 + r.nextDouble() * 0.8,
        size = 1 + r.nextDouble() * 2,
        color = r.nextBool() ? AttendifyTheme.primary : AttendifyTheme.accent;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  _ParticlePainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final px = p.x * size.width;
      final py = ((p.y + time * p.speed * 0.3) % 1.0) * size.height;
      canvas.drawCircle(
        Offset(px, py), p.size,
        Paint()..color = p.color.withValues(alpha: 0.15),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
