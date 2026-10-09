import 'package:flutter/material.dart';

import '../models/nameplate.dart';
import '../theme/manga_colors.dart';
import 'manga_avatar.dart';
import 'neo_widgets.dart';

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
        Column(
          children: [
            MangaAvatar(rival: false, pro: pro, size: 72),
            const SizedBox(height: 4),
            _Nameplate(name: heroName, style: nameplate, pro: pro),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              _Bubble(text: heroLine, color: MangaColors.white, alignLeft: true),
              const SizedBox(height: 6),
              _Bubble(text: rivalLine, color: const Color(0xFFFFE1EA), alignLeft: false),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            const MangaAvatar(rival: true, size: 72),
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
    final fill = Color(style.fillHex);
    return Container(
      constraints: const BoxConstraints(maxWidth: 78),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: MangaColors.ink, width: 2),
        boxShadow: [
          BoxShadow(
            color: pro ? MangaColors.gold : MangaColors.ink,
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
          color: Color(style.inkHex),
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
  });

  final String text;
  final Color color;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return NeoBox(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      offset: const Offset(3, 3),
      borderWidth: 2.5,
      child: Align(
        alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: Text(
          text,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
