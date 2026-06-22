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
  }
}
