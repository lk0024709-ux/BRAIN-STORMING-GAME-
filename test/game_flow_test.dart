import 'dart:math';

import 'package:brain_speed_iq/config/app_config.dart';
import 'package:brain_speed_iq/controllers/game_controller.dart';
import 'package:brain_speed_iq/controllers/profile_controller.dart';
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
    generator: QuestionGenerator(random: Random(7)),
    random: Random(11),
  );
}

void main() {
  test('correct answers unlock the next age-based campaign level', () async {
    final profile = await makeAdultProfile();
    final game = makeGame(profile)..startSession();

    expect(game.levelNumber, 1);
    expect(game.levelInfo.title, 'Advanced BODMAS');
    await game.submit(game.question!.correctIndex);

    expect(profile.profile.levelsCompleted, 1);
    expect(game.levelNumber, 1); // The solved level stays visible in its reward.
    await game.nextRound();
    expect(game.levelNumber, 2);
    expect(game.levelInfo.title, 'Advanced BODMAS');
    game.dispose();
  });

  test('a missed answer does not unlock another level', () async {
    final profile = await makeAdultProfile();
    final game = makeGame(profile)..startSession();
    final wrongIndex = (game.question!.correctIndex + 1) % 4;

    await game.submit(wrongIndex);
    expect(game.hasPendingSecondChance, isTrue);
    await game.finalizeMiss();
    await game.nextRound();

    expect(profile.profile.levelsCompleted, 0);
    expect(game.levelNumber, 1);
    game.dispose();
  });

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
