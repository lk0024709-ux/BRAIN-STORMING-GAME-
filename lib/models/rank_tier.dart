enum RankTier {
  bronze(minXp: 0, label: 'BRONZE', motto: 'The spark is lit.'),
  silver(minXp: 1000, label: 'SILVER', motto: 'The mind is sharpening.'),
  gold(minXp: 5000, label: 'GOLD', motto: 'A forged brain.'),
  diamond(minXp: 20000, label: 'DIAMOND', motto: 'Peak rank. The dojo is yours.');

  const RankTier({
    required this.minXp,
    required this.label,
    required this.motto,
  });

  final int minXp;
  final String label;
  final String motto;

  RankTier? get next {
    final nextIndex = index + 1;
    if (nextIndex >= RankTier.values.length) return null;
    return RankTier.values[nextIndex];
  }

  static RankTier fromIndex(int index) {
    if (index <= 0) return RankTier.bronze;
    if (index >= RankTier.values.length) return RankTier.diamond;
    return RankTier.values[index];
  }

  /// Highest tier whose threshold the player has already passed.
  static RankTier earnedFor(int xp) {
    var tier = RankTier.bronze;
    for (final candidate in RankTier.values) {
      if (xp >= candidate.minXp) tier = candidate;
    }
    return tier;
  }

  /// Progress from this forged tier toward the next threshold.
  double progress(int xp) {
    final upcoming = next;
    if (upcoming == null) return 1;
    final span = upcoming.minXp - minXp;
    if (span <= 0) return 1;
    return ((xp - minXp) / span).clamp(0.0, 1.0);
  }
}
