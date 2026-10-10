import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/nameplate.dart';
import '../models/rank_tier.dart';
import '../models/reward.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._storage);

  final StorageService _storage;
  UserProfile profile = UserProfile.fresh();
  Future<void> _saveTail = Future<void>.value();

  int get userAge => profile.userAge;
  int get coins => profile.coins;
  int get totalXp => profile.totalXp;
  bool get isProUser => profile.isProUser;
  bool get onboardingComplete => profile.onboardingComplete;
  String get nickname => profile.nickname;
  bool get isChild => profile.isChild;
  bool get canEvolve => profile.canEvolve;
  RankTier get forgedTier => profile.forgedTier;

  Future<void> load() async {
    profile = _storage.read();
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String nickname,
    required int age,
  }) async {
    final clamped = age.clamp(6, 60);
    final child = isCoppaChild(clamped);
    profile = profile.copyWith(
      onboardingComplete: true,
      acceptedTerms: true,
      nickname: nickname.trim(),
      userAge: clamped,
      coins: child
          ? AppConfig.childStartingCoins
          : AppConfig.standardStartingCoins,
    );
    await _save();
  }

  Future<void> updateNickname(String nickname) async {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty || trimmed.length > 16) return;
    profile = profile.copyWith(nickname: trimmed);
    await _save();
  }

  Future<void> updateAge(int age) async {
    profile = profile.copyWith(userAge: age.clamp(6, 60));
    await _save();
  }

  Future<void> setSound(bool enabled) async {
    profile = profile.copyWith(soundOn: enabled);
    await _save();
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    profile = profile.copyWith(coins: profile.coins + amount);
    await _save();
  }

  Future<bool> trySpend(int amount) async {
    if (amount < 0 || profile.coins < amount) return false;
    profile = profile.copyWith(coins: profile.coins - amount);
    await _save();
    return true;
  }

  Future<bool> consumeHintToken() => _consumeToken(hint: true);
  Future<bool> consumeFiftyToken() => _consumeToken(fifty: true);
  Future<bool> consumeChanceToken() => _consumeToken(chance: true);

  Future<bool> _consumeToken({
    bool hint = false,
    bool fifty = false,
    bool chance = false,
  }) async {
    if (hint && profile.hintTokens <= 0) return false;
    if (fifty && profile.fiftyTokens <= 0) return false;
    if (chance && profile.chanceTokens <= 0) return false;
    profile = profile.copyWith(
      hintTokens: profile.hintTokens - (hint ? 1 : 0),
      fiftyTokens: profile.fiftyTokens - (fifty ? 1 : 0),
      chanceTokens: profile.chanceTokens - (chance ? 1 : 0),
    );
    await _save();
    return true;
  }

  Future<String?> buyHintPack() {
    return _buyPack(
      cost: AppConfig.hintPackCost,
      apply: (current) => current.copyWith(
        hintTokens: current.hintTokens + AppConfig.hintPackCount,
      ),
    );
  }

  Future<String?> buyFiftyPack() {
    return _buyPack(
      cost: AppConfig.fiftyPackCost,
      apply: (current) => current.copyWith(
        fiftyTokens: current.fiftyTokens + AppConfig.fiftyPackCount,
      ),
    );
  }

  Future<String?> buyChancePack() {
    return _buyPack(
      cost: AppConfig.chancePackCost,
      apply: (current) => current.copyWith(
        chanceTokens: current.chanceTokens + AppConfig.chancePackCount,
      ),
    );
  }

  Future<String?> _buyPack({
    required int cost,
    required UserProfile Function(UserProfile current) apply,
  }) async {
    if (profile.coins < cost) return 'Not enough coins.';
    profile = apply(profile.copyWith(coins: profile.coins - cost));
    await _save();
    return null;
  }

  Future<String?> buyOrEquipNameplate(NameplateStyle style) async {
    if (style.isProOnly) {
      return profile.isProUser
          ? null
          : 'Golden nameplate is a PRO perk.';
    }
    final owned = profile.ownedNameplates.contains(style.id);
    if (!owned) {
      if (profile.coins < style.cost) return 'Not enough coins.';
      profile = profile.copyWith(
        coins: profile.coins - style.cost,
        ownedNameplates: [...profile.ownedNameplates, style.id],
        nameplateId: style.id,
      );
    } else {
      profile = profile.copyWith(nameplateId: style.id);
    }
    await _save();
    return null;
  }

  Future<void> applyCorrect({
    required RewardResult reward,
    required int timeMs,
  }) async {
    final streak = profile.streak + 1;
    final bestTime = profile.bestTimeMs == 0 || timeMs < profile.bestTimeMs
        ? timeMs
        : profile.bestTimeMs;
    profile = profile.copyWith(
      coins: profile.coins + reward.coins,
      totalXp: profile.totalXp + reward.xp,
      levelsCompleted: profile.levelsCompleted + 1,
      questionsSettled: profile.questionsSettled + 1,
      streak: streak,
      bestStreak: streak > profile.bestStreak ? streak : profile.bestStreak,
      bestTimeMs: bestTime,
    );
    await _save();
  }

  Future<void> applyMiss() async {
    profile = profile.copyWith(
      questionsSettled: profile.questionsSettled + 1,
      streak: 0,
    );
    await _save();
  }

  Future<RankTier?> evolve() async {
    final next = profile.nextTier;
    if (next == null || profile.totalXp < next.minXp) return null;
    profile = profile.copyWith(forgedRankIndex: next.index);
    await _save();
    return next;
  }

  Future<void> unlockPro() async {
    if (profile.isProUser) return;
    profile = profile.copyWith(isProUser: true);
    await _save();
  }

  Future<void> setProForDebug(bool value) async {
    profile = profile.copyWith(isProUser: value);
    await _save();
  }

  Future<void> resetTraining() async {
    profile = profile.copyWith(
      coins: profile.startingCoins,
      totalXp: 0,
      forgedRankIndex: 0,
      levelsCompleted: 0,
      questionsSettled: 0,
      bestTimeMs: 0,
      streak: 0,
      bestStreak: 0,
      hintTokens: 0,
      fiftyTokens: 0,
      chanceTokens: 0,
      nameplateId: profile.isProUser ? profile.nameplateId : 'classic',
    );
    await _save();
  }

  Future<void> _save() {
    // Persist immutable snapshots in order so fast successive actions cannot
    // interleave SharedPreferences writes and leave a mixed profile on disk.
    final snapshot = profile;
    final write = _saveTail.then((_) => _storage.write(snapshot));
    _saveTail = write.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Profile persistence failed: $error\n$stackTrace');
      },
    );
    return write.then((_) => notifyListeners());
  }
}
