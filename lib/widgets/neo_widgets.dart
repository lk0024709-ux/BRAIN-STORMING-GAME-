import 'package:flutter/material.dart';

import '../theme/manga_colors.dart';

class HalftoneBackground extends StatelessWidget {
  const HalftoneBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _HalftonePainter(),
      child: child,
    );
  }
}

class _HalftonePainter extends CustomPainter {
  const _HalftonePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = MangaColors.paper,
    );
    final dot = Paint()..color = const Color(0x14000000);
    const gap = 14.0;
    for (var y = 6.0; y < size.height; y += gap) {
      for (var x = 6.0; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.3, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NeoBox extends StatelessWidget {
  const NeoBox({
    super.key,
    required this.child,
    this.color = MangaColors.white,
    this.padding = const EdgeInsets.all(12),
    this.offset = const Offset(4, 4),
    this.borderWidth = 3,
    this.onTap,
    this.radius = 0,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final Offset offset;
  final double borderWidth;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: MangaColors.ink, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: MangaColors.ink,
            offset: offset,
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}

class MangaButton extends StatefulWidget {
  const MangaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = MangaColors.yellow,
    this.icon,
    this.expand = true,
    this.subtitle,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool expand;
  final String? subtitle;

  @override
  State<MangaButton> createState() => _MangaButtonState();
}

class _MangaButtonState extends State<MangaButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fill = enabled ? widget.color : MangaColors.disabled;
    final ink = enabled ? MangaColors.ink : MangaColors.disabledInk;
    final shift = _down && enabled ? const Offset(4, 4) : Offset.zero;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              widget.onPressed?.call();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: Matrix4.translationValues(shift.dx, shift.dy, 0),
        width: widget.expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: MangaColors.ink, width: 3),
          boxShadow: [
            BoxShadow(
              color: MangaColors.ink,
              offset: _down && enabled ? Offset.zero : const Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: ink, size: 20),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ink,
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
    );
  }
}

class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins, this.compact = false});

  final int coins;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return NeoBox(
      color: MangaColors.yellow,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      offset: const Offset(3, 3),
      borderWidth: 2.5,
      child: Text(
        '🪙 $coins',
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    );
  }
}

class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: MangaColors.gold,
        border: Border.all(color: MangaColors.ink, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: MangaColors.ink,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        compact ? '👑' : '👑 PRO',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
        fontSize: 13,
      ),
    );
  }
}
