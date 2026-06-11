import 'answer_option.dart';

class QuizQuestionModel {
  const QuizQuestionModel({
    required this.id,
    required this.currentNumber,
    required this.text,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
  });

  final int id;
  final int currentNumber;
  final String text;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      currentNumber: (json['current_number'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
      optionA: json['option_a'] as String? ?? '',
      optionB: json['option_b'] as String? ?? '',
      optionC: json['option_c'] as String? ?? '',
      optionD: json['option_d'] as String? ?? '',
    );
  }

  List<AnswerOption> get options => <AnswerOption>[
        AnswerOption(value: 'a', label: 'A', text: optionA),
        AnswerOption(value: 'b', label: 'B', text: optionB),
        AnswerOption(value: 'c', label: 'C', text: optionC),
        AnswerOption(value: 'd', label: 'D', text: optionD),
      ];
}
