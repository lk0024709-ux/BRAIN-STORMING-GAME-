# BrainSpeed IQ

An ad-free neo-brutalist manga brain-training game. It generates age-adaptive questions, tracks solve times, awards XP ranks, and offers an optional lifetime Pro upgrade.

## Jaldi shuru kaise karein

Flutter **3.38.1+** chahiye (stable channel — CI `3.47.6` pin karta hai, aur har push pe analyze + test + release APK chalata hai). Machine pe ye steps kaafi hain:

```bash
flutter pub get
flutter test
flutter run
```

Pehli screen age slider (6–60+) aur Terms + Privacy checkbox maangti hai. The app renders its startup screen before loading the local profile. There are no ads or advertising SDKs. Google Play Billing starts only from the Pro screen or an explicit restore action.

## What you get

- **Onboarding** saves age, terms acceptance, nickname, and a starting coin purse (80 under 13, 40 otherwise).
- **Math Quest** is a visible, age-based campaign with **120 numbered levels** (four 30-level chapters). Each correct answer unlocks the next level; a miss leaves the current level open to retry. Completing level 120 unlocks an increasingly difficult Master Mode.
- **QuestionGenerator** procedurally builds every question and scales the numbers with the level—nothing is a hardcoded quiz bank.
  - Under 10: addition, subtraction, then mixed arithmetic.
  - 10–16: multiplication, BODMAS, number patterns, then mixed math.
  - 17+: advanced BODMAS, sequences, decimals, then mixed math.
- **Level Map** shows all 120 stages as complete, current, or locked, with the player's age-specific chapters and progress.
- **Gameplay** is a comic page with generated hero and rival portraits, a thought cloud, and 2×2 answer panels.
  - Hint costs 10 coins and drops a yellow banner inside the cloud.
  - 50/50 costs 25 coins and removes two wrong panels.
  - An affordable first miss offers one Second Chance for 40 coins or a stored chance token. The same stopwatch keeps running; the miss is only recorded if the player moves on or misses again.
- **Stopwatch rewards**
  - ≤ 5.0s Lightning Fast — +20 coins, +40 XP
  - 5.1–12.0s Sharp Brain — +10 coins, +20 XP
  - 12.1–25.0s Good Work — +5 coins, +10 XP
  - slower Solved — +0 coins, +5 XP
  - Pro doubles XP only.
- **Ranks** are forged, not automatic. Bronze 0–1k, Silver 1k–5k, Gold 5k–20k, Diamond 20k+. Cross a threshold and **Evolve Rank** plays the medal-forging celebration.
- **Shop** lets players spend earned coins on booster tokens and nameplates.
- **Pro** (`brainspeed_iq_pro`, non-consumable): 2× XP, golden nameplate, and crown badge. Under 13 must pass a parent math check before the Play purchase sheet opens.

## Project map

```
lib/
  models/        question, age-based math levels, rank, reward, profile, nameplates
  services/      QuestionGenerator, RewardEngine, IAPService, storage
  controllers/   ProfileController, GameController
  screens/       onboarding, home, 120-level map, gameplay, rank, shop, pro, settings, legal
  widgets/       neo-brutalist chrome, generated avatars, cloud, comic popup, forge
assets/images/   generated hero and rival portraits
.github/workflows/build_apk.yml
android/         AGP 9.3.3, Kotlin 2.4.20, Gradle 9.5.0
```

Local keys include the ones the product contract asked for: `userAge`, `coins`, `total_xp`, `isProUser`.

## Privacy and purchases

Training progress and profile data are stored locally with SharedPreferences. The app includes no advertising, ad mediation, advertising identifier, or analytics integration. It does not run a user-data server. If a player chooses to purchase or restore Pro, the app uses Google Play Billing; Google Play handles payment and store-account details. Under-13 purchases require the in-app parent check.

The in-app Privacy Policy and Terms are also in `PRIVACY_POLICY.md` and `TERMS.md`. Replace `support@brainspeed.iq` and have counsel review them before release.

## Pro plan — Play Billing

Create a **non-consumable** in Play Console with product id exactly:

```
brainspeed_iq_pro
```

The app starts the purchase-update listener only when the Pro screen is opened or the player explicitly chooses Restore, then queries the product only on the Pro screen. It buys with `buyNonConsumable`, checks product id + purchased/restored, then sets `isProUser` and completes the purchase. Restore is available on the Pro screen and in Settings; the player can retry it if Play Billing was initially unavailable.

A modified client can flip a local bool. Before real revenue, verify the purchase token on a server. The in-app check is the complete store flow; it is not a fraud backend.

Release signing: copy `android/key.properties.example` to `android/key.properties` (gitignored). Without it, release APKs are debug-signed so CI and `flutter run --release` still work. Do not upload a debug-signed APK to production.

Debug builds have a Settings toggle to grant/drop Pro so the gold nameplate and 2× XP can be checked without Play.

## Android build and CI

Play icon: `branding/play_store_512.png`.

`.github/workflows/build_apk.yml` runs on push, pull request, and manual dispatch. It analyzes, tests, builds a release APK, and uploads `brainspeed-iq-apk` (PRs skip the APK build).

The workflow pins its toolchain in the `env:` block — Flutter 3.47.6 (stable), Java 17, `platforms;android-36`, `build-tools;36.0.0` — and uses the Android SDK that the hosted Ubuntu runners already ship, so no second copy of the command line tools is downloaded. Bump `FLUTTER_VERSION` there when you bump `pubspec.yaml`.

The Android Gradle files match current Flutter stable templates (AGP 9.3.3, Kotlin 2.4.20, Gradle 9.5.0, Java 17). If `flutter create` on your machine prints newer versions, prefer those. Do not go back to AGP 9.3.0/9.3.1: their lint crashes on JDK 17 (`NoSuchMethodError: java.util.List.removeLast()` in the bundled `JavaDocParser`), which fails `flutter build apk --release`. The AGP 9.3 line also needs Gradle 9.5.0 or newer.

Caching, because the Gradle build is ~85% of the run: `setup-java` caches `~/.gradle/caches` (keyed on the `*.gradle.kts` files) and the wrapper distribution separately (keyed on `gradle-wrapper.properties`, so editing a build file does not force Gradle itself to be downloaded again), `flutter-action` caches the Flutter SDK and its engine artifacts, and `org.gradle.caching=true` lets a restored cache serve unchanged Kotlin, dex and resource tasks. The wrapper pulls `gradle-9.5.0-bin.zip` rather than `-all.zip` — CI never reads the bundled sources and docs. Measured on the same commit: `flutter build apk --release` drops from **383s cold to 76s warm** and the whole job from ~6.5 min to ~2.2 min. Everything except the Gradle build is ~50s either way.

This repo is Android-first because the requested pipeline is an APK. To add iOS, create the platform files and configure the same non-consumable product in App Store Connect.

## Tests

```bash
flutter test
```

Covers the age-gated startup, generated character assets, all 120 age-appropriate level generators, chapter mapping, unlock/retry progression, question choices (kids stay on +/−), reward edges at 5.0 / 5.1 / 12.0 / 12.1 / 25.0 / 25.1, Pro XP doubling, rank forge thresholds, paid second-chance timing/settlement, and protection against double-spending a booster on rapid taps.
