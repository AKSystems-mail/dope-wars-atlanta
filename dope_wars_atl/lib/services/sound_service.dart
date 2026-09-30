import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Manages game sound effects using bundled WAV assets.
/// Fully offline — no network needed.
class SoundService {
  final Map<String, AudioPlayer> _players = {};
  double _volume = 0.5;

  /// Set volume (0.0–1.0). Affects all subsequent plays.
  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  /// MARTA two-tone chime (train arrival).
  void playMartaChime() => _play('assets/sounds/marta_chime.wav');

  /// Car horn for Ryde / Drive travel.
  void playCarHorn() => _play('assets/sounds/car_horn.wav');

  /// Cash register ka-ching for buy / sell.
  void playCashRegister() => _play('assets/sounds/cash_register.wav');

  /// Percussive encounter alert.
  void playEncounter() => _play('assets/sounds/encounter.wav');

  /// Weapon fire crack.
  void playWeaponFire() => _play('assets/sounds/weapon_fire.wav');

  /// Background music. Kept out of [_players] deliberately: a looping bed
  /// must never be stopped by one-shot plays, and it has its own volume and
  /// its own on/off so muting the gunshots doesn't kill the soundtrack.
  ///
  /// LAZY on purpose: an `AudioPlayer` field initializer constructs at
  /// SoundService construction, which opens the plugin channel there. In a test
  /// harness with no platform implementation that throws MissingPluginException
  /// and fails the whole suite. Building it on first use keeps the cost off the
  /// boot path and off every test that never asks for music.
  AudioPlayer? _music;
  bool _musicOn = false;

  Future<void> startMusic() async {
    if (_musicOn) return;
    // flutter_test has no audioplayers implementation, so the plugin channel
    // throws MissingPluginException — and because init() fires this without
    // awaiting, it lands AFTER the test completes and fails the suite anyway.
    // flutter test sets FLUTTER_TEST=true in the environment; the app never does.
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _musicOn = true;
    try {
      final player = _music ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      // 0.6, not 0.35: the loop sits around -17 LUFS and is played under a
      // phone speaker, where a low bed is simply inaudible. It must still sit
      // under the SFX (which are at 0.5 with far more transient energy), so it
      // does not dominate.
      await player.setVolume(0.6);
      await player.play(AssetSource('assets/sounds/night_loop.mp3'));
    } catch (e) {
      // Release the latch on failure. Setting _musicOn before the play means a
      // failed start would otherwise leave the service believing music is
      // running: stopMusic would no-op and every later startMusic would return
      // early, so the toggle could never retry a start that failed once.
      _musicOn = false;
      debugPrint('SoundService: music failed to start: $e');
    }
  }

  Future<void> stopMusic() async {
    if (!_musicOn) return;
    _musicOn = false;
    try {
      await _music?.stop();
    } catch (e) {
      debugPrint('SoundService: music failed to stop: $e');
    }
  }

  bool get musicPlaying => _musicOn;

  void _play(String assetPath) {
    try {
      final player = _players.putIfAbsent(assetPath, () {
        final p = AudioPlayer();
        p.setVolume(_volume);
        return p;
      });
      player.stop();
      player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('SoundService: failed to play $assetPath: $e');
    }
  }

  void stopAll() {
    for (final player in _players.values) {
      player.stop();
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
    _music?.dispose();
  }
}
