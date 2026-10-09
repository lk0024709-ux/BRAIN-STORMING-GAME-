import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/rank_tier.dart';
import '../theme/manga_colors.dart';
import 'manga_avatar.dart';
import 'neo_widgets.dart';

/// Formats numbers with comma separators (e.g., 3400 -> "3,400").
String formatXp(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
}

/// Massive 2D Rank Medal with sharp Neo-Brutalist borders and drop shadow.
class RankBadge extends StatelessWidget {
  const RankBadge({
    super.key,
    required this.tier,
    this.size = 180,
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
            padding: EdgeInsets.only(top: size * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tier.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.12,
                    letterSpacing: 1.5,
                    color: MangaColors.ink,
                  ),
                ),
                Text(
                  '${formatXp(tier.minXp)} XP',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.08,
                    color: MangaColors.ink.withValues(alpha: 0.8),
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

    // Hard drop shadow
    final hexShadow = _hex(size, const Offset(6, 6));
    canvas.drawPath(hexShadow, shadow);

    final face = _hex(size, Offset.zero);

    // Glowing aura if Pro or evolution celebration
    if (glow) {
      canvas.drawPath(
        face,
        Paint()
          ..color = MangaColors.gold.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10,
      );
    }

    // Outer medal face
    canvas.drawPath(face, fill);
    canvas.drawPath(face, ink);

    // Inner concentric ring
    final innerFace = _hex(Size(size.width * 0.82, size.height * 0.82), Offset.zero);
    canvas.save();
    canvas.translate(size.width * 0.09, size.height * 0.09);
    canvas.drawPath(
      innerFace,
      Paint()
        ..color = MangaColors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      innerFace,
      Paint()
        ..color = MangaColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();

    // Medallion center circle
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.30;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = MangaColors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(center, radius, ink);

    // Star accent at the top of the circle
    _star(canvas, Offset(center.dx, center.dy - radius * 0.65), size.width * 0.045, fill, ink);
  }

  void _star(Canvas canvas, Offset c, double r, Paint fill, Paint ink) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final a1 = -math.pi / 2 + i * 2 * math.pi / 5;
      final a2 = a1 + math.pi / 5;
      final p1 = Offset(c.dx + r * math.cos(a1), c.dy + r * math.sin(a1));
      final p2 = Offset(c.dx + (r * 0.5) * math.cos(a2), c.dy + (r * 0.5) * math.sin(a2));
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.lineTo(p2.dx, p2.dy);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, ink..strokeWidth = 1.5);
  }

  Path _hex(Size size, Offset shift) {
    final c = Offset(size.width / 2, size.height / 2) + shift;
    final rx = size.width * 0.44;
    final ry = size.height * 0.48;
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

/// 2D Neo-Brutalist Progress Bar towards next Rank.
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: MangaColors.ink,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(progress.clamp(0.0, 1.0) * 100).round()}%',
                style: const TextStyle(
                  color: MangaColors.yellow,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: MangaColors.white,
            borderRadius: BorderRadius.circular(6),
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
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    width: width,
                    decoration: BoxDecoration(
                      color: MangaColors.rankFill(tier),
                      borderRadius: BorderRadius.circular(3),
                    ),
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

/// Forging / Rank Evolution Celebration Screen with characters celebrating!
class ForgeCelebration extends StatefulWidget {
  const ForgeCelebration({
    super.key,
    required this.tier,
    this.isPro = false,
  });

  final RankTier tier;
  final bool isPro;

  @override
  State<ForgeCelebration> createState() => _ForgeCelebrationState();
}

class _ForgeCelebrationState extends State<ForgeCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
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

    final heroLine = switch (widget.tier) {
      RankTier.silver => 'SILVER FORGED! The mind is sharpening fast!',
      RankTier.gold => 'GOLD UNLOCKED! We forged pure brilliance!',
      RankTier.diamond => 'DIAMOND DOJO MASTER! Peak brain reached!',
      RankTier.bronze => 'The spark is lit! Onward!',
    };

    final rivalLine = switch (widget.tier) {
      RankTier.silver => 'Tch! Lucky beginner gains. Try catching up to Gold!',
      RankTier.gold => 'N-nani?! You actually forged Gold?! Rematch right now!',
      RankTier.diamond => 'Impossible... Diamond Rank?! I will reclaim this dojo!',
      RankTier.bronze => 'Don\'t get cocky, hero!',
    };

    return SizedBox.expand(
      child: Material(
        color: const Color(0xF2111111),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                const Spacer(),

                // Animated Forged Medal Card
                ScaleTransition(
                  scale: scale,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      NeoBox(
                        color: MangaColors.yellow,
                        offset: const Offset(8, 8),
                        borderWidth: 3.5,
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MangaColors.ink,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '⚡ RANK FORGED! ⚡',
                                style: TextStyle(
                                  color: MangaColors.yellow,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Massive Medal
                            RankBadge(tier: widget.tier, size: 210, glow: true),
                            const SizedBox(height: 8),

                            Text(
                              widget.tier.motto,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: MangaColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Comic Spark Sticker
                      Positioned(
                        top: -14,
                        right: -10,
                        child: Transform.rotate(
                          angle: 0.15,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: MangaColors.pink,
                              border: Border.all(color: MangaColors.ink, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: MangaColors.ink,
                                  offset: Offset(3, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Text(
                              '💥 POWER UP!',
                              style: TextStyle(
                                color: MangaColors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Characters Celebrating Side-by-Side
                NeoBox(
                  color: MangaColors.white,
                  offset: const Offset(4, 4),
                  borderWidth: 2.5,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      MangaAvatar(
                        rival: false,
                        pro: widget.isPro,
                        size: 64,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: MangaColors.hero,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'HERO',
                                style: TextStyle(
                                  color: MangaColors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              heroLine,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Rival reaction
                NeoBox(
                  color: const Color(0xFFFFE8EE),
                  offset: const Offset(4, 4),
                  borderWidth: 2.5,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: MangaColors.rival,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'RIVAL',
                                style: TextStyle(
                                  color: MangaColors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              rivalLine,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const MangaAvatar(rival: true, size: 64),
                    ],
                  ),
                ),

                const Spacer(),

                // Return button
                MangaButton(
                  label: 'ENTER THE UPGRADED DOJO',
                  subtitle: 'Show the rival what ${widget.tier.label} can do',
                  color: MangaColors.mint,
                  icon: Icons.check_circle,
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

Future<void> showForgeCelebration(
  BuildContext context,
  RankTier tier, {
  bool isPro = false,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Rank forged',
    barrierColor: Colors.transparent,
    pageBuilder: (context, _, _) => ForgeCelebration(tier: tier, isPro: isPro),
  );
}
