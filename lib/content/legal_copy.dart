import '../config/app_config.dart';

class LegalCopy {
  LegalCopy._();

  static String get privacy => '''
BrainSpeed IQ Privacy Policy

Last updated: 10 October 2026

BrainSpeed IQ is an educational brain-training game. Your profile and training progress are stored on your device. The app does not include advertising, ad tracking, or analytics services.

1. What we store
The app stores your nickname, age, coin balance, total XP, rank, sound preference, cosmetics, and Pro status in local storage (SharedPreferences). We do not create an account or operate a user-data server.

2. Age and children
You set an age before play. Age is used to choose an appropriate question difficulty and starting coin balance. If the saved age is under 13, a parent check is required before opening a purchase flow. Age is not used for advertising; the app does not show ads.

3. Advertising and tracking
BrainSpeed IQ does not display banner, interstitial, or rewarded ads. It does not include AdMob, Meta Audience Network, an advertising identifier, ad mediation, or an advertising-consent SDK. The app does not use third-party analytics or ad tracking.

4. Purchases
Pro is a non-consumable in-app product sold by Google Play (product id ${AppConfig.proProductId}). Google Play handles payment and account details. The app receives purchase status from Google Play Billing and stores the Pro-unlocked flag locally. We do not receive your full card number.

5. Your choices
You can reset training data in Settings and review this policy and the Terms in the app. Uninstalling the app removes its local data, subject to your device's backup settings.

6. Contact
Questions: ${AppConfig.supportEmail}

This policy describes the app in this project. Replace the contact email and have counsel review it before a public store release.
''';

  static String get terms => '''
BrainSpeed IQ Terms of Use

Last updated: 10 October 2026

By checking the box on the age screen, you agree to these terms and the Privacy Policy.

1. The game
BrainSpeed IQ is an educational drill. Questions are generated on the device. Ranks, coins, and cosmetics are game progress, not cash value, except where a store purchase says otherwise.

2. Age
You confirm the age you enter is accurate. Age selects an appropriate question difficulty and starting coin balance. Parents and guardians should set the age for younger players. A parent check is required before an under-13 player opens a purchase flow.

3. Pro
Pro is optional. It doubles XP earned from correct solves and unlocks the golden nameplate and crown badge. Price and tax are shown by Google Play before you pay. Pro is tied to the store account that bought it. Use Restore Purchases after reinstalling. Digital goods are handled under Google Play's refund rules.

Product id: ${AppConfig.proProductId}.

4. Coins and tools
Coins are earned by solving rounds. Hint, 50/50, and Second Chance tools spend coins or tokens. They have no cash value and are not transferable.

5. Fair play
Do not cheat the billing system, attack the app, or use it to harm someone else. We may refuse support for modified builds.

6. No warranty
The game is provided as-is for training and entertainment. It is not a medical, psychological, or school assessment. Solve times and ranks are game feedback, not an official IQ score.

7. Liability
To the extent the law allows, the developer is not liable for indirect or lost-progress damages. Nothing in these terms limits liability that cannot legally be limited.

8. Changes
If these terms change in a later version, the in-app text will show a new date. Continuing to play after an update means you accept the new text.

9. Contact
${AppConfig.supportEmail}
''';
}
