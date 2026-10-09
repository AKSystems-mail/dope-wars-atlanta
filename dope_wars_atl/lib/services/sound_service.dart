import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Manages game sound effects using bundled WAV assets.
/// Fully offline — no network needed.
class SoundService {
  /// Paths are relative to the bundle's `assets/` directory. audioplayers'
  /// AudioCache prepends its own `assets/` prefix (`AudioCache.prefix`,
  /// default 'assets/'), so a path that already carries it resolves to
  /// `assets/assets/sounds/...` and throws `Unable to load asset`. Every path
  /// below used to have the prefix, which means no sound ever loaded — and
  /// since the failure arrives on an unawaited future, each attempt was filed
  /// in Crashlytics as a FATAL (184 events, 100% of sessions).
  static const chime = 'sounds/marta_chime.wav';
  static const carHornSound = 'sounds/car_horn.wav';
  static const cashRegisterSound = 'sounds/cash_register.wav';
  static const encounterSound = 'sounds/encounter.wav';
  static const weaponFireSound = 'sounds/weapon_fire.wav';
  static const musicLoop = 'sounds/night_loop.mp3';

  /// Every bundled sound. This is the only place audio assets are named, so it
  /// is the list the asset-existence test walks.
  static const bundled = <String>[
    chime,
    carHornSound,
    cashRegisterSound,
    encounterSound,
    weaponFireSound,
    musicLoop,
  ];

  final Map<String, AudioPlayer> _players = {};
  double _volume = 0.5;

  /// Set volume (0.0–1.0). Affects all subsequent plays.
  void setVolume(double value) {
    _volume = value.clamp(0.0, 1.0);
  }

  /// MARTA two-tone chime (train arrival).
  void playMartaChime() => _play(chime);

  /// Car horn for Ryde / Drive travel.
  void playCarHorn() => _play(carHornSound);

  /// Cash register ka-ching for buy / sell.
  void playCashRegister() => _play(cashRegisterSound);

  /// Percussive encounter alert.
  void playEncounter() => _play(encounterSound);

  /// Weapon fire crack.
  void playWeaponFire() => _play(weaponFireSound);

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
    // flutter_test has no audioplayers implementations, so the plugin channel
    // throws MissingPluginException — and because init() fires this without
    // awaiting, it lands AFTER the test completes and fails the suite anyway.
    // flutter test sets FLUTTER_TEST=true in the environment; the app never does.
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    _musicOn = true;
    try {
      final player = _music ??= AudioPlayer(playerId: 'music');
      // Configure the audio context BEFORE the first play. On Android
      // audioplayers otherwise picks a default focus/stream that a long
      // looping bed can end up muted on, while short one-shots still work —
      // which is exactly the pattern we were seeing.
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
      await player.setReleaseMode(ReleaseMode.loop);
      // One call, volume as an argument. The SFX path plays a single
      // play(AssetSource) and those are audible; the multi-call
      // setReleaseMode -> setVolume -> play sequence on a fresh player is what
      // music was doing, and it never made a sound.
      await player.play(AssetSource(musicLoop), volume: 0.8);
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
        // Handled, not awaited: a rejected channel call would otherwise reach
        // PlatformDispatcher as an unhandled error and be filed as a crash.
        p.setVolume(_volume).catchError(
          (Object e) => debugPrint('SoundService: volume failed: $e'),
        );
        return p;
      });
      player.stop();
      player.play(AssetSource(assetPath)).catchError(
        (Object e) => debugPrint('SoundService: failed to play $assetPath: $e'),
      );
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
