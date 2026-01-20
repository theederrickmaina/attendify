import 'package:flutter/material.dart';

class NeumoCard extends StatelessWidget {
  const NeumoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            offset: Offset(4, 4),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Color(0x11FFFFFF),
            offset: Offset(-4, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class EmbuBackground extends StatelessWidget {
  const EmbuBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEFF7EF), Color(0xFFD7EAF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

class NeumoButton extends StatefulWidget {
  const NeumoButton({super.key, required this.onPressed, required this.child});
  final VoidCallback onPressed;
  final Widget child;
  @override
  State<NeumoButton> createState() => _NeumoButtonState();
}

class _NeumoButtonState extends State<NeumoButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _pressed
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    offset: Offset(2, 2),
                    blurRadius: 6,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x55000000),
                    offset: Offset(4, 6),
                    blurRadius: 16,
                  ),
                  BoxShadow(
                    color: Color(0x22FFFFFF),
                    offset: Offset(-2, -2),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

PreferredSizeWidget embuAppBar(String title) {
  return AppBar(
    title: Row(
      children: [
        const Icon(Icons.landscape_outlined, color: Colors.white70),
        const SizedBox(width: 8),
        Text(title),
      ],
    ),
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF006400), Color(0xFF228B22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
  );
}
