import 'package:flutter/material.dart';

import '../theme/cyber_palette.dart';

class CyberBackdrop extends StatelessWidget {
  const CyberBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _CircuitBackdropPainter(),
      child: child,
    );
  }
}

class _CircuitBackdropPainter extends CustomPainter {
  const _CircuitBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1223),
            CyberPalette.background,
            Color(0xFF100B1D),
          ],
          stops: [0, 0.55, 1],
        ).createShader(bounds),
    );

    final blueGlow = Rect.fromCircle(
      center: Offset(size.width * 0.08, size.height * 0.18),
      radius: size.width * 0.65,
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          colors: [CyberPalette.blue.withValues(alpha: 0.12), Colors.transparent],
        ).createShader(blueGlow),
    );
    final pinkGlow = Rect.fromCircle(
      center: Offset(size.width * 0.98, size.height * 0.72),
      radius: size.width * 0.58,
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          colors: [CyberPalette.pink.withValues(alpha: 0.08), Colors.transparent],
        ).createShader(pinkGlow),
    );

    final tracePaint = Paint()
      ..color = const Color(0x173B7FFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final nodePaint = Paint()..color = const Color(0x3369BFFF);
    for (var row = 0; row < 12; row++) {
      final y = 34.0 + row * 172;
      final direction = row.isEven ? 1.0 : -1.0;
      final startX = direction > 0 ? -12.0 : size.width + 12;
      final turnX = size.width * (row.isEven ? 0.24 : 0.77);
      final endX = size.width * (row.isEven ? 0.68 : 0.34);
      final path = Path()
        ..moveTo(startX, y)
        ..lineTo(turnX, y)
        ..lineTo(turnX + direction * 20, y + 20)
        ..lineTo(endX, y + 20);
      canvas.drawPath(path, tracePaint);
      canvas.drawCircle(Offset(endX, y + 20), 2, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitBackdropPainter oldDelegate) => false;
}

class CyberPanel extends StatelessWidget {
  const CyberPanel({
    super.key,
    required this.child,
    this.accent = CyberPalette.edge,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.onTap,
  });

  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: CyberPalette.panel.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withValues(alpha: 0.72), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 18,
            spreadRadius: 0.5,
          ),
          const BoxShadow(
            color: Color(0xBB02040B),
            offset: Offset(0, 7),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return panel;
    return GestureDetector(onTap: onTap, child: panel);
  }
}

class CyberPrimaryButton extends StatelessWidget {
  const CyberPrimaryButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.onPressed,
    this.icon = Icons.bolt,
  });

  final String label;
  final String subtitle;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: CyberPalette.blue.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(-5, 4),
          ),
          BoxShadow(
            color: CyberPalette.pink.withValues(alpha: 0.26),
            blurRadius: 20,
            offset: const Offset(5, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [CyberPalette.blue, CyberPalette.purple, CyberPalette.pink],
              ),
              borderRadius: radius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.66), width: 1.4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 30, color: CyberPalette.text),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: CyberPalette.text,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: CyberPalette.text.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
