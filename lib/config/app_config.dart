/// Local game, store, age, and support constants.
class AppConfig {
  AppConfig._();

  static const String appName = 'BrainSpeed IQ';
  static const String versionLabel = '1.0.0';
  static const String packageName = 'com.brainspeed.iq';

  /// Non-consumable product configured in Play Console.
  static const String proProductId = 'brainspeed_iq_pro';

  static const String supportEmail = 'support@brainspeed.iq';

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

  /// Battle-only background loop, relative to the Flutter `assets/` folder.
  /// Original instrumental track; see assets/audio/LICENSE.md.
  static const String battleMusicAsset = 'audio/battle_loop.ogg';

  /// Kept low so quiz text and answer feedback stay the focus.
  static const double battleMusicVolume = 0.35;
}

/// Players under 13 use the child profile and parent-gated purchase flow.
bool isCoppaChild(int age) => age < 13;
