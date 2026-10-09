import '../models/reward.dart';

/// Maps a stopped stopwatch to coins and XP. Pro doubles XP only.
class RewardEngine {
  const RewardEngine();

  RewardResult evaluate({required Duration elapsed, required bool isPro}) {
    final seconds = elapsed.inMilliseconds / 1000.0;
    final band = bandFor(seconds);
    return RewardResult(
      seconds: seconds,
      band: band,
      coins: band.coins,
      baseXp: band.xp,
      xp: isPro ? band.xp * 2 : band.xp,
      xpDoubled: isPro,
    );
  }

  static SpeedBand bandFor(double seconds) {
    if (seconds <= 5.0) return SpeedBand.lightning;
    if (seconds <= 12.0) return SpeedBand.sharp;
    if (seconds <= 25.0) return SpeedBand.good;
    return SpeedBand.solved;
  }
}
