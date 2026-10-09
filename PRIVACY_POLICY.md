# BrainSpeed IQ Privacy Policy

Last updated: 9 October 2026

BrainSpeed IQ is an educational brain-training game. This policy explains what stays on the device and when advertising software is allowed to run. The same text is shown inside the app.

## 1. What we store

Progress is stored only on the device, using local storage (SharedPreferences). That includes nickname, age, coin balance, total XP, rank, sound preference, cosmetics, and whether Pro is unlocked. There is no account and no developer-run user server.

## 2. Age and COPPA

An age must be set before play. If the saved age is under 13:

- The advertising SDK is not initialized.
- Banner, interstitial, and rewarded ads are not requested.
- Meta Audience Network is not contacted.
- The advertising ID is not used for that player.

Question difficulty still adapts. Tracking does not start. If a player changes age from 13+ to under 13 during a session where ads already started, ads stop immediately and a restart finishes child-safe mode.

Players aged 13 to 17 are treated as teens for ad requests: non-personalized ads and a tighter content rating. Players 18+ may receive ads allowed by their consent choice.

## 3. Ads

For eligible players, the app uses Google AdMob. Meta Audience Network can fill those requests through AdMob mediation.

- Interstitial, after every 3 correctly completed rounds, unless Pro is active.
- Rewarded, only if the player taps a watch-ad button.
- Banner, on the Rank and Shop screens, unless Pro is active.

Pro turns banner and interstitial ads off immediately. Google and Meta process ad requests under their own policies. In regions that require a consent form, the app shows Google's User Messaging Platform form before requesting ads.

## 4. Purchases

Pro is a non-consumable sold by Google Play, product id `brainspeed_iq_pro`. Google processes payment. The app stores an `isProUser` flag locally after the store reports a purchased or restored transaction. Card numbers are not received by the app.

## 5. Children and purchases

If the saved age is under 13, a parent gate (a simple math check) is required before the purchase sheet opens.

## 6. Choices

Training data can be reset in Settings. This policy and the Terms are available in the app. Where the consent form requires it, Settings shows a privacy-options button. Uninstalling the app deletes local progress from the device.

## 7. Contact

support@brainspeed.iq

Replace this contact address, and have counsel review the policy, before a public store release.
