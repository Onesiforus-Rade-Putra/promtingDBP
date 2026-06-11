class RegisterRequestModel {
  const RegisterRequestModel({
    required this.email,
    required this.username,
    required this.password,
    required this.phoneNumber,
    required this.fullName,
    this.nim,
    this.birthDate,
  });

  final String email;
  final String username;
  final String password;
  final String phoneNumber;
  final String fullName;
  final String? nim;
  final DateTime? birthDate;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'email': email.trim(),
      'username': username.trim(),
      'password': password,
      'phone_number': phoneNumber.trim(),
      'full_name': fullName.trim(),
    };

    final String? cleanedNim = nim?.trim();

    if (cleanedNim != null && cleanedNim.isNotEmpty) {
      json['nim'] = cleanedNim;
    }

    if (birthDate != null) {
      json['birth_date'] = _formatApiDate(birthDate!);
    }

    return json;
  }

  static String _formatApiDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
