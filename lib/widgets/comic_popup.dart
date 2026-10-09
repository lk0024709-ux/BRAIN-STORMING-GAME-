import 'package:flutter/material.dart';

import '../models/reward.dart';
import '../theme/manga_colors.dart';
import 'neo_widgets.dart';

class ComicPopup extends StatefulWidget {
  const ComicPopup({
    super.key,
    required this.reward,
    required this.onNext,
  });

  final RewardResult reward;
  final VoidCallback onNext;

  @override
  State<ComicPopup> createState() => _ComicPopupState();
}

class _ComicPopupState extends State<ComicPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
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
    return ColoredBox(
      color: const Color(0xAA111111),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: ScaleTransition(
            scale: scale,
            child: Transform.rotate(
              angle: -0.04,
              child: NeoBox(
                color: MangaColors.yellow,
                offset: const Offset(8, 8),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.reward.band.emoji,
                      style: const TextStyle(fontSize: 42),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.reward.headline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.reward.band.title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RewardRow(
                      label: 'COINS',
                      value: '+${widget.reward.coins}',
                    ),
                    const SizedBox(height: 6),
                    _RewardRow(
                      label: widget.reward.xpDoubled ? 'XP  ·  PRO 2x' : 'XP',
                      value: '+${widget.reward.xp}',
                    ),
                    const SizedBox(height: 14),
                    MangaButton(
                      label: 'NEXT',
                      color: MangaColors.mint,
                      onPressed: widget.onNext,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: MangaColors.white,
        border: Border.all(color: MangaColors.ink, width: 2.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
