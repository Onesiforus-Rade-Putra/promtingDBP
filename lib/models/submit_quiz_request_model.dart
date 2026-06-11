class SubmitQuizRequestModel {
  const SubmitQuizRequestModel({required this.answers});

  final Map<String, String> answers;

  factory SubmitQuizRequestModel.fromSelectedAnswers(Map<int, String> selectedAnswers) {
    final answers = <String, String>{};
    for (final entry in selectedAnswers.entries) {
      if (!const <String>{'a', 'b', 'c', 'd'}.contains(entry.value)) {
        throw ArgumentError('Pilihan jawaban harus berupa a, b, c, atau d.');
      }
      answers[entry.key.toString()] = entry.value;
    }
    return SubmitQuizRequestModel(answers: answers);
  }

  factory SubmitQuizRequestModel.fromJson(Map<String, dynamic> json) {
    final raw = json['answers'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return SubmitQuizRequestModel(
      answers: raw.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{'answers': answers};
}
