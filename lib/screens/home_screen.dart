import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controllers/game_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/age_band.dart';
import '../models/math_level.dart';
import '../services/banter_service.dart';
import '../theme/manga_colors.dart';
import '../theme/manga_theme.dart';
import '../widgets/dialogue_strip.dart';
import '../widgets/neo_widgets.dart';
import '../widgets/rank_widgets.dart';
import 'gameplay_screen.dart';
import 'level_map_screen.dart';
import 'pro_upgrade_screen.dart';
import 'rank_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BanterService _banter = BanterService();
  BanterPair? _pair;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pair ??= _nextPair();
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _pair = _nextPair());
    });
  }

  BanterPair _nextPair() {
    final age = context.read<ProfileController>().userAge;
    return _banter.line(BanterEvent.home, age);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showLevels() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const LevelMapScreen()),
    );
  }

  void _start() {
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

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final data = profile.profile;
    final pair = _pair ?? const BanterPair('Cloud\'s ready.', 'Then start.');
    final next = data.nextTier;
    final currentLevel = data.levelsCompleted + 1;
    final levelInfo = MathLevelInfo.forAge(data.userAge, currentLevel);
    final coreLevelsDone =
        data.levelsCompleted.clamp(0, MathLevelInfo.campaignLength).toInt();
    return Scaffold(
      body: HalftoneBackground(
        child: SafeArea(
          child: DojoFrame(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'BRAINSPEED\nIQ',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          height: 0.9,
                        ),
                      ),
                    ),
                    if (data.isProUser) const ProBadge(),
                    const SizedBox(width: 8),
                    CoinChip(coins: data.coins),
                  ],
                ),
                const SizedBox(height: 14),
                DialogueStrip(
                  heroName: data.nickname.isEmpty ? 'HERO' : data.nickname.toUpperCase(),
                  heroLine: pair.hero,
                  rivalLine: pair.rival,
                  pro: data.isProUser,
                  nameplate: data.equippedNameplate,
                ),
                const SizedBox(height: 14),
                NeoBox(
                  color: MangaColors.yellow,
                  onTap: _showLevels,
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: MangaColors.white,
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
                          '$currentLevel',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              levelInfo.band.label + ' MATH QUEST',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              levelInfo.levelLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              '${levelInfo.title} · CHAPTER ${levelInfo.chapter}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: coreLevelsDone /
                                    MathLevelInfo.campaignLength,
                                minHeight: 7,
                                color: MangaColors.ink,
                                backgroundColor: MangaColors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              data.levelsCompleted >=
                                      MathLevelInfo.campaignLength
                                  ? '120 / 120 CORE LEVELS · MASTER MODE OPEN'
                                  : '$coreLevelsDone / 120 LEVELS COMPLETE · TAP TO VIEW MAP',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.map_outlined, size: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                NeoBox(
                  color: MangaColors.white,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const RankScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      RankBadge(tier: data.forgedTier, size: 72),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.forgedTier.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '${data.totalXp} XP  ·  streak ${data.streak}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            if (data.canEvolve)
                              const Text(
                                'EVOLVE RANK is ready.',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              )
                            else if (next != null)
                              Text(
                                '${next.minXp - data.totalXp} XP to ${next.label}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                MangaButton(
                  label: 'START QUIZ · LEVEL $currentLevel',
                  subtitle: '${levelInfo.title} · stopwatch starts on question',
                  color: MangaColors.pink,
                  icon: Icons.bolt,
                  onPressed: _start,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MangaButton(
                        label: 'RANK',
                        color: MangaColors.rankFill(data.forgedTier),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const RankScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MangaButton(
                        label: 'SHOP',
                        color: MangaColors.yellow,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ShopScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: MangaButton(
                        label: data.isProUser ? 'PRO ACTIVE' : 'GO PRO',
                        color: MangaColors.gold,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const ProUpgradeScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: MangaButton(
                        label: 'SETTINGS',
                        color: MangaColors.white,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
