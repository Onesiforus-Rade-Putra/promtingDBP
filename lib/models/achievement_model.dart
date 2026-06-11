class AchievementModel {
  const AchievementModel({
    required this.title,
    required this.xpReward,
    required this.difficulty,
    required this.progressPercentage,
    required this.isCompleted,
    this.description = '',
    this.achievementType = '',
  });

  final String title;
  final String description;
  final String achievementType;
  final int xpReward;
  final String difficulty;
  final int progressPercentage;
  final bool isCompleted;

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      achievementType: json['achievement_type']?.toString() ?? '',
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 0,
      difficulty: json['difficulty']?.toString() ?? 'easy',
      progressPercentage: (json['progress_percentage'] as num?)?.toInt() ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }
}
