import 'package:flutter/material.dart';

import '../models/reward.dart';
import '../theme/manga_colors.dart';
import 'neo_widgets.dart';

/// Comic-Style Popup Badge displayed upon solving a round.
///
/// Features exact stopwatch time, speed band comic badge, coins reward,
/// and XP rewards (with glowing 2× XP boost indicator for Pro users).
class ComicPopup extends StatefulWidget {
  const ComicPopup({
    super.key,
    required this.reward,
    required this.levelNumber,
    required this.onNext,
  });

  final RewardResult reward;
  final int levelNumber;
  final VoidCallback onNext;

  @override
  State<ComicPopup> createState() => _ComicPopupState();
}

class _ComicPopupState extends State<ComicPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
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

    final band = widget.reward.band;
    final bannerColor = switch (band) {
      SpeedBand.lightning => MangaColors.yellow,
      SpeedBand.sharp => MangaColors.blue,
      SpeedBand.good => MangaColors.mint,
      SpeedBand.solved => MangaColors.paperDeep,
    };

    final shoutText = switch (band) {
      SpeedBand.lightning => 'LIGHTNING FAST!',
      SpeedBand.sharp => 'SHARP BRAIN!',
      SpeedBand.good => 'GOOD WORK!',
      SpeedBand.solved => 'SOLVED!',
    };

    return ColoredBox(
      color: const Color(0xCC111111),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ScaleTransition(
            scale: scale,
            child: Transform.rotate(
              angle: -0.03,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  NeoBox(
                    color: bannerColor,
                    offset: const Offset(8, 8),
                    borderWidth: 3,
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Speed band icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: MangaColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: MangaColors.ink, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: MangaColors.ink,
                                offset: Offset(3, 3),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            band.emoji,
                            style: const TextStyle(fontSize: 42),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Comic shoutout headline
                        Text(
                          shoutText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            letterSpacing: 1.2,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'LEVEL ${widget.levelNumber} COMPLETE · NEXT LEVEL OPEN',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Exact Time Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: MangaColors.ink,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '⏱️ ${widget.reward.seconds.toStringAsFixed(1)}s',
                            style: const TextStyle(
                              color: MangaColors.yellow,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Rewards breakdown
                        _RewardRow(
                          icon: '🪙',
                          label: 'COINS',
                          value: '+${widget.reward.coins}',
                          color: MangaColors.paper,
                        ),
                        const SizedBox(height: 8),
                        _RewardRow(
                          icon: '⭐',
                          label: widget.reward.xpDoubled
                              ? 'XP · 👑 PRO 2× BOOST'
                              : 'XP',
                          value: '+${widget.reward.xp}',
                          color: widget.reward.xpDoubled
                              ? const Color(0xFFFFF0A6)
                              : MangaColors.white,
                          isPro: widget.reward.xpDoubled,
                        ),
                        const SizedBox(height: 16),

                        // Action button
                        MangaButton(
                          label: 'NEXT LEVEL',
                          subtitle: 'Keep the momentum going',
                          color: MangaColors.mint,
                          icon: Icons.arrow_forward,
                          onPressed: widget.onNext,
                        ),
                      ],
                    ),
                  ),

                  // Floating Comic Badge Sticker
                  Positioned(
                    top: -12,
                    right: -10,
                    child: Transform.rotate(
                      angle: 0.12,
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
                        child: Text(
                          band == SpeedBand.lightning ? '⚡ SPEED DEMON!' : 'BRAIN IQ+',
                          style: const TextStyle(
                            color: MangaColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
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

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isPro = false,
  });

  final String icon;
  final String label;
  final String value;
  final Color color;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: isPro ? MangaColors.ink : MangaColors.ink,
          width: 2.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: MangaColors.ink,
            offset: Offset(2.5, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isPro ? const Color(0xFF996500) : MangaColors.ink,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
