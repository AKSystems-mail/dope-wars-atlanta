import 'dart:math';

class AdService {
  static const List<_Ad> _ads = [
    _Ad(
      title: 'RYDE',
      subtitle: 'Ryde or Die — Every Ride\'s a Gamble',
      asset: 'assets/ads/ryde.png',
    ),
    _Ad(
      title: 'Re-Elect Councilman',
      subtitle: 'He Gets Things Done',
      asset: 'assets/ads/councilman.png',
    ),
    _Ad(
      title: 'Get Higher',
      subtitle: 'Your Neighborhood Smoke Spot',
      asset: 'assets/ads/get_higher.png',
    ),
    _Ad(
      title: 'Certified Pre-Owned Whips',
      subtitle: '0% APR or Your Firstborn',
      asset: 'assets/ads/certified_whips.png',
    ),
    _Ad(
      title: 'The Varsity',
      subtitle: 'Eat Here or Die Trying',
      asset: 'assets/ads/the_varsity.png',
    ),
  ];

  _Ad? _currentAd;

  _Ad getRandomAd() {
    final rng = Random();
    return _ads[rng.nextInt(_ads.length)];
  }

  /// Returns the ad to show, or null if ads are disabled
  _Ad? getAdForMartaTravel() {
    _currentAd = getRandomAd();
    return _currentAd;
  }

  String? get currentAdAsset => _currentAd?.asset;
}

class _Ad {
  final String title;
  final String subtitle;
  final String asset;

  const _Ad({
    required this.title,
    required this.subtitle,
    required this.asset,
  });
}
