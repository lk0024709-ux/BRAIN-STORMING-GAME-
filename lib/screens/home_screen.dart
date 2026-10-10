import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/age_band.dart';
import '../models/math_level.dart';
import '../theme/cyber_palette.dart';
import '../theme/manga_theme.dart';
import '../widgets/cyber_widgets.dart';
import '../widgets/rank_widgets.dart';
import 'gameplay_screen.dart';
import 'level_map_screen.dart';
import 'pro_upgrade_screen.dart';
import 'rank_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _start(BuildContext context) {
    final profile = context.read<ProfileController>();
    if (profile.profile.soundOn) {
      SystemSound.play(SystemSoundType.click);
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => GameController(profile: profile)..startSession(),
          child: const GameplayScreen(),
        ),
      ),
    );
  }

  void _openLevelMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const LevelMapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;
    final currentLevel = profile.levelsCompleted + 1;
    final level = MathLevelInfo.forAge(profile.userAge, currentLevel);
    final completedCoreLevels = profile.levelsCompleted
        .clamp(0, MathLevelInfo.campaignLength)
        .toInt();
    final bestTime = profile.bestTimeMs == 0
        ? '—'
        : '${(profile.bestTimeMs / 1000).toStringAsFixed(1)}s';
    final accuracy = (profile.accuracy * 100).round();
    final nextTier = profile.nextTier;
    final xpTarget = nextTier == null
        ? '${formatXp(profile.totalXp)} XP · TOP RANK'
        : '${formatXp(profile.totalXp)} / ${formatXp(nextTier.minXp)} XP';

    return Scaffold(
      backgroundColor: CyberPalette.background,
      body: CyberBackdrop(
        child: SafeArea(
          child: DojoFrame(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.electric_bolt,
                      color: CyberPalette.cyan,
                      size: 38,
                      shadows: [
                        Shadow(color: CyberPalette.blue, blurRadius: 16),
                      ],
                    ),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BRAINSPEED IQ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: CyberPalette.text,
                              fontWeight: FontWeight.w900,
                              fontSize: 21,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'MATH DUEL ARENA',
                            style: TextStyle(
                              color: CyberPalette.muted,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (profile.isProUser) ...[
                      const _ProPill(),
                      const SizedBox(width: 7),
                    ],
                    _CoinPill(coins: profile.coins),
                  ],
                ),
                const SizedBox(height: 16),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _CyberCharacterCard(
                            isRival: false,
                            name: profile.nickname.isEmpty
                                ? 'HERO'
                                : profile.nickname.toUpperCase(),
                            detail: '${profile.forgedTier.label} · LV $currentLevel',
                            stats: 'ACCURACY $accuracy% · BEST $bestTime',
                            pro: profile.isProUser,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CyberCharacterCard(
                            isRival: true,
                            name: 'RIVAL',
                            detail: 'AI SPARRING PARTNER',
                            stats: 'MATCH READY · LV $currentLevel',
                          ),
                        ),
                      ],
                    ),
                    const IgnorePointer(child: _VersusBadge()),
                  ],
                ),
                const SizedBox(height: 15),
                CyberPanel(
                  accent: CyberPalette.blue,
                  padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                  child: Row(
                    children: [
                      RankBadge(
                        tier: profile.forgedTier,
                        size: 76,
                        glow: profile.isProUser,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${profile.forgedTier.label} · LEVEL $currentLevel',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: CyberPalette.text,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                Text(
                                  'STREAK: ${profile.streak}',
                                  style: const TextStyle(
                                    color: CyberPalette.muted,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${level.band.label} TRACK · ${level.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: CyberPalette.muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              xpTarget,
                              style: const TextStyle(
                                color: CyberPalette.text,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _NeonProgressBar(
                              progress: profile.forgedTier.progress(profile.totalXp),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedCoreLevels / 120 MATH LEVELS COMPLETE',
                              style: const TextStyle(
                                color: CyberPalette.cyan,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                CyberPrimaryButton(
                  label: 'START BATTLE',
                  subtitle: 'LEVEL $currentLevel · ${level.title.toUpperCase()}',
                  onPressed: () => _start(context),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _CyberMenuButton(
                        label: 'RANK',
                        icon: Icons.emoji_events_rounded,
                        accent: CyberPalette.blue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const RankScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CyberMenuButton(
                        label: 'SHOP',
                        icon: Icons.shopping_bag_rounded,
                        accent: CyberPalette.pink,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const ShopScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: _CyberMenuButton(
                        label: profile.isProUser ? 'PRO ACTIVE' : 'GO PRO',
                        icon: Icons.star_rounded,
                        accent: CyberPalette.gold,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const ProUpgradeScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CyberMenuButton(
                        label: 'SETTINGS',
                        icon: Icons.settings_rounded,
                        accent: CyberPalette.muted,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                _LevelMapTicker(
                  currentLevel: currentLevel,
                  onTap: () => _openLevelMap(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CyberCharacterCard extends StatelessWidget {
  const _CyberCharacterCard({
    required this.isRival,
    required this.name,
    required this.detail,
    required this.stats,
    this.pro = false,
  });

  final bool isRival;
  final String name;
  final String detail;
  final String stats;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    final accent = isRival ? CyberPalette.pink : CyberPalette.blue;
    return SizedBox(
      height: 250,
      child: CyberPanel(
        accent: accent,
        radius: 23,
        padding: const EdgeInsets.fromLTRB(9, 10, 9, 10),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  isRival ? 'RIVAL' : 'HERO',
                  style: const TextStyle(
                    color: CyberPalette.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Image.asset(
                isRival
                    ? 'assets/images/rival_avatar.png'
                    : 'assets/images/hero_avatar.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                semanticLabel: isRival ? 'Rival portrait' : 'Hero portrait',
              ),
            ),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CyberPalette.text,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accent == CyberPalette.blue
                    ? CyberPalette.cyan
                    : CyberPalette.pink,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stats,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CyberPalette.muted,
                fontWeight: FontWeight.w700,
                fontSize: 8,
              ),
            ),
            if (pro) ...[
              const SizedBox(height: 3),
              const Text(
                'PRO',
                style: TextStyle(
                  color: CyberPalette.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 8,
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VersusBadge extends StatelessWidget {
  const _VersusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [CyberPalette.gold, Color(0xFFFF8A3D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFFFF0BD), width: 2),
        boxShadow: const [
          BoxShadow(color: CyberPalette.gold, blurRadius: 16, spreadRadius: 1),
          BoxShadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: const Text(
        'VS',
        style: TextStyle(
          color: Color(0xFF17101A),
          fontWeight: FontWeight.w900,
          fontSize: 20,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _NeonProgressBar extends StatelessWidget {
  const _NeonProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth * progress.clamp(0.0, 1.0).toDouble();
          return SizedBox(
            width: constraints.maxWidth,
            height: 8,
            child: Stack(
              children: [
                Container(
                  width: constraints.maxWidth,
                  height: 8,
                  color: const Color(0xFF27324A),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  width: width,
                  height: 8,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CyberPalette.blue,
                        CyberPalette.purple,
                        CyberPalette.pink,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CyberMenuButton extends StatelessWidget {
  const _CyberMenuButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            height: 68,
            decoration: BoxDecoration(
              color: CyberPalette.panelDeep.withValues(alpha: 0.95),
              borderRadius: radius,
              border: Border.all(color: accent.withValues(alpha: 0.75), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: accent, size: 25),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CyberPalette.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
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

class _LevelMapTicker extends StatelessWidget {
  const _LevelMapTicker({
    required this.currentLevel,
    required this.onTap,
  });

  final int currentLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CyberPalette.panelDeep.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CyberPalette.pink.withValues(alpha: 0.72)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, color: CyberPalette.pink, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'AGE-BASED MATH QUEST · ',
                        style: TextStyle(color: CyberPalette.cyan),
                      ),
                      TextSpan(
                        text: '120 LEVELS · YOU ARE ON $currentLevel',
                        style: const TextStyle(color: CyberPalette.pink),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios, color: CyberPalette.muted, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF25233A), Color(0xFF11192B)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: CyberPalette.gold.withValues(alpha: 0.9), width: 1.3),
        boxShadow: [
          BoxShadow(color: CyberPalette.gold.withValues(alpha: 0.18), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: CyberPalette.gold, size: 23),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: CyberPalette.text,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProPill extends StatelessWidget {
  const _ProPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: CyberPalette.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: CyberPalette.gold.withValues(alpha: 0.8)),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: CyberPalette.gold,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}
