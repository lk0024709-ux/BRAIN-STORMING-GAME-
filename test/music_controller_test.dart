import 'package:brain_speed_iq/config/app_config.dart';
import 'package:brain_speed_iq/controllers/music_controller.dart';
import 'package:brain_speed_iq/services/storage_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_battle_music_player.dart';

const _track = 'audio/battle_loop.ogg';

/// Lets queued controller work (microtasks and zero-delay futures) finish.
Future<void> flush() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

MusicController makeController(
  FakeBattleMusicPlayer player, {
  bool enabled = true,
  List<bool>? persisted,
}) {
  return MusicController(
    player: player,
    enabled: enabled,
    persist: (value) async => persisted?.add(value),
    // Lifecycle is driven directly in these tests. The widget tests cover the
    // real WidgetsBinding wiring.
    observeLifecycle: false,
  );
}

void main() {
  test('nothing plays until a battle opens', () async {
    final player = FakeBattleMusicPlayer();
    final music = makeController(player);
    await flush();

    expect(player.calls, isEmpty);
    expect(music.isPlaying, isFalse);
    music.dispose();
  });

  test('a battle starts one looping track at the quiet battle volume', () async {
    final player = FakeBattleMusicPlayer();
    final music = makeController(player);
    final battle = Object();

    music.enterBattle(battle);
    await flush();

    expect(player.calls, ['playLoop:$_track']);
    expect(player.lastAsset, _track);
    expect(player.lastVolume, AppConfig.battleMusicVolume);
    expect(player.lastVolume, lessThanOrEqualTo(0.5));
    expect(music.isPlaying, isTrue);
    music.dispose();
  });

  test('route rebuilds and repeated enters never start a second track',
      () async {
    final player = FakeBattleMusicPlayer();
    final music = makeController(player);
    final first = Object();
    final second = Object();

    music.enterBattle(first);
    music.enterBattle(first); // Same screen rebuilt or re-entered.
    music.enterBattle(second); // An overlapping battle surface.
    await flush();

    expect(player.playLoopCount, 1);
    expect(player.countOf('stop'), 0);
    music.dispose();
  });

  test('the track keeps playing until the last battle owner leaves', () async {
    final player = FakeBattleMusicPlayer();
    final music = makeController(player);
    final first = Object();
    final second = Object();
    music
      ..enterBattle(first)
      ..enterBattle(second);
    await flush();

    music.exitBattle(first);
    await flush();
    expect(player.playing, isTrue);
    expect(player.countOf('stop'), 0);

    music.exitBattle(second);
    await flush();
    expect(player.countOf('stop'), 1);
    expect(player.playing, isFalse);
    expect(music.isPlaying, isFalse);
    music.dispose();
  });

  test('leaving gameplay stops the track; a new battle restarts it', () async {
    final player = FakeBattleMusicPlayer();
    final music = makeController(player);
    final battle = Object();

    music.enterBattle(battle);
    await flush();
    music.exitBattle(battle);
    await flush();
    expect(player.calls, ['playLoop:$_track', 'stop']);

    music.enterBattle(Object());
    await flush();
    expect(player.playLoopCount, 2);
    expect(player.playing, isTrue);
    music.dispose();
  });

  test('backgrounding pauses the battle track and returning resumes it',
      () async {
    final player = FakeBattleMusicPlayer();
    final music = makeController(player);
    music.enterBattle(Object());
    await flush();

    music.didChangeAppLifecycleState(AppLifecycleState.paused);
    await flush();
    expect(player.countOf('pause'), 1);
    expect(player.playing, isFalse);

    music.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await flush();
    expect(player.countOf('resume'), 1);
    expect(player.playing, isTrue);
    // Resuming continues the loop. It must not restart it from the beginning.
    expect(player.playLoopCount, 1);
    music.dispose();
  });

  test('inactive and hidden states also pause, and duplicate states do not',
      () async {
    final player = FakeBattleMusicPlayer();
    final music = makeController(player);
    music.enterBattle(Object());
    await flush();

    music.didChangeAppLifecycleState(AppLifecycleState.inactive);
    music.didChangeAppLifecycleState(AppLifecycleState.hidden);
    await flush();
    expect(player.countOf('pause'), 1);

    music.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await flush();
    expect(player.countOf('resume'), 1);
    music.dispose();
  });

  test('backgrounded before a battle opens: nothing starts until foreground',
      () async {
    final player = FakeBattleMusicPlayer();
    final music = makeController(player);

    music.didChangeAppLifecycleState(AppLifecycleState.paused);
    music.enterBattle(Object());
    await flush();
    expect(player.calls, isEmpty);

    music.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await flush();
    expect(player.calls, ['playLoop:$_track']);
    music.dispose();
  });

  test('muting stops at once, persists, and unmuting resumes in the battle',
      () async {
    final player = FakeBattleMusicPlayer();
    final persisted = <bool>[];
    final music = makeController(player, persisted: persisted);
    music.enterBattle(Object());
    await flush();

    await music.setEnabled(false);
    await flush();
    expect(music.enabled, isFalse);
    expect(persisted, [false]);
    expect(player.countOf('stop'), 1);
    expect(player.playing, isFalse);

    // Still in battle, so unmuting restarts the track.
    await music.setEnabled(true);
    await flush();
    expect(persisted, [false, true]);
    expect(player.playLoopCount, 2);
    expect(player.playing, isTrue);
    music.dispose();
  });

  test('music that is switched off never starts in a battle', () async {
    final player = FakeBattleMusicPlayer();
    final music = makeController(player, enabled: false);

    music.enterBattle(Object());
    await flush();
    expect(player.calls, isEmpty);
    expect(music.inBattle, isTrue);
    music.dispose();
  });

  test('toggling music while idle changes the setting without audio calls',
      () async {
    final player = FakeBattleMusicPlayer();
    final persisted = <bool>[];
    final music = makeController(player, persisted: persisted);

    await music.setEnabled(false);
    await flush();
    expect(persisted, [false]);
    expect(player.calls, isEmpty);
    music.dispose();
  });

  test('a plugin failure never throws, marks music unavailable, and retries',
      () async {
    final player = FakeBattleMusicPlayer()..failOn.add('playLoop');
    final music = makeController(player);
    final firstBattle = Object();

    music.enterBattle(firstBattle);
    await flush();
    expect(music.unavailable, isTrue);
    expect(music.isPlaying, isFalse);

    // Still unavailable within the same battle: no retry storm.
    music.didChangeAppLifecycleState(AppLifecycleState.paused);
    music.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await flush();
    expect(player.playLoopCount, 1);

    // Closing the battle still releases the output, then the next battle gets
    // one fresh attempt. This time the plugin works.
    music.exitBattle(firstBattle);
    await flush();
    expect(player.countOf('stop'), 1);

    player.failOn.clear();
    music.enterBattle(Object());
    await flush();
    expect(player.playLoopCount, 2);
    expect(music.unavailable, isFalse);
    expect(music.isPlaying, isTrue);
    music.dispose();
  });

  test('a failed pause still stops the track when the battle closes', () async {
    final player = FakeBattleMusicPlayer()..failOn.add('pause');
    final music = makeController(player);
    final battle = Object();
    music.enterBattle(battle);
    await flush();

    music.didChangeAppLifecycleState(AppLifecycleState.paused);
    await flush();
    expect(music.unavailable, isTrue);

    music.exitBattle(battle);
    await flush();
    expect(player.countOf('stop'), 1);
    expect(player.playing, isFalse);
    music.dispose();
  });

  test('a failed mute toggle still persists the setting', () async {
    final player = FakeBattleMusicPlayer()..failOn.add('stop');
    final persisted = <bool>[];
    final music = makeController(player, persisted: persisted);
    final battle = Object();
    music.enterBattle(battle);
    await flush();

    await music.setEnabled(false);
    await flush();
    expect(persisted, [false]);
    expect(music.enabled, isFalse);
    music.dispose();
  });

  test('dispose stops and releases the player, then ignores later requests',
      () async {
    final player = FakeBattleMusicPlayer();
    final music = makeController(player);
    final battle = Object();
    music.enterBattle(battle);
    await flush();

    music.dispose();
    await flush();
    expect(player.countOf('stop'), 1);
    expect(player.countOf('dispose'), 1);
    expect(player.playing, isFalse);

    music.enterBattle(Object());
    music.exitBattle(battle);
    await flush();
    expect(player.playLoopCount, 1);
  });

  test('music preference is stored separately from sound effects', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();

    expect(storage.readMusicOn(), isTrue); // Defaults on.
    await storage.writeMusicOn(false);

    final reloaded = await StorageService.create();
    expect(reloaded.readMusicOn(), isFalse);
    expect(reloaded.read().soundOn, isTrue); // Sound effects untouched.
  });
}
