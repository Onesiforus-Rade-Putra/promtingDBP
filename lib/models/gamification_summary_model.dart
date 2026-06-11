class GamificationSummaryModel {
  const GamificationSummaryModel({
    required this.currentLevel,
    required this.currentRanking,
    required this.totalXpEarned,
    required this.currentStreak,
    required this.currentLevelXp,
    required this.nextLevelRequiredXpDiff,
    required this.totalQuest,
    required this.totalQuestCompleted,
  });

  final int currentLevel;
  final int currentRanking;
  final int totalXpEarned;
  final int currentStreak;
  final int currentLevelXp;
  final int nextLevelRequiredXpDiff;
  final int totalQuest;
  final int totalQuestCompleted;

  factory GamificationSummaryModel.fromJson(Map<String, dynamic> json) {
    return GamificationSummaryModel(
      currentLevel: (json['current_level'] as num?)?.toInt() ?? 0,
      currentRanking: (json['current_ranking'] as num?)?.toInt() ?? 0,
      totalXpEarned: (json['total_xp_earned'] as num?)?.toInt() ??
          (json['total_xp'] as num?)?.toInt() ??
          0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      currentLevelXp: (json['current_level_xp'] as num?)?.toInt() ?? 0,
      nextLevelRequiredXpDiff:
          (json['next_level_required_xp_diff'] as num?)?.toInt() ?? 0,
      totalQuest: (json['total_quest'] as num?)?.toInt() ?? 0,
      totalQuestCompleted:
          (json['total_quest_completed'] as num?)?.toInt() ?? 0,
    );
  }
}
