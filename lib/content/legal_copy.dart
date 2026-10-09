import '../config/app_config.dart';

class LegalCopy {
  LegalCopy._();

  static String get privacy => '''
BrainSpeed IQ Privacy Policy

Last updated: 9 October 2026

BrainSpeed IQ is an educational brain-training game. This policy explains what stays on your device and when advertising software is allowed to run.

1. What we store
The app stores progress only on this device, using local storage (SharedPreferences). That includes your nickname, age, coin balance, total XP, rank, sound preference, cosmetics, and whether Pro is unlocked. We do not create an account, and we do not run our own user server.

2. Age and COPPA
You must set an age before play. If the saved age is under 13:
- The advertising SDK is not initialized.
- Banner, interstitial, and rewarded ads are not requested.
- Meta Audience Network is not contacted.
- We do not use the advertising ID for that player.
Question difficulty still adapts, but tracking does not start. If a player changes age from 13+ to under 13 during a session where ads already started, ads stop immediately and a restart finishes child-safe mode.

Players aged 13 to 17 are treated as teens for ad requests: non-personalized ads and a tighter content rating. Players 18+ may receive ads allowed by their consent choice.

3. Ads
For eligible players, BrainSpeed IQ uses Google AdMob. Meta Audience Network can fill those requests through AdMob mediation. Formats:
- Interstitial, after every 3 correctly completed rounds, unless Pro is active.
- Rewarded, only if you tap a "watch ad" button.
- Banner, on the Rank and Shop screens, unless Pro is active.
Pro turns banner and interstitial ads off immediately. Google and Meta process ad requests under their own policies. In regions that require a consent form, we show Google's User Messaging Platform form before requesting ads.

4. Purchases
Pro is a non-consumable in-app product sold by Google Play (product id ${AppConfig.proProductId}). Google processes payment. We store an isProUser flag locally after the store reports a purchased or restored transaction. We do not receive your full card number.

5. Children and purchases
If the saved age is under 13, a parent gate (a simple math check) is required before the purchase sheet opens.

6. Your choices
You can reset training data in Settings. You can review this policy and the Terms inside the app. Where the consent form requires it, Settings shows a privacy-options button. Uninstalling the app deletes local progress from the device.

7. Contact
Questions: ${AppConfig.supportEmail}

This policy is written for the app as shipped in this project. Replace the contact email and have counsel review it before a public store release.
''';

  static String get terms => '''
BrainSpeed IQ Terms of Use

Last updated: 9 October 2026

By checking the box on the age screen, you agree to these terms and the Privacy Policy.

1. The game
BrainSpeed IQ is an educational drill. Questions are generated on the device. Ranks, coins, and cosmetics are game progress, not cash value, except where a store purchase says otherwise.

2. Age
You confirm the age you enter is accurate. Players under 13 get a no-ad experience. A false age can break child-privacy protections. Parents and guardians should set the age for younger players.

3. Pro
Pro is optional. It removes banner and interstitial ads, doubles XP earned from correct solves, and shows the golden nameplate plus crown badge. Price and tax are shown by Google Play before you pay. Pro is tied to the store account that bought it. Use Restore Purchases after reinstalling. Digital goods are handled under Google Play's refund rules.

4. Coins and tools
Coins are earned by solving and, for eligible players, by optional rewarded ads. Hint, 50/50, and Second Chance spend coins or tokens. They have no cash value and are not transferable.

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
