import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gma_mediation_meta/gma_mediation_meta.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

/// AdMob singleton with Meta Audience Network mediation.
///
/// The Meta adapter is pulled in by `gma_mediation_meta` and registered by
/// Flutter's plugin registrant. Placement mapping lives in the AdMob
/// mediation group, not in this class. Under-13 players never initialize
/// the SDK (COPPA: no tracking, no ads).
class AdService extends ChangeNotifier {
  static const List<Type> mediationAdapters = <Type>[GmaMediationMeta];

  int _age = 0;
  bool _isPro = false;
  bool _sdkReady = false;
  bool _consentAllowsAds = false;
  bool _nonPersonalized = true;
  bool _sdkEverStarted = false;

  bool privacyOptionsRequired = false;
  bool needsRestartForChildMode = false;
  String? lastError;

  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  Future<void>? _configureFlight;

  bool get isChild => isCoppaChild(_age);
  bool get isPro => _isPro;
  bool get sdkReady => _sdkReady;

  /// Banners and interstitials. Off for Pro, kids, and denied consent.
  bool get forcedAdsAllowed =>
      _sdkReady && _consentAllowsAds && !_isPro && !isChild;

  /// Rewarded ads stay optional for Pro. Still never requested for kids.
  bool get rewardedAllowed => _sdkReady && _consentAllowsAds && !isChild;

  bool get usingTestUnits => AppConfig.useTestAds;

  String get mediationLabel =>
      'AdMob + ${mediationAdapters.length} mediation adapter (Meta Audience Network)';

  AdRequest get request => AdRequest(nonPersonalizedAds: _nonPersonalized);

  bool get _mobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> configure({required int age, required bool isPro}) {
    final flight = _configure(age: age, isPro: isPro);
    _configureFlight = flight;
    return flight;
  }

  Future<void> _configure({required int age, required bool isPro}) async {
    _age = age.clamp(6, 60);
    _isPro = isPro;
    lastError = null;

    if (isChild) {
      _consentAllowsAds = false;
      needsRestartForChildMode = _sdkEverStarted;
      _sdkReady = false;
      await _dropFullscreenAds();
      notifyListeners();
      return;
    }

    needsRestartForChildMode = false;
    if (!_mobile) {
      _sdkReady = false;
      _consentAllowsAds = false;
      notifyListeners();
      return;
    }

    try {
      final treatment = _age < 18
          ? AgeRestrictedTreatment.teen
          : AgeRestrictedTreatment.unspecified;
      final rating = _age < 16 ? MaxAdContentRating.pg : MaxAdContentRating.t;
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          ageRestrictedTreatment: treatment,
          maxAdContentRating: rating,
        ),
      );
      await _gatherConsent();
      final canRequest = await ConsentInformation.instance.canRequestAds();
      privacyOptionsRequired = await _privacyOptionsRequired();
      if (!canRequest) {
        _consentAllowsAds = false;
        _sdkReady = false;
        notifyListeners();
        return;
      }
      _nonPersonalized = _age < 18 || await _consentRequiresNpa();
      if (!_sdkEverStarted) {
        await MobileAds.instance.initialize();
        _sdkEverStarted = true;
      }
      _sdkReady = true;
      _consentAllowsAds = true;
      notifyListeners();
      unawaited(_preloadInterstitial());
      unawaited(_preloadRewarded());
    } catch (error, stack) {
      lastError = error.toString();
      _sdkReady = false;
      _consentAllowsAds = false;
      debugPrint('AdService.configure failed: $error\n$stack');
      notifyListeners();
    }
  }

  void onProUnlocked() {
    _isPro = true;
    unawaited(_dropFullscreenAds());
    notifyListeners();
  }

  Future<void> maybeShowInterstitial(int levelsCompleted) async {
    if (_configureFlight != null) await _configureFlight;
    if (!forcedAdsAllowed) return;
    if (levelsCompleted <= 0 ||
        levelsCompleted % AppConfig.interstitialEvery != 0) {
      return;
    }
    await showInterstitial();
  }

  Future<void> showInterstitial() async {
    if (!forcedAdsAllowed) return;
    final ad = _interstitial ??
        await _loadInterstitial(timeout: const Duration(seconds: 5));
    _interstitial = null;
    if (ad == null) {
      unawaited(_preloadInterstitial());
      return;
    }
    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        shown.dispose();
        lastError = error.message;
        if (!completer.isCompleted) completer.complete();
      },
    );
    ad.show();
    await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {},
    );
    unawaited(_preloadInterstitial());
  }

  /// Returns true only when the player actually earned the reward.
  Future<bool> showRewarded() async {
    if (_configureFlight != null) await _configureFlight;
    if (!rewardedAllowed) return false;
    final ad =
        _rewarded ?? await _loadRewarded(timeout: const Duration(seconds: 8));
    _rewarded = null;
    if (ad == null) {
      unawaited(_preloadRewarded());
      return false;
    }
    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        shown.dispose();
        lastError = error.message;
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    await ad.show(
      onUserEarnedReward: (shown, reward) {
        earned = reward.amount > 0 || reward.type.isNotEmpty;
      },
    );
    final result = await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => earned,
    );
    unawaited(_preloadRewarded());
    return result;
  }

  Future<void> showPrivacyOptions() async {
    if (!_mobile) return;
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  Future<void> _gatherConsent() async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) {}).whenComplete(() {
          if (!completer.isCompleted) completer.complete();
        });
      },
      (error) {
        lastError = error.message;
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {},
    );
  }

  Future<bool> _consentRequiresNpa() async {
    final status = await ConsentInformation.instance.getConsentStatus();
    return status != ConsentStatus.obtained &&
        status != ConsentStatus.notRequired;
  }

  Future<bool> _privacyOptionsRequired() async {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  Future<void> _preloadInterstitial() async {
    if (!forcedAdsAllowed || _interstitial != null || _loadingInterstitial) {
      return;
    }
    _loadingInterstitial = true;
    await _loadInterstitial(timeout: const Duration(seconds: 12));
    _loadingInterstitial = false;
  }

  Future<InterstitialAd?> _loadInterstitial({required Duration timeout}) {
    final completer = Completer<InterstitialAd?>();
    InterstitialAd.load(
      adUnitId: AppConfig.interstitialUnitId,
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          lastError = error.message;
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    return completer.future.timeout(timeout, onTimeout: () => _interstitial);
  }

  Future<void> _preloadRewarded() async {
    if (!rewardedAllowed || _rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    await _loadRewarded(timeout: const Duration(seconds: 12));
    _loadingRewarded = false;
  }

  Future<RewardedAd?> _loadRewarded({required Duration timeout}) {
    final completer = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: AppConfig.rewardedUnitId,
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          if (!completer.isCompleted) completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          lastError = error.message;
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    return completer.future.timeout(timeout, onTimeout: () => _rewarded);
  }

  Future<void> _dropFullscreenAds() async {
    _interstitial?.dispose();
    _interstitial = null;
    _rewarded?.dispose();
    _rewarded = null;
  }

  @override
  void dispose() {
    unawaited(_dropFullscreenAds());
    super.dispose();
  }
}
