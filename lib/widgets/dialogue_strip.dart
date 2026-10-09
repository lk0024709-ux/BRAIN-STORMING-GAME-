import 'package:flutter/material.dart';

import '../models/nameplate.dart';
import '../theme/manga_colors.dart';
import 'manga_avatar.dart';
import 'neo_widgets.dart';

/// Character Header Dialogue Strip displaying Hero (Boy) and Rival
/// avatars with Manga-style chat bubbles reacting to the game state.
class DialogueStrip extends StatelessWidget {
  const DialogueStrip({
    super.key,
    required this.heroName,
    required this.heroLine,
    required this.rivalLine,
    required this.pro,
    required this.nameplate,
  });

  final String heroName;
  final String heroLine;
  final String rivalLine;
  final bool pro;
  final NameplateStyle nameplate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Avatar (Boy) with golden frame & 👑 PRO badge if Pro
        Column(
          children: [
            MangaAvatar(rival: false, pro: pro, size: 66),
            const SizedBox(height: 4),
            _Nameplate(name: heroName, style: nameplate, pro: pro),
          ],
        ),
        const SizedBox(width: 8),

        // Manga-style chat bubbles reacting to game state
        Expanded(
          child: Column(
            children: [
              _Bubble(
                text: heroLine,
                color: MangaColors.white,
                alignLeft: true,
                speakerTag: 'HERO',
                tagColor: MangaColors.hero,
              ),
              const SizedBox(height: 5),
              _Bubble(
                text: rivalLine,
                color: const Color(0xFFFFE6ED),
                alignLeft: false,
                speakerTag: 'RIVAL',
                tagColor: MangaColors.rival,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Rival Avatar
        Column(
          children: [
            const MangaAvatar(rival: true, size: 66),
            const SizedBox(height: 4),
            const _Nameplate(
              name: 'RIVAL',
              style: NameplateStyle.classic,
              pro: false,
            ),
          ],
        ),
      ],
    );
  }
}

class _Nameplate extends StatelessWidget {
  const _Nameplate({
    required this.name,
    required this.style,
    required this.pro,
  });

  final String name;
  final NameplateStyle style;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    final fill = pro ? MangaColors.gold : Color(style.fillHex);
    return Container(
      constraints: const BoxConstraints(maxWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: MangaColors.ink, width: 2),
        boxShadow: [
          BoxShadow(
            color: pro ? const Color(0xFFB38600) : MangaColors.ink,
            offset: const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        pro ? '👑 $name' : name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: pro ? MangaColors.ink : Color(style.inkHex),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.color,
    required this.alignLeft,
    required this.speakerTag,
    required this.tagColor,
  });

  final String text;
  final Color color;
  final bool alignLeft;
  final String speakerTag;
  final Color tagColor;

  @override
  Widget build(BuildContext context) {
    return NeoBox(
      color: color,
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
      offset: const Offset(2.5, 2.5),
      borderWidth: 2,
      child: Column(
        crossAxisAlignment:
            alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: tagColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  speakerTag,
                  style: const TextStyle(
                    color: MangaColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 7.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignLeft ? TextAlign.left : TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              height: 1.2,
              color: MangaColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
