import 'quiz_question_model.dart';

class StartQuizResponseModel {
  const StartQuizResponseModel({
    required this.attemptId,
    required this.text,
    required this.totalQuestions,
    required this.endDateTime,
    required this.firstQuestion,
  });

  final int attemptId;
  final String text;
  final int totalQuestions;
  final DateTime endDateTime;
  final QuizQuestionModel firstQuestion;

  factory StartQuizResponseModel.fromJson(Map<String, dynamic> json) {
    return StartQuizResponseModel(
      attemptId: (json['attempt_id'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
      totalQuestions: (json['total_questions'] as num?)?.toInt() ?? 0,
      endDateTime: DateTime.parse(json['end_date_time'] as String),
      firstQuestion: QuizQuestionModel.fromJson(
        json['first_question'] as Map<String, dynamic>,
      ),
    );
  }
}
