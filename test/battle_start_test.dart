import 'package:brain_speed_iq/app.dart';
import 'package:brain_speed_iq/config/app_config.dart';
import 'package:brain_speed_iq/controllers/game_controller.dart';
import 'package:brain_speed_iq/controllers/music_controller.dart';
import 'package:brain_speed_iq/screens/gameplay_screen.dart';
import 'package:brain_speed_iq/screens/home_screen.dart';
import 'package:brain_speed_iq/screens/onboarding_screen.dart';
import 'package:brain_speed_iq/screens/settings_screen.dart';
import 'package:brain_speed_iq/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_battle_music_player.dart';

const _returningProfile = <String, Object>{
  StorageService.keyOnboarding: true,
  StorageService.keyTerms: true,
  StorageService.keyNickname: 'Tester',
  StorageService.keyUserAge: 21,
};

void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required FakeBattleMusicPlayer player,
  Map<String, Object> prefs = _returningProfile,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  await tester.pumpWidget(BrainSpeedApp(musicPlayer: player));
  await tester.pumpAndSettle();
}

/// The gameplay stopwatch rebuilds every 50 ms, so `pumpAndSettle` would never
/// return. Advance time in fixed steps instead.
Future<void> _settleBriefly(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _startBattle(WidgetTester tester) async {
  await tester.ensureVisible(find.text('START BATTLE'));
  await tester.tap(find.text('START BATTLE'));
  await _settleBriefly(tester);
}

/// Leaves the battle the way a player does: close button, then LEAVE.
Future<void> _leaveBattle(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.close));
  await _settleBriefly(tester);
  await tester.tap(find.text('LEAVE'));
  await _settleBriefly(tester);
}

/// Replaces the tree so gameplay's ticker and the music controller dispose.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  testWidgets('START BATTLE opens gameplay with a generated question and level',
      (tester) async {
    _usePhoneSize(tester);
    final player = FakeBattleMusicPlayer();
    await _pumpApp(tester, player: player);
    expect(find.text('START BATTLE'), findsOneWidget);

    await _startBattle(tester);

    // No provider or rendering exception may escape the navigation.
    expect(tester.takeException(), isNull);
    expect(find.byType(GameplayScreen), findsOneWidget);
    expect(find.text('LEVEL 1 / 120'), findsOneWidget);

    final context = tester.element(find.byType(GameplayScreen));
    final question = context.read<GameController>().question;
    expect(question, isNotNull);
    expect(find.text(question!.display), findsOneWidget);
    expect(question.options, hasLength(4));

    await _unmount(tester);
  });

  testWidgets('battle music starts once when the battle opens, then stops on exit',
      (tester) async {
    _usePhoneSize(tester);
    final player = FakeBattleMusicPlayer();
    await _pumpApp(tester, player: player);

    // Home and onboarding are silent.
    expect(player.calls, isEmpty);

    await _startBattle(tester);
    expect(tester.takeException(), isNull);
    expect(player.calls, ['playLoop:audio/battle_loop.ogg']);
    expect(player.lastVolume, AppConfig.battleMusicVolume);
    expect(player.playing, isTrue);

    // Rebuilding the gameplay route must not start a duplicate track.
    await tester.pump(const Duration(milliseconds: 300));
    expect(player.playLoopCount, 1);

    await _leaveBattle(tester);
    expect(find.byType(GameplayScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(player.countOf('stop'), 1);
    expect(player.playing, isFalse);

    await _unmount(tester);
  });

  testWidgets('a new battle restarts the track after the last one stopped',
      (tester) async {
    _usePhoneSize(tester);
    final player = FakeBattleMusicPlayer();
    await _pumpApp(tester, player: player);

    await _startBattle(tester);
    await _leaveBattle(tester);
    await _startBattle(tester);

    expect(tester.takeException(), isNull);
    expect(player.playLoopCount, 2);
    expect(player.playing, isTrue);

    await _unmount(tester);
  });

  testWidgets('backgrounding in battle pauses music and returning resumes it',
      (tester) async {
    _usePhoneSize(tester);
    final player = FakeBattleMusicPlayer();
    await _pumpApp(tester, player: player);
    await _startBattle(tester);
    expect(player.playing, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(player.countOf('pause'), 1);
    expect(player.playing, isFalse);
    expect(find.byType(GameplayScreen), findsOneWidget); // Battle stays open.

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(player.countOf('resume'), 1);
    expect(player.playing, isTrue);
    expect(player.playLoopCount, 1); // Resumed, not restarted.

    await _unmount(tester);
  });

  testWidgets('the gameplay music button mutes at once and remembers the choice',
      (tester) async {
    _usePhoneSize(tester);
    final player = FakeBattleMusicPlayer();
    await _pumpApp(tester, player: player);
    await _startBattle(tester);
    expect(player.playing, isTrue);

    await tester.tap(find.byTooltip('Turn battle music off'));
    await _settleBriefly(tester);
    expect(player.countOf('stop'), 1);
    expect(player.playing, isFalse);
    expect(find.byTooltip('Turn battle music on'), findsOneWidget);

    final stored = (await tester.runAsync(StorageService.create))!;
    expect(stored.readMusicOn(), isFalse);

    await tester.tap(find.byTooltip('Turn battle music on'));
    await _settleBriefly(tester);
    expect(player.playLoopCount, 2);
    expect(player.playing, isTrue);
    expect(find.byTooltip('Turn battle music off'), findsOneWidget);

    await _unmount(tester);
  });

  testWidgets('the settings music switch is separate from sound effects',
      (tester) async {
    _usePhoneSize(tester);
    final player = FakeBattleMusicPlayer();
    await _pumpApp(tester, player: player);

    await tester.ensureVisible(find.text('SETTINGS'));
    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Battle music on'), findsOneWidget);
    expect(find.text('Sound on'), findsOneWidget);

    await tester.ensureVisible(find.text('Battle music on'));
    await tester.tap(find.text('Battle music on'));
    await tester.pumpAndSettle();
    expect(find.text('Battle music off'), findsOneWidget);
    expect(find.text('Sound on'), findsOneWidget); // Sound effects unchanged.

    final stored = (await tester.runAsync(StorageService.create))!;
    expect(stored.readMusicOn(), isFalse);
    expect(stored.read().soundOn, isTrue);

    // Music stays off for the next battle.
    // The list was scrolled to reach the music switch, so bring back the
    // arrow before tapping it.
    await tester.ensureVisible(find.byIcon(Icons.arrow_back));
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    await _startBattle(tester);
    expect(player.calls, isEmpty);

    await _unmount(tester);
  });

  testWidgets('if the audio plugin fails, START BATTLE still opens gameplay',
      (tester) async {
    _usePhoneSize(tester);
    final player = FakeBattleMusicPlayer()..failOn.add('playLoop');
    await _pumpApp(tester, player: player);

    await _startBattle(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(GameplayScreen), findsOneWidget);
    final context = tester.element(find.byType(GameplayScreen));
    expect(context.read<GameController>().question, isNotNull);
    expect(context.read<MusicController>().unavailable, isTrue);
    expect(context.read<MusicController>().isPlaying, isFalse);

    await _unmount(tester);
  });

  testWidgets('first-time players are not sent to a battle or given music',
      (tester) async {
    _usePhoneSize(tester);
    final player = FakeBattleMusicPlayer();
    await _pumpApp(tester, player: player, prefs: {});

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(player.calls, isEmpty);
    expect(tester.takeException(), isNull);

    await _unmount(tester);
  });
}
