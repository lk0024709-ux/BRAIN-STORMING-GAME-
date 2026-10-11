import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../config/app_config.dart';
import '../services/battle_music_player.dart';

/// Owns the single battle music player for the whole app.
///
/// Screens never call the player directly. They declare interest with
/// [enterBattle] and [exitBattle], using their State object as the owner.
/// Route rebuilds, repeated enter calls, and overlapping screens therefore
/// cannot start a second track, and the player is reconciled in order:
///
/// * Plays only while at least one battle owner exists, music is switched on,
///   and the app is in the foreground.
/// * Pauses while a battle is open but the app is in the background, so the
///   track resumes where it stopped.
/// * Stops when the last battle owner leaves, or when music is switched off.
///
/// Playback never blocks battle startup. Plugin failures are caught here, the
/// music is marked unavailable, and it gets one retry at the next battle.
class MusicController extends ChangeNotifier with WidgetsBindingObserver {
  MusicController({
    required BattleMusicPlayer player,
    required bool enabled,
    required Future<void> Function(bool enabled) persist,
    bool observeLifecycle = true,
    String assetPath = AppConfig.battleMusicAsset,
    double volume = AppConfig.battleMusicVolume,
  })  : _player = player,
        _enabled = enabled,
        _persist = persist,
        _assetPath = assetPath,
        _volume = volume {
    if (observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }
  }

  final BattleMusicPlayer _player;
  final Future<void> Function(bool enabled) _persist;
  final String _assetPath;
  final double _volume;

  bool _enabled;
  bool _foreground = true;
  bool _unavailable = false;
  bool _disposed = false;
  bool _observingLifecycle = false;
  _Output _output = _Output.silent;
  final Set<Object> _battleOwners = <Object>{};
  Future<void> _queue = Future<void>.value();

  /// Whether the user wants battle music. Persisted separately from sound
  /// effects.
  bool get enabled => _enabled;

  /// True while at least one battle screen is open.
  bool get inBattle => _battleOwners.isNotEmpty;

  /// True only while the track is audibly playing.
  bool get isPlaying => _output == _Output.playing;

  /// True after the audio plugin failed. Music stays silent until the next
  /// battle, and gameplay continues normally.
  bool get unavailable => _unavailable;

  /// Declares that [owner] (normally a State object) is in a battle screen.
  void enterBattle(Object owner) {
    if (_disposed) return;
    final wasIdle = _battleOwners.isEmpty;
    if (!_battleOwners.add(owner)) return;
    if (wasIdle) _unavailable = false; // One retry per battle after a failure.
    _schedule();
  }

  /// Withdraws [owner]. Stops the track when no battle owner remains.
  void exitBattle(Object owner) {
    if (_disposed) return;
    if (!_battleOwners.remove(owner)) return;
    _schedule();
  }

  /// Switches battle music on or off and remembers the choice.
  Future<void> setEnabled(bool value) async {
    if (_disposed || _enabled == value) return;
    _enabled = value;
    notifyListeners();
    _schedule();
    try {
      await _persist(value);
    } catch (error, stackTrace) {
      debugPrint('Could not save the music setting: $error\n$stackTrace');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _schedule();
  }

  void _schedule() {
    _queue = _queue.then((_) => _reconcile()).catchError(
      (Object error, StackTrace stackTrace) {
        debugPrint('Battle music failed: $error\n$stackTrace');
        _markUnavailable();
      },
    );
  }

  Future<void> _reconcile() async {
    if (_disposed) return;

    // While unavailable we never start audio, but we still stop or pause a
    // track that a failed call may have left running.
    final wantsPlaying = _enabled && _foreground && inBattle && !_unavailable;
    if (wantsPlaying) {
      if (_output == _Output.playing) return;
      if (_output == _Output.paused) {
        await _player.resume();
      } else {
        await _player.playLoop(_assetPath, volume: _volume);
      }
      _setOutput(_Output.playing);
    } else if (inBattle && _enabled) {
      // Battle still open, but the app is backgrounded: keep the position.
      if (_output == _Output.playing) {
        await _player.pause();
        _setOutput(_Output.paused);
      }
    } else if (_output != _Output.silent) {
      // Battle closed or music muted: release the track.
      await _player.stop();
      _setOutput(_Output.silent);
    }
  }

  void _setOutput(_Output next) {
    if (_output == next) return;
    _output = next;
    if (!_disposed) notifyListeners();
  }

  void _markUnavailable() {
    // The real player state is unknown after a failure. Stop it when the
    // battle closes, and let the next battle start it again.
    _output = _Output.unknown;
    _unavailable = true;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
    _battleOwners.clear();
    // Queued after any in-flight work, so the player is stopped and released in
    // order. Errors here are ignored because the app is shutting down.
    _queue = _queue.then((_) async {
      try {
        if (_output != _Output.silent) await _player.stop();
      } catch (_) {
        // Best effort on shutdown.
      }
      try {
        await _player.dispose();
      } catch (_) {
        // Best effort on shutdown.
      }
    });
    super.dispose();
  }
}

enum _Output { silent, playing, paused, unknown }
