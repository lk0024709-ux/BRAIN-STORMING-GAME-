import 'package:flutter/material.dart';

import '../theme/cyber_palette.dart';
import 'rank_widgets.dart';

/// Widgets for the "BATTLE DOJO" battle screen: dark neon panels, a gold
/// italic title, a purple thought cloud, and a 2x2 grid of neon answer cards.
/// These widgets are presentational only. Game state is passed in by the
/// gameplay screen.

/// Perspective grid floor drawn behind the battle content.
class BattleGridFloorPainter extends CustomPainter {
  const BattleGridFloorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.66;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          CyberPalette.purple.withValues(alpha: 0.35),
          CyberPalette.purple.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCenter(
          center: Offset(w / 2, horizon),
          width: w * 1.2,
          height: h * 0.5,
        ),
      );
    canvas.drawRect(Rect.fromLTWH(0, horizon - h * 0.25, w, h * 0.5), glow);

    final line = Paint()
      ..color = CyberPalette.cyan.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final vanishing = Offset(w / 2, horizon);
    for (var i = -8; i <= 8; i++) {
      canvas.drawLine(vanishing, Offset(w / 2 + i * w * 0.2, h), line);
    }
    for (var k = 1; k <= 10; k++) {
      final t = k / 10;
      final y = horizon + (h - horizon) * t * t;
      canvas.drawLine(Offset(0, y), Offset(w, y), line);
    }

    canvas.drawLine(
      Offset(0, horizon),
      Offset(w, horizon),
      Paint()
        ..color = CyberPalette.cyan.withValues(alpha: 0.35)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant BattleGridFloorPainter oldDelegate) => false;
}

/// Gold italic "BATTLE DOJO" title with a cyan subtitle.
class BattleDojoTitle extends StatelessWidget {
  const BattleDojoTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF2B3),
                CyberPalette.gold,
                Color(0xFFE08A1E),
              ],
            ).createShader(bounds),
            child: const Text(
              'BATTLE DOJO',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 2,
                height: 1.05,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Solve to enter the dojo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: CyberPalette.cyan,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

/// Hero portrait in a neon ring with a LIVE tag and tier/level/XP lines.
class BattleHeroChip extends StatelessWidget {
  const BattleHeroChip({
    super.key,
    required this.tierLabel,
    required this.level,
    required this.totalXp,
    required this.pro,
  });

  final String tierLabel;
  final int level;
  final int totalXp;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    final ring = pro
        ? const [CyberPalette.gold, Color(0xFFE08A1E)]
        : const [CyberPalette.cyan, CyberPalette.purple];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: ring),
            boxShadow: [
              BoxShadow(
                color: ring.first.withValues(alpha: 0.55),
                blurRadius: 16,
              ),
            ],
          ),
          child: ClipOval(
            child: ColoredBox(
              color: CyberPalette.panelDeep,
              child: Image.asset(
                'assets/images/hero_avatar.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.6),
                gaplessPlayback: true,
                semanticLabel: 'Hero portrait',
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: CyberPalette.cyan,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: CyberPalette.mint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CyberPalette.mint),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 3, backgroundColor: CyberPalette.mint),
              SizedBox(width: 5),
              Text(
                'LIVE',
                style: TextStyle(
                  color: CyberPalette.mint,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$tierLabel · LV $level',
          style: const TextStyle(
            color: CyberPalette.text,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '${formatXp(totalXp)} XP',
          style: const TextStyle(
            color: CyberPalette.gold,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Gold "+N IQ XP" pill shown at the top-right of the thought cloud.
class BattleXpBadge extends StatelessWidget {
  const BattleXpBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CyberPalette.gold, Color(0xFFE08A1E)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: CyberPalette.gold.withValues(alpha: 0.5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF1A1200)),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1A1200),
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Purple glowing thought cloud that holds the question formula.
class BattleCloud extends StatelessWidget {
  const BattleCloud({
    super.key,
    required this.label,
    required this.formula,
    required this.xpText,
    this.hint,
  });

  final String label;
  final String formula;
  final String xpText;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _CloudPainter()),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD2B8FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _FormulaText(formula: formula),
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: CyberPalette.panelDeep.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CyberPalette.gold),
                    ),
                    child: Text(
                      '💡 $hint',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CyberPalette.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 4,
          child: BattleXpBadge(text: xpText),
        ),
      ],
    );
  }
}

class _FormulaText extends StatelessWidget {
  const _FormulaText({required this.formula});

