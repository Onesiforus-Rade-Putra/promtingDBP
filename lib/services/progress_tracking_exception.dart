abstract class ProgressTrackingException implements Exception {
  const ProgressTrackingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SessionExpiredException extends ProgressTrackingException {
  const SessionExpiredException()
      : super('Sesi Anda telah berakhir. Silakan login kembali.');
}

class RequestValidationException extends ProgressTrackingException {
  const RequestValidationException(super.message);
}

class NetworkException extends ProgressTrackingException {
  const NetworkException()
      : super('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
}

class ServerException extends ProgressTrackingException {
  const ServerException([String? message])
      : super(message ?? 'Terjadi kesalahan. Silakan coba lagi.');
}

class ApiException extends ProgressTrackingException {
  const ApiException(super.message);
}
