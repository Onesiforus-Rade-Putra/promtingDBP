class AnswerOption {
  const AnswerOption({required this.value, required this.label, required this.text});

  /// Value yang dikirim ke API: a, b, c, atau d.
  final String value;
  final String label;
  final String text;
}
