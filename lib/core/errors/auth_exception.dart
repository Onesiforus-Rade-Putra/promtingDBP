enum AuthFailureType {
  unauthorized,
  validation,
  server,
  network,
  invalidResponse,
}

class AuthException implements Exception {
  final String message;
  final AuthFailureType type;
  final int? statusCode;

  const AuthException({
    required this.message,
    required this.type,
    this.statusCode,
  });

  @override
  String toString() => message;
}
