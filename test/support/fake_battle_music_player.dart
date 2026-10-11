import 'package:brain_speed_iq/services/battle_music_player.dart';
import 'package:flutter/services.dart';

/// Records every player call so tests can assert start, loop, pause, resume,
/// and stop without any platform audio stack.
class FakeBattleMusicPlayer implements BattleMusicPlayer {
  /// Ordered log of calls, e.g. `playLoop:audio/battle_loop.ogg`, `pause`.
  final List<String> calls = <String>[];

  /// Method names that throw a PlatformException when called.
  final Set<String> failOn = <String>{};

  /// Whether a track is currently audible according to this fake.
  bool playing = false;

  String? lastAsset;
  double? lastVolume;

  int countOf(String call) => calls.where((c) => c == call).length;

  int get playLoopCount =>
      calls.where((c) => c.startsWith('playLoop:')).length;

  void _record(String name) {
    calls.add(name);
    if (failOn.contains(name.split(':').first)) {
      throw PlatformException(code: 'fake_failure', message: '$name failed');
    }
  }

  @override
  Future<void> playLoop(String assetPath, {required double volume}) async {
    _record('playLoop:$assetPath');
    lastAsset = assetPath;
    lastVolume = volume;
    playing = true;
  }

  @override
  Future<void> pause() async {
    _record('pause');
    playing = false;
  }

  @override
  Future<void> resume() async {
    _record('resume');
    playing = true;
  }

  @override
  Future<void> stop() async {
    _record('stop');
    playing = false;
  }

  @override
  Future<void> dispose() async {
    _record('dispose');
    playing = false;
  }
}
