import 'dart:math';

import 'package:brain_speed_iq/config/app_config.dart';
import 'package:brain_speed_iq/controllers/game_controller.dart';
import 'package:brain_speed_iq/controllers/profile_controller.dart';
import 'package:brain_speed_iq/services/ad_service.dart';
import 'package:brain_speed_iq/services/question_generator.dart';
import 'package:brain_speed_iq/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProfileController> makeAdultProfile() async {
  SharedPreferences.setMockInitialValues({});
  final profile = ProfileController(await StorageService.create());
  await profile.load();
  await profile.completeOnboarding(nickname: 'Tester', age: 21);
  return profile;
}

GameController makeGame(ProfileController profile) {
  return GameController(
    profile: profile,
    ads: AdService(),
    generator: QuestionGenerator(random: Random(7)),
    random: Random(11),
  );
}

void main() {
  test('a recoverable miss uses one paid second chance and keeps elapsed time',
      () async {
    final profile = await makeAdultProfile();
    final game = makeGame(profile)..startSession();
    final question = game.question!;
    final wrongIndex = (question.correctIndex + 1) % question.options.length;

    await Future<void>.delayed(const Duration(milliseconds: 15));
    await game.submit(wrongIndex);

    expect(game.hasPendingSecondChance, isTrue);
    expect(profile.profile.questionsSettled, 0);
    expect(game.phase, RoundPhase.resolved);

    game.onTick();
    final beforeRetry = game.elapsed.value;
    expect(await game.useSecondChance(), ToolOutcome.applied);
    expect(game.phase, RoundPhase.playing);
    expect(game.secondChanceUsed, isTrue);
    expect(profile.coins, 0); // 40 starting coins pay the 40-coin retry.

    await Future<void>.delayed(const Duration(milliseconds: 15));
    game.onTick();
    expect(game.elapsed.value, greaterThan(beforeRetry));

    await game.submit(wrongIndex);
    expect(game.failed, isTrue);
    expect(game.hasPendingSecondChance, isFalse);
    expect(profile.profile.questionsSettled, 1);
    expect(profile.profile.streak, 0);
    game.dispose();
  });

  test('two near-simultaneous hint taps spend only once', () async {
    final profile = await makeAdultProfile();
    final game = makeGame(profile)..startSession();

    final outcomes = await Future.wait<ToolOutcome>([
      game.useHint(),
      game.useHint(),
    ]);

    expect(outcomes.where((value) => value == ToolOutcome.applied), hasLength(1));
    expect(profile.coins, AppConfig.standardStartingCoins - AppConfig.hintCost);
    expect(game.hintVisible, isTrue);
    game.dispose();
  });
}
