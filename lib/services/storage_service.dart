import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

/// Local offline store. Keys `userAge`, `coins`, `total_xp`, and `isProUser`
/// match the product contract; everything else is progression metadata.
class StorageService {
  StorageService(this._prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  final SharedPreferences _prefs;

  static const keyOnboarding = 'onboarding_complete';
  static const keyTerms = 'accepted_terms';
  static const keyNickname = 'nickname';
  static const keyUserAge = 'userAge';
  static const keyCoins = 'coins';
  static const keyTotalXp = 'total_xp';
  static const keyIsPro = 'isProUser';
  static const keyForgedRank = 'forged_rank';
  static const keyLevels = 'levels_completed';
  static const keySettled = 'questions_settled';
  static const keyBestTime = 'best_time_ms';
  static const keyStreak = 'streak';
  static const keyBestStreak = 'best_streak';
  static const keyHintTokens = 'hint_tokens';
  static const keyFiftyTokens = 'fifty_tokens';
  static const keyChanceTokens = 'chance_tokens';
  static const keySound = 'sound_on';
  static const keyNameplate = 'nameplate';
  static const keyOwned = 'owned_nameplates';

  UserProfile read() {
    final owned = _prefs.getStringList(keyOwned) ?? const ['classic'];
    return UserProfile(
      onboardingComplete: _prefs.getBool(keyOnboarding) ?? false,
      acceptedTerms: _prefs.getBool(keyTerms) ?? false,
      nickname: _prefs.getString(keyNickname) ?? '',
      userAge: _prefs.getInt(keyUserAge) ?? 12,
      coins: _prefs.getInt(keyCoins) ?? 0,
      totalXp: _prefs.getInt(keyTotalXp) ?? 0,
      isProUser: _prefs.getBool(keyIsPro) ?? false,
      forgedRankIndex: _prefs.getInt(keyForgedRank) ?? 0,
      levelsCompleted: _prefs.getInt(keyLevels) ?? 0,
      questionsSettled: _prefs.getInt(keySettled) ?? 0,
      bestTimeMs: _prefs.getInt(keyBestTime) ?? 0,
      streak: _prefs.getInt(keyStreak) ?? 0,
      bestStreak: _prefs.getInt(keyBestStreak) ?? 0,
      hintTokens: _prefs.getInt(keyHintTokens) ?? 0,
      fiftyTokens: _prefs.getInt(keyFiftyTokens) ?? 0,
      chanceTokens: _prefs.getInt(keyChanceTokens) ?? 0,
      soundOn: _prefs.getBool(keySound) ?? true,
      nameplateId: _prefs.getString(keyNameplate) ?? 'classic',
      ownedNameplates: owned,
    );
  }

  Future<void> write(UserProfile profile) async {
    await _prefs.setBool(keyOnboarding, profile.onboardingComplete);
    await _prefs.setBool(keyTerms, profile.acceptedTerms);
    await _prefs.setString(keyNickname, profile.nickname);
    await _prefs.setInt(keyUserAge, profile.userAge);
    await _prefs.setInt(keyCoins, profile.coins);
    await _prefs.setInt(keyTotalXp, profile.totalXp);
    await _prefs.setBool(keyIsPro, profile.isProUser);
    await _prefs.setInt(keyForgedRank, profile.forgedRankIndex);
    await _prefs.setInt(keyLevels, profile.levelsCompleted);
    await _prefs.setInt(keySettled, profile.questionsSettled);
    await _prefs.setInt(keyBestTime, profile.bestTimeMs);
    await _prefs.setInt(keyStreak, profile.streak);
    await _prefs.setInt(keyBestStreak, profile.bestStreak);
    await _prefs.setInt(keyHintTokens, profile.hintTokens);
    await _prefs.setInt(keyFiftyTokens, profile.fiftyTokens);
    await _prefs.setInt(keyChanceTokens, profile.chanceTokens);
    await _prefs.setBool(keySound, profile.soundOn);
    await _prefs.setString(keyNameplate, profile.nameplateId);
    await _prefs.setStringList(keyOwned, profile.ownedNameplates);
  }

  Future<void> clear() => _prefs.clear();
}
