class QuizModel {
  const QuizModel({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.minimumScore,
    required this.xpReward,
    required this.difficulty,
    required this.lastAttemptSuccessfull,
    required this.certificateId,
    required this.completionCount,
  });

  final int id;
  final String title;
  final String category;
  final int durationMinutes;
  final int minimumScore;
  final int xpReward;
  final String difficulty;
  final bool lastAttemptSuccessfull;
  final String? certificateId;
  final int completionCount;

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      minimumScore: (json['minimum_score'] as num?)?.toInt() ?? 0,
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 0,
      difficulty: json['difficulty'] as String? ?? 'easy',
      // Nama field mengikuti dokumentasi API secara persis.
      lastAttemptSuccessfull: json['last_attempt_successfull'] as bool? ?? false,
      certificateId: json['certificate_id'] as String?,
      completionCount: (json['completion_count'] as num?)?.toInt() ?? 0,
    );
  }
}