  final String formula;

  static const _operators = {'+', '-', '−', '×', '÷', '*', '/', '='};

  @override
  Widget build(BuildContext context) {
    // Keep one span per character so the plain text still equals the formula
    // (tests and screen readers see the exact question text).
    return Text.rich(
      TextSpan(
        children: [
          for (final ch in formula.split(''))
            TextSpan(
              text: ch,
              style: TextStyle(
                color: _operators.contains(ch)
                    ? CyberPalette.cyan
                    : ch == '?'
                        ? CyberPalette.gold
                        : CyberPalette.text,
              ),
            ),
        ],
      ),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        shadows: [
          Shadow(color: CyberPalette.cyan, blurRadius: 12),
        ],
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    var path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(w * 0.06, h * 0.42, w * 0.94, h * 0.94),
          Radius.circular(h * 0.26),
        ),
      );
    final bumps = [
      Rect.fromCircle(center: Offset(w * 0.22, h * 0.52), radius: h * 0.22),
      Rect.fromCircle(center: Offset(w * 0.42, h * 0.38), radius: h * 0.30),
      Rect.fromCircle(center: Offset(w * 0.64, h * 0.44), radius: h * 0.26),
      Rect.fromCircle(center: Offset(w * 0.84, h * 0.56), radius: h * 0.20),
    ];
    for (final rect in bumps) {
      path = Path.combine(PathOperation.union, path, Path()..addOval(rect));
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = CyberPalette.purple.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 0.9,
          colors: const [
            Color(0xFF3B1E7A),
            Color(0xFF1A1040),
            Color(0xFF0C0A22),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFB48CFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) => false;
}

enum BattleAnswerState { idle, correct, wrong, dimmed, removed }

/// One neon answer card: letter in the accent color, answer in white.
class BattleAnswerCard extends StatefulWidget {
  const BattleAnswerCard({
    super.key,
    required this.letter,
    required this.answer,
    required this.accent,
    required this.state,
    required this.onPressed,
  });

  final String letter;
  final String answer;
  final Color accent;
  final BattleAnswerState state;
  final VoidCallback? onPressed;

  @override
  State<BattleAnswerCard> createState() => _BattleAnswerCardState();
}

class _BattleAnswerCardState extends State<BattleAnswerCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    final style = switch (widget.state) {
      BattleAnswerState.idle => (
          border: widget.accent,
          fill: CyberPalette.panel,
          letter: widget.accent,
          text: CyberPalette.text,
          glow: 0.45,
        ),
      BattleAnswerState.correct => (
          border: CyberPalette.mint,
          fill: CyberPalette.mint.withValues(alpha: 0.18),
          letter: CyberPalette.mint,
          text: CyberPalette.text,
          glow: 0.7,
        ),
      BattleAnswerState.wrong => (
          border: CyberPalette.pink,
          fill: CyberPalette.pink.withValues(alpha: 0.18),
          letter: CyberPalette.pink,
          text: CyberPalette.text,
          glow: 0.6,
        ),
      BattleAnswerState.dimmed || BattleAnswerState.removed => (
          border: CyberPalette.edge.withValues(alpha: 0.4),
          fill: CyberPalette.panelDeep.withValues(alpha: 0.6),
          letter: CyberPalette.muted.withValues(alpha: 0.5),
          text: CyberPalette.muted.withValues(alpha: 0.5),
          glow: 0.0,
        ),
    };
    final border = style.border;
    final fill = style.fill;
    final letterColor = style.letter;
    final textColor = style.text;
    final glow = style.glow;

    return AnimatedScale(
      scale: _down && enabled ? 0.96 : 1,
      duration: const Duration(milliseconds: 80),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled
            ? (_) {
                setState(() => _down = false);
                widget.onPressed?.call();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 2),
            boxShadow: glow > 0
                ? [
                    BoxShadow(
                      color: border.withValues(alpha: glow),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(
                widget.letter,
                style: TextStyle(
                  color: letterColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.answer,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Booster / retry button with a neon border, title, and subtitle.
class BattleActionButton extends StatelessWidget {
  const BattleActionButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: CyberPalette.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: CyberPalette.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CyberPalette.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One neon speech line under the cloud, tagged with the speaker.
class BattleBanterLine extends StatelessWidget {
  const BattleBanterLine({
    super.key,
    required this.speaker,
    required this.text,
    required this.color,
  });

  final String speaker;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color),
          ),
          child: Text(
            speaker,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CyberPalette.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
