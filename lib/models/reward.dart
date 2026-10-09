enum SpeedBand {
  lightning(
    title: 'Lightning Fast',
    emoji: '⚡',
    coins: 20,
    xp: 40,
  ),
  sharp(
    title: 'Sharp Brain',
    emoji: '🎯',
    coins: 10,
    xp: 20,
  ),
  good(
    title: 'Good Work',
    emoji: '👍',
    coins: 5,
    xp: 10,
  ),
  solved(
    title: 'Solved',
    emoji: '🧠',
    coins: 0,
    xp: 5,
  );

  const SpeedBand({
    required this.title,
    required this.emoji,
    required this.coins,
    required this.xp,
  });

  final String title;
  final String emoji;
  final int coins;
  final int xp;
}

class RewardResult {
  const RewardResult({
    required this.seconds,
    required this.band,
    required this.coins,
    required this.baseXp,
    required this.xp,
    required this.xpDoubled,
  });

  final double seconds;
  final SpeedBand band;
  final int coins;
  final int baseXp;
  final int xp;
  final bool xpDoubled;

  String get headline => 'Solved in ${seconds.toStringAsFixed(1)}s!';
}
