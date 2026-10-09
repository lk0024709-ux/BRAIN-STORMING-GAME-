import 'package:brain_speed_iq/models/rank_tier.dart';
import 'package:brain_speed_iq/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('thresholds match Bronze, Silver, Gold, Diamond', () {
    expect(RankTier.bronze.minXp, 0);
    expect(RankTier.silver.minXp, 1000);
    expect(RankTier.gold.minXp, 5000);
    expect(RankTier.diamond.minXp, 20000);
    expect(RankTier.earnedFor(999), RankTier.bronze);
    expect(RankTier.earnedFor(1000), RankTier.silver);
    expect(RankTier.earnedFor(4999), RankTier.silver);
    expect(RankTier.earnedFor(5000), RankTier.gold);
    expect(RankTier.earnedFor(19999), RankTier.gold);
    expect(RankTier.earnedFor(20000), RankTier.diamond);
  });

  test('evolve stays locked until the player forges the next medal', () {
    final almost = UserProfile.fresh().copyWith(totalXp: 999);
    expect(almost.canEvolve, isFalse);
    expect(almost.forgedTier.progress(999), closeTo(0.999, 0.001));

    final ready = almost.copyWith(totalXp: 1000);
    expect(ready.canEvolve, isTrue);
    expect(ready.forgedTier, RankTier.bronze);
    expect(ready.nextTier, RankTier.silver);

    final forged = ready.copyWith(forgedRankIndex: RankTier.silver.index);
    expect(forged.canEvolve, isFalse);
    expect(forged.forgedTier, RankTier.silver);
  });
}
