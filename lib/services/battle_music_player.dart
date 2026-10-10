import 'package:audioplayers/audioplayers.dart';

/// The small surface the battle music needs. Tests replace it with a fake, so
/// the rules in MusicController can be checked without a platform audio stack.
abstract class BattleMusicPlayer {
  /// Starts [assetPath] from the beginning on a seamless loop at [volume].
  Future<void> playLoop(String assetPath, {required double volume});

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> dispose();
}

/// Production player backed by audioplayers (MediaPlayer on Android by default,
/// AVAudioPlayer on iOS). The native player is created on first play, so
/// onboarding and the home screen never touch audio hardware.
class AudioplayersBattleMusicPlayer implements BattleMusicPlayer {
  AudioplayersBattleMusicPlayer();

  // Duck other apps' audio rather than cutting it off. Background music should
  // not take over a podcast or navigation prompt that is already playing.
  static final AudioContext _context = AudioContextConfig(
    focus: AudioContextConfigFocus.duckOthers,
  ).build();

  AudioPlayer? _player;

  AudioPlayer _ensurePlayer() => _player ??= AudioPlayer();

  @override
  Future<void> playLoop(String assetPath, {required double volume}) async {
    final player = _ensurePlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(
      AssetSource(assetPath),
      volume: volume,
      ctx: _context,
    );
  }

  @override
  Future<void> pause() async {
    await _player?.pause();
  }

  @override
  Future<void> resume() async {
    await _player?.resume();
  }

  @override
  Future<void> stop() async {
    await _player?.stop();
  }

  @override
  Future<void> dispose() async {
    final player = _player;
    _player = null;
    await player?.dispose();
  }
}
