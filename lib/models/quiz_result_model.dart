class QuizResultModel {
  const QuizResultModel({
    required this.correctAnswers,
    required this.totalQuestions,
    required this.minimumScore,
    required this.passed,
    required this.pointsGained,
    required this.streakCount,
    required this.streakBonus,
    required this.certificateId,
  });

  final int correctAnswers;
  final int totalQuestions;
  final int minimumScore;
  final bool passed;
  final int pointsGained;
  final int streakCount;
  final int streakBonus;
  final String? certificateId;

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      correctAnswers: (json['correct_answers'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      minimumScore: (json['minimum_score'] as num?)?.toInt() ?? 0,
      passed: json['passed'] as bool? ?? false,
      pointsGained: (json['points_gained'] as num?)?.toInt() ?? 0,
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
      streakBonus: (json['streak_bonus'] as num?)?.toInt() ?? 0,
      certificateId: json['certificate_id'] as String?,
    );
  }

  QuizResultModel copyWith({String? certificateId}) {
    return QuizResultModel(
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      minimumScore: minimumScore,
      passed: passed,
      pointsGained: pointsGained,
      streakCount: streakCount,
      streakBonus: streakBonus,
      certificateId: certificateId ?? this.certificateId,
    );
  }
}
