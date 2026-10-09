import 'package:flutter/material.dart';

import '../theme/manga_colors.dart';

class MangaAvatar extends StatelessWidget {
  const MangaAvatar({
    super.key,
    required this.rival,
    this.pro = false,
    this.size = 78,
  });

  final bool rival;
  final bool pro;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.12,
      child: CustomPaint(
        painter: _AvatarPainter(rival: rival, pro: pro && !rival),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter({required this.rival, required this.pro});

  final bool rival;
  final bool pro;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ink = Paint()
      ..color = MangaColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..style = PaintingStyle.fill;

    if (pro) {
      fill.color = MangaColors.gold.withValues(alpha: 0.55);
      canvas.drawCircle(Offset(w * 0.5, h * 0.42), w * 0.48, fill);
      fill.color = MangaColors.gold;
      _crown(canvas, w, h, fill, ink);
    }

    // Hard shadow under the bust.
    fill.color = MangaColors.ink;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.58, w * 0.74, h * 0.40),
        Radius.circular(w * 0.08),
      ),
      fill,
    );

    fill.color = rival ? MangaColors.rival : MangaColors.hero;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.54, w * 0.74, h * 0.40),
        Radius.circular(w * 0.08),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.54, w * 0.74, h * 0.40),
        Radius.circular(w * 0.08),
      ),
      ink,
    );

    // Collar.
    fill.color = MangaColors.white;
    final collar = Path()
      ..moveTo(w * 0.38, h * 0.62)
      ..lineTo(w * 0.50, h * 0.78)
      ..lineTo(w * 0.62, h * 0.62)
      ..close();
    canvas.drawPath(collar, fill);
    canvas.drawPath(collar, ink);

    fill.color = MangaColors.skin;
    canvas.drawCircle(Offset(w * 0.50, h * 0.40), w * 0.30, fill);
    canvas.drawCircle(Offset(w * 0.50, h * 0.40), w * 0.30, ink);

    fill.color = MangaColors.ink;
    if (rival) {
      _rivalHair(canvas, w, h, fill, ink);
    } else {
      _heroHair(canvas, w, h, fill);
    }

    _eyes(canvas, w, h, fill, ink, smirk: rival);
    fill.color = MangaColors.blush;
    canvas.drawCircle(Offset(w * 0.30, h * 0.48), w * 0.045, fill);
    canvas.drawCircle(Offset(w * 0.70, h * 0.48), w * 0.045, fill);

    if (pro) {
      fill.color = MangaColors.ink;
      final badge = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.62, h * 0.78, w * 0.30, h * 0.16),
        Radius.circular(w * 0.04),
      );
      fill.color = MangaColors.gold;
      canvas.drawRRect(badge, fill);
      canvas.drawRRect(badge, ink);
    }
  }

  void _heroHair(Canvas canvas, double w, double h, Paint fill) {
    final hair = Path()
      ..moveTo(w * 0.22, h * 0.36)
      ..lineTo(w * 0.18, h * 0.16)
      ..lineTo(w * 0.34, h * 0.24)
      ..lineTo(w * 0.40, h * 0.08)
      ..lineTo(w * 0.52, h * 0.20)
      ..lineTo(w * 0.64, h * 0.06)
      ..lineTo(w * 0.70, h * 0.22)
      ..lineTo(w * 0.86, h * 0.14)
      ..lineTo(w * 0.80, h * 0.38)
      ..close();
    canvas.drawPath(hair, fill);
  }

  void _rivalHair(Canvas canvas, double w, double h, Paint fill, Paint ink) {
    final hair = Path()
      ..moveTo(w * 0.20, h * 0.42)
      ..quadraticBezierTo(w * 0.18, h * 0.12, w * 0.48, h * 0.12)
      ..quadraticBezierTo(w * 0.86, h * 0.10, w * 0.82, h * 0.40)
      ..lineTo(w * 0.74, h * 0.32)
      ..quadraticBezierTo(w * 0.50, h * 0.22, w * 0.28, h * 0.36)
      ..close();
    canvas.drawPath(hair, fill);
    fill.color = MangaColors.white;
    canvas.drawRect(Rect.fromLTWH(w * 0.18, h * 0.30, w * 0.16, h * 0.06), fill);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.18, h * 0.30, w * 0.16, h * 0.06),
      ink,
    );
  }

  void _eyes(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint ink, {
    required bool smirk,
  }) {
    fill.color = MangaColors.white;
    final left = Rect.fromLTWH(w * 0.30, h * 0.36, w * 0.14, h * 0.10);
    final right = Rect.fromLTWH(w * 0.56, h * 0.36, w * 0.14, h * 0.10);
    canvas.drawRRect(
      RRect.fromRectAndRadius(left, const Radius.circular(4)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(right, const Radius.circular(4)),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(left, const Radius.circular(4)),
      ink..strokeWidth = w * 0.03,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(right, const Radius.circular(4)),
      ink,
    );
    fill.color = MangaColors.ink;
    canvas.drawCircle(Offset(w * 0.38, h * 0.41), w * 0.035, fill);
    canvas.drawCircle(Offset(w * 0.64, h * 0.41), w * 0.035, fill);
    fill.color = MangaColors.white;
    canvas.drawCircle(Offset(w * 0.395, h * 0.398), w * 0.012, fill);
    canvas.drawCircle(Offset(w * 0.655, h * 0.398), w * 0.012, fill);

    final mouth = Path();
    if (smirk) {
      mouth
        ..moveTo(w * 0.40, h * 0.54)
        ..quadraticBezierTo(w * 0.55, h * 0.60, w * 0.66, h * 0.52);
    } else {
      mouth
        ..moveTo(w * 0.40, h * 0.54)
        ..quadraticBezierTo(w * 0.50, h * 0.62, w * 0.60, h * 0.54);
    }
    canvas.drawPath(mouth, ink..style = PaintingStyle.stroke);
    ink.style = PaintingStyle.stroke;
  }

  void _crown(Canvas canvas, double w, double h, Paint fill, Paint ink) {
    final crown = Path()
      ..moveTo(w * 0.28, h * 0.20)
      ..lineTo(w * 0.34, h * 0.08)
      ..lineTo(w * 0.50, h * 0.16)
      ..lineTo(w * 0.66, h * 0.04)
      ..lineTo(w * 0.74, h * 0.18)
      ..lineTo(w * 0.70, h * 0.20)
      ..close();
    canvas.drawPath(crown, fill);
    canvas.drawPath(crown, ink);
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.rival != rival || oldDelegate.pro != pro;
  }
}
