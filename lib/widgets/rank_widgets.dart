import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/rank_tier.dart';
import '../theme/manga_colors.dart';
import 'neo_widgets.dart';

class RankBadge extends StatelessWidget {
  const RankBadge({
    super.key,
    required this.tier,
    this.size = 168,
    this.glow = false,
  });

  final RankTier tier;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MedalPainter(tier: tier, glow: glow),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: size * 0.08),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tier.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.11,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${tier.minXp}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.08,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter({required this.tier, required this.glow});

  final RankTier tier;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = MangaColors.rankFill(tier);
    final ink = Paint()
      ..color = MangaColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.miter;
    final shadow = Paint()..color = MangaColors.ink;
    final hex = _hex(size, const Offset(6, 6));
    canvas.drawPath(hex, shadow);
    final face = _hex(size, Offset.zero);
    if (glow) {
      canvas.drawPath(
        face,
        Paint()
          ..color = MangaColors.gold.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10,
      );
    }
    canvas.drawPath(face, fill);
    canvas.drawPath(face, ink);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.28,
      Paint()
        ..color = MangaColors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.28,
      ink,
    );
  }

  Path _hex(Size size, Offset shift) {
    final c = Offset(size.width / 2, size.height / 2) + shift;
    final rx = size.width * 0.42;
    final ry = size.height * 0.46;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = (-math.pi / 2) + i * math.pi / 3;
      final point = Offset(
        c.dx + rx * math.cos(angle),
        c.dy + ry * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _MedalPainter oldDelegate) {
    return oldDelegate.tier != tier || oldDelegate.glow != glow;
  }
}

class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.progress,
    required this.tier,
    required this.label,
  });

  final double progress;
  final RankTier tier;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          height: 22,
          decoration: BoxDecoration(
            color: MangaColors.white,
            border: Border.all(color: MangaColors.ink, width: 3),
            boxShadow: const [
              BoxShadow(
                color: MangaColors.ink,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  constraints.maxWidth * progress.clamp(0.0, 1.0).toDouble();
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: width,
                    color: MangaColors.rankFill(tier),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class ForgeCelebration extends StatefulWidget {
  const ForgeCelebration({super.key, required this.tier});

  final RankTier tier;

  @override
  State<ForgeCelebration> createState() => _ForgeCelebrationState();
}

class _ForgeCelebrationState extends State<ForgeCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    return SizedBox.expand(
      child: Material(
        color: const Color(0xF0111111),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: scale,
                  child: NeoBox(
                    color: MangaColors.yellow,
                    offset: const Offset(8, 8),
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                    child: Column(
                      children: [
                        const Text(
                          'RANK FORGED',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RankBadge(tier: widget.tier, size: 210, glow: true),
                        const SizedBox(height: 8),
                        Text(
                          widget.tier.motto,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The medal hits the anvil. Your dojo just got louder.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                MangaButton(
                  label: 'BACK TO THE DOJO',
                  color: MangaColors.mint,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showForgeCelebration(BuildContext context, RankTier tier) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Rank forged',
    barrierColor: Colors.transparent,
    pageBuilder: (context, _, _) => ForgeCelebration(tier: tier),
  );
}
