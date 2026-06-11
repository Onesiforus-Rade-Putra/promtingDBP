class QuestModel {
  final String title;
  final String description;
  final String frequency;
  final int xpReward;
  final String difficulty;
  final int progressPercentage;
  final bool isCompleted;

  QuestModel({
    required this.title,
    required this.description,
    required this.frequency,
    required this.xpReward,
    required this.difficulty,
    required this.progressPercentage,
    required this.isCompleted,
  });

  factory QuestModel.fromJson(Map<String, dynamic> json) {
    return QuestModel(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      frequency: json['frequency']?.toString() ?? 'harian',
      xpReward: json['xp_reward'] is int ? json['xp_reward'] : 0,
      difficulty: json['difficulty']?.toString() ?? 'easy',
      progressPercentage:
          json['progress_percentage'] is int ? json['progress_percentage'] : 0,
      isCompleted: json['is_completed'] is bool ? json['is_completed'] : false,
    );
  }
}
