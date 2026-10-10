# BrainSpeed IQ

Neo-brutalist manga brain-training game. Procedural questions, a running stopwatch (no countdown), pure XP ranks, AdMob + Meta mediation, and a lifetime Pro plan.

## Jaldi shuru kaise karein

Flutter **3.38.1+** chahiye (stable channel — CI `3.47.6` pin karta hai, aur har push pe analyze + test + release APK chalata hai). Machine pe ye steps kaafi hain:

```bash
flutter pub get
flutter test
flutter run
```

Pehli screen age slider (6–60+) aur Terms + Privacy checkbox maangti hai. Slider hilaaye bina dojo nahi khulega. Under 13 pe ads SDK start hi nahi hota.

## What you get

- **Onboarding** saves `userAge`, terms acceptance, nickname, and a starting coin purse (80 under 13, 40 otherwise).
- **QuestionGenerator** builds every drill. Nothing is a hardcoded quiz bank.
  - Under 10: single- and double-digit addition and subtraction.
  - 10–16: multiplication, basic BODMAS, missing-number series.
  - 17+: multi-operator BODMAS, rapid series, decimals.
- **Gameplay** is a comic page: hero, rival, thought cloud, 2×2 panels.
  - Hint costs 10 coins and drops a yellow banner inside the cloud.
  - 50/50 costs 25 coins and kills two wrong panels.
  - Second Chance costs 40 coins after a miss. The stopwatch keeps running.
  - Short on coins and 13+? Watch an ad for a free hint or +20 coins.
- **Stopwatch rewards**
  - ≤ 5.0s Lightning Fast — +20 coins, +40 XP
  - 5.1–12.0s Sharp Brain — +10 coins, +20 XP
  - 12.1–25.0s Good Work — +5 coins, +10 XP
  - slower Solved — +0 coins, +5 XP
  - Pro doubles XP only.
- **Ranks** are forged, not automatic. Bronze 0–1k, Silver 1k–5k, Gold 5k–20k, Diamond 20k+. Cross a threshold and **Evolve Rank** plays the medal-forging celebration.
- **Ads**: interstitial every 3 correct levels, rewarded on demand, banners on Rank and Shop. Meta Audience Network is mediated through AdMob.
- **Pro** (`brainspeed_iq_pro`, non-consumable): ad-free banners and interstitials, 2× XP, golden nameplate + crown. Under 13 must pass a parent math gate before the Play sheet opens.

## Project map

```
lib/
  models/        question, rank, reward, profile, nameplates
  services/      QuestionGenerator, RewardEngine, AdService, IAPService, storage
  controllers/   ProfileController, GameController
  screens/       onboarding, home, gameplay, rank, shop, pro, settings, legal
  widgets/       neo-brutalist chrome, avatars, cloud, comic popup, forge
.github/workflows/build_apk.yml
android/         AGP 9.3.3, Kotlin 2.4.20, Gradle 9.5.0
```

Local keys include the ones the product contract asked for: `userAge`, `coins`, `total_xp`, `isProUser`.

## Ads — AdMob + Meta

Development builds use Google's test units (`USE_TEST_ADS` defaults to true) and the test app id `ca-app-pub-3940256099942544~3347511713`. Do not ship those.

1. Create an AdMob app and three units: banner, interstitial, rewarded.
2. In AdMob, open Mediation and add **Meta Audience Network** as a bidding source on each format. Placement IDs live in the AdMob mediation group, not in Dart. The `gma_mediation_meta` plugin registers the adapter.
3. Build with real ids:

```bash
flutter build apk --release \
  -PADMOB_APP_ID=ca-app-pub-xxxxxxxx~yyyyyyyy \
  --dart-define=USE_TEST_ADS=false \
  --dart-define=ADMOB_BANNER_ID=ca-app-pub-xxx/banner \
  --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-xxx/interstitial \
  --dart-define=ADMOB_REWARDED_ID=ca-app-pub-xxx/rewarded
```

Age rules, applied before `MobileAds.initialize`:

