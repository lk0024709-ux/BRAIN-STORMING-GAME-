/// Store, ad, and support constants.
///
/// Production ad unit IDs are injected at build time so a debug run never
/// accidentally serves live inventory:
///
/// ```bash
/// flutter build apk --release \
///   --dart-define=USE_TEST_ADS=false \
///   --dart-define=ADMOB_BANNER_ID=ca-app-pub-xxx/yyy \
///   --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-xxx/yyy \
///   --dart-define=ADMOB_REWARDED_ID=ca-app-pub-xxx/yyy
/// ```
///
/// The Android AdMob *app* id is a manifest placeholder (`ADMOB_APP_ID`),
/// not a Dart define. See README.
class AppConfig {
  AppConfig._();

  static const String appName = 'BrainSpeed IQ';
  static const String versionLabel = '1.0.0';
  static const String packageName = 'com.brainspeed.iq';

  /// Non-consumable product configured in Play Console.
  static const String proProductId = 'brainspeed_iq_pro';

  static const String supportEmail = 'support@brainspeed.iq';

  static const bool useTestAds = bool.fromEnvironment(
    'USE_TEST_ADS',
    defaultValue: true,
  );

  static const String _bannerOverride = String.fromEnvironment('ADMOB_BANNER_ID');
  static const String _interstitialOverride = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID',
  );
  static const String _rewardedOverride = String.fromEnvironment(
    'ADMOB_REWARDED_ID',
  );

  /// Google's official sample units. Safe for development.
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';

  static String get bannerUnitId =>
      _pick(_bannerOverride, testBannerId);

  static String get interstitialUnitId =>
      _pick(_interstitialOverride, testInterstitialId);

  static String get rewardedUnitId => _pick(_rewardedOverride, testRewardedId);

  static String _pick(String override, String testId) {
    if (useTestAds || override.isEmpty) return testId;
    return override;
  }

  static const int interstitialEvery = 3;
  static const int rewardedCoinPayout = 20;
  static const int childStartingCoins = 80;
  static const int standardStartingCoins = 40;

  static const int hintCost = 10;
  static const int fiftyCost = 25;
  static const int secondChanceCost = 40;

  static const int hintPackCount = 3;
  static const int hintPackCost = 24;
  static const int fiftyPackCount = 3;
  static const int fiftyPackCost = 60;
  static const int chancePackCount = 2;
  static const int chancePackCost = 64;
}

/// COPPA line: under 13 is a child even if the math band is already "teen".
bool isCoppaChild(int age) => age < 13;
