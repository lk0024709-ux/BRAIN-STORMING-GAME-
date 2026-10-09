import 'package:flutter/material.dart';

import '../models/rank_tier.dart';

class MangaColors {
  MangaColors._();

  static const ink = Color(0xFF111111);
  static const paper = Color(0xFFFFF4DE);
  static const paperDeep = Color(0xFFFFE7C2);
  static const pink = Color(0xFFFF3D7F);
  static const yellow = Color(0xFFFFE14A);
  static const blue = Color(0xFF3EC1FF);
  static const hero = Color(0xFF2F6BFF);
  static const rival = Color(0xFFFF3355);
  static const mint = Color(0xFF5DFFB0);
  static const green = Color(0xFF1EC86A);
  static const red = Color(0xFFFF3B30);
  static const white = Color(0xFFFFFFFF);
  static const cloud = Color(0xFFFFFDF8);
  static const disabled = Color(0xFFE7DCCB);
  static const disabledInk = Color(0xFF8A8175);
  static const bronze = Color(0xFFE08A45);
  static const silver = Color(0xFFD5DDE6);
  static const gold = Color(0xFFFFC400);
  static const diamond = Color(0xFF7AF0FF);
  static const skin = Color(0xFFFFCBA8);
  static const blush = Color(0xFFFF8FAB);

  static const optionFills = <Color>[yellow, blue, pink, mint];

  static Color rankFill(RankTier tier) => switch (tier) {
        RankTier.bronze => bronze,
        RankTier.silver => silver,
        RankTier.gold => gold,
        RankTier.diamond => diamond,
      };
}