| Age | Ads |
| --- | --- |
| Under 13 | SDK never starts. No banners, interstitials, rewarded, or Meta calls. |
| 13–17 | Teen treatment, non-personalized, PG/T cap. |
| 18+ | Consent form (UMP) first. Personalized only if consent is obtained or not required. |

`DELAY_APP_MEASUREMENT_INIT` is set so measurement waits for that age gate. If someone changes age from 13+ to under 13 after the SDK already started, requests stop and Settings asks for a restart.

Pro disables banner and interstitial immediately. Rewarded stays optional, because the player taps it.

## Pro plan — Play Billing

Create a **non-consumable** in Play Console with product id exactly:

```
brainspeed_iq_pro
```

The app queries that id, buys with `buyNonConsumable`, listens on `purchaseStream`, checks product id + purchased/restored, then sets `isProUser` and completes the purchase. Restore is on the Pro screen, in Settings, and once silently after launch.

A modified client can flip a local bool. Before real revenue, verify the purchase token on a server. The in-app check is the complete store flow; it is not a fraud backend.

Release signing: copy `android/key.properties.example` to `android/key.properties` (gitignored). Without it, release APKs are debug-signed so CI and `flutter run --release` still work. Do not upload a debug-signed APK to production.

Debug builds have a Settings toggle to grant/drop Pro so the gold nameplate and 2× XP can be checked without Play.

## COPPA / store listing

This is a mixed-audience app, not a Designed for Families child app. The age gate is mandatory. Do not enroll it as primarily child-directed if adults see ads. Declare ads, and declare that under-13 users are not served ads and the SDK is not initialized for them. Privacy and terms are in the app and in `PRIVACY_POLICY.md` / `TERMS.md` — replace `support@brainspeed.iq` and have counsel read them before release.

Play icon: `branding/play_store_512.png`.

## CI

`.github/workflows/build_apk.yml` runs on push, pull request, and manual dispatch. It analyzes, tests, builds a release APK, and uploads `brainspeed-iq-apk` (PRs skip the APK build).

The workflow pins its toolchain in the `env:` block — Flutter 3.47.6 (stable), Java 17, `platforms;android-36`, `build-tools;36.0.0` — and uses the Android SDK that the hosted Ubuntu runners already ship, so no second copy of the command line tools is downloaded. Bump `FLUTTER_VERSION` there when you bump `pubspec.yaml`.

The Android Gradle files match current Flutter stable templates (AGP 9.3.3, Kotlin 2.4.20, Gradle 9.5.0, Java 17). If `flutter create` on your machine prints newer versions, prefer those. Do not go back to AGP 9.3.0/9.3.1: their lint crashes on JDK 17 (`NoSuchMethodError: java.util.List.removeLast()` in the bundled `JavaDocParser`), which fails `flutter build apk --release`. The AGP 9.3 line also needs Gradle 9.5.0 or newer.

Caching, because the Gradle build is ~85% of the run: `setup-java` caches `~/.gradle/caches` (keyed on the `*.gradle.kts` files) and the wrapper distribution separately (keyed on `gradle-wrapper.properties`, so editing a build file does not force Gradle itself to be downloaded again), `flutter-action` caches the Flutter SDK and its engine artifacts, and `org.gradle.caching=true` lets a restored cache serve unchanged Kotlin, dex and resource tasks. The wrapper pulls `gradle-9.5.0-bin.zip` rather than `-all.zip` — CI never reads the bundled sources and docs. Measured on the same commit: `flutter build apk --release` drops from **383s cold to 76s warm** and the whole job from ~6.5 min to ~2.2 min, with a byte-identical APK. Everything except the Gradle build is ~50s either way.

## iOS

This repo is Android-first because the requested pipeline is an APK. To add iOS:

```bash
flutter create . --platforms=ios --project-name brain_speed_iq
```

Then set `GADApplicationIdentifier` to your AdMob app id, add Meta's SKAdNetwork IDs from Google's mediation guide, and create the same non-consumable in App Store Connect.

## Tests

```bash
flutter test
```

Covers the generator (four unique choices, kids stay on +/−), reward edges at 5.0 / 5.1 / 12.0 / 12.1 / 25.0 / 25.1, Pro XP doubling, and rank forge thresholds.
