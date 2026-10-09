import 'package:audioplayers/audioplayers.dart';
import 'package:dope_wars_atl/services/sound_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// audioplayers resolves an `AssetSource` as `<AudioCache.prefix><path>`.
/// A path that already carries the prefix resolves to `assets/assets/...`,
/// which fails at runtime: silence for the player, a FATAL for Crashlytics.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final path in SoundService.bundled) {
    test('$path loads through the audioplayers prefix', () async {
      expect(AudioCache().prefix, 'assets/');
      expect(
        path.startsWith('assets/'),
        isFalse,
        reason: 'path already carries the prefix: assets/$path',
      );
      // Throws FlutterError if the bundle has no entry for the resolved key.
      await rootBundle.load('${AudioCache().prefix}$path');
    });
  }
}
