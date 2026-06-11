class ApiConfig {
  ApiConfig._();

  /// Android Emulator:
  /// Gunakan 10.0.2.2 untuk mengakses localhost komputer.
  ///
  /// Physical Device:
  /// Ganti dengan IP laptop pada jaringan yang sama,
  /// contoh: http://192.168.1.10:8000
  ///
  /// Production:
  /// Gunakan HTTPS.
  static const String baseUrl = 'https://mahasiswa-sukses-backend.vercel.app';

  static const Duration requestTimeout = Duration(seconds: 20);

  static const String loginEndpoint = '/api/v1/auth/login';
  static const String registerEndpoint = '/api/v1/auth/register';
}
