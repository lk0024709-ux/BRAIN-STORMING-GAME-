import 'package:flutter/material.dart';

import '../theme/manga_colors.dart';

/// Generated portrait for the hero and rival, framed in the game's manga style.
///
/// When [pro] is true on the hero, the portrait gets a golden frame and badge.
class MangaAvatar extends StatelessWidget {
  const MangaAvatar({
    super.key,
    required this.rival,
    this.pro = false,
    this.size = 76,
  });

  final bool rival;
  final bool pro;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isProHero = pro && !rival;
    final avatarWidget = SizedBox(
      width: size,
      height: size * 1.12,
      child: Image.asset(
        rival
            ? 'assets/images/rival_avatar.png'
            : 'assets/images/hero_avatar.png',
        fit: BoxFit.contain,
        semanticLabel: rival
            ? 'Rival character portrait'
            : 'Hero character portrait',
      ),
    );

    if (!isProHero) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MangaColors.ink, width: 2.5),
          color: MangaColors.white,
          boxShadow: const [
            BoxShadow(
              color: MangaColors.ink,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: avatarWidget,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MangaColors.ink, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: MangaColors.gold,
                offset: Offset(0, 0),
                blurRadius: 8,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: MangaColors.ink,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: MangaColors.gold, width: 2.5),
              color: MangaColors.white,
            ),
            padding: const EdgeInsets.all(2),
            child: avatarWidget,
          ),
        ),
        Positioned(
          top: -7,
          right: -7,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: MangaColors.gold,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: MangaColors.ink, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: MangaColors.ink,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Text(
              '👑 PRO',
              style: TextStyle(
                color: MangaColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 8.5,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
