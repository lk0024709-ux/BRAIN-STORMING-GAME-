import '../config/app_config.dart';
import 'nameplate.dart';
import 'rank_tier.dart';

class UserProfile {
  const UserProfile({
    required this.onboardingComplete,
    required this.acceptedTerms,
    required this.nickname,
    required this.userAge,
    required this.coins,
    required this.totalXp,
    required this.isProUser,
    required this.forgedRankIndex,
    required this.levelsCompleted,
    required this.questionsSettled,
    required this.bestTimeMs,
    required this.streak,
    required this.bestStreak,
    required this.hintTokens,
    required this.fiftyTokens,
    required this.chanceTokens,
    required this.soundOn,
    required this.nameplateId,
    required this.ownedNameplates,
  });

  factory UserProfile.fresh() {
    return const UserProfile(
      onboardingComplete: false,
      acceptedTerms: false,
      nickname: '',
      userAge: 12,
      coins: 0,
      totalXp: 0,
      isProUser: false,
      forgedRankIndex: 0,
      levelsCompleted: 0,
      questionsSettled: 0,
      bestTimeMs: 0,
      streak: 0,
      bestStreak: 0,
      hintTokens: 0,
      fiftyTokens: 0,
      chanceTokens: 0,
      soundOn: true,
      nameplateId: 'classic',
      ownedNameplates: ['classic'],
    );
  }

  final bool onboardingComplete;
  final bool acceptedTerms;
  final String nickname;
  final int userAge;
  final int coins;
  final int totalXp;
  final bool isProUser;
  final int forgedRankIndex;
  final int levelsCompleted;
  final int questionsSettled;
  final int bestTimeMs;
  final int streak;
  final int bestStreak;
  final int hintTokens;
  final int fiftyTokens;
  final int chanceTokens;
  final bool soundOn;
  final String nameplateId;
  final List<String> ownedNameplates;

  RankTier get forgedTier => RankTier.fromIndex(forgedRankIndex);

  RankTier? get nextTier => forgedTier.next;

  bool get canEvolve =>
      nextTier != null && totalXp >= nextTier!.minXp;

  bool get isChild => isCoppaChild(userAge);

  int get startingCoins =>
      isChild ? AppConfig.childStartingCoins : AppConfig.standardStartingCoins;

  NameplateStyle get equippedNameplate {
    if (isProUser) return NameplateStyle.proGold;
    return NameplateStyle.byId(nameplateId);
  }

  double get accuracy {
    if (questionsSettled == 0) return 0;
    return levelsCompleted / questionsSettled;
  }

  UserProfile copyWith({
    bool? onboardingComplete,
    bool? acceptedTerms,
    String? nickname,
    int? userAge,
    int? coins,
    int? totalXp,
    bool? isProUser,
    int? forgedRankIndex,
    int? levelsCompleted,
    int? questionsSettled,
    int? bestTimeMs,
    int? streak,
    int? bestStreak,
    int? hintTokens,
    int? fiftyTokens,
    int? chanceTokens,
    bool? soundOn,
    String? nameplateId,
    List<String>? ownedNameplates,
  }) {
    return UserProfile(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      nickname: nickname ?? this.nickname,
      userAge: userAge ?? this.userAge,
      coins: coins ?? this.coins,
      totalXp: totalXp ?? this.totalXp,
      isProUser: isProUser ?? this.isProUser,
      forgedRankIndex: forgedRankIndex ?? this.forgedRankIndex,
      levelsCompleted: levelsCompleted ?? this.levelsCompleted,
      questionsSettled: questionsSettled ?? this.questionsSettled,
      bestTimeMs: bestTimeMs ?? this.bestTimeMs,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      hintTokens: hintTokens ?? this.hintTokens,
      fiftyTokens: fiftyTokens ?? this.fiftyTokens,
      chanceTokens: chanceTokens ?? this.chanceTokens,
      soundOn: soundOn ?? this.soundOn,
      nameplateId: nameplateId ?? this.nameplateId,
      ownedNameplates: ownedNameplates ?? this.ownedNameplates,
    );
  }
}
