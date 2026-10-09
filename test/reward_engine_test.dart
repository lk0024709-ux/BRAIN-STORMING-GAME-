import 'package:brain_speed_iq/models/reward.dart';
import 'package:brain_speed_iq/services/reward_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = RewardEngine();

  RewardResult at(double seconds, {bool pro = false}) {
    return engine.evaluate(
      elapsed: Duration(milliseconds: (seconds * 1000).round()),
      isPro: pro,
    );
  }

  test('speed bands match the reward table, including exact edges', () {
    expect(at(0.1).band, SpeedBand.lightning);
    expect(at(5.0).band, SpeedBand.lightning);
    expect(at(5.0).coins, 20);
    expect(at(5.0).xp, 40);

    expect(at(5.1).band, SpeedBand.sharp);
    expect(at(12.0).band, SpeedBand.sharp);
    expect(at(12.0).coins, 10);
    expect(at(12.0).xp, 20);

    expect(at(12.1).band, SpeedBand.good);
    expect(at(25.0).band, SpeedBand.good);
    expect(at(25.0).coins, 5);
    expect(at(25.0).xp, 10);

    expect(at(25.1).band, SpeedBand.solved);
    expect(at(40).coins, 0);
    expect(at(40).xp, 5);
  });

  test('pro doubles XP and leaves coins alone', () {
    final normal = at(4.2);
    final pro = at(4.2, pro: true);
    expect(normal.headline, 'Solved in 4.2s!');
    expect(pro.coins, normal.coins);
    expect(pro.xp, normal.xp * 2);
    expect(pro.xpDoubled, isTrue);
    expect(pro.baseXp, 40);
  });
}
