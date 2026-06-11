import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../core/errors/auth_exception.dart';
import '../models/login_response_model.dart';
import '../models/register_request_model.dart';

class AuthService {
  AuthService({
    required http.Client client,
    required this.baseUrl,
  }) : _client = client;

  final http.Client _client;
  final String baseUrl;

  static const String _invalidDataMessage =
      'Data registrasi tidak valid. Silakan periksa kembali.';

  static const String _generalErrorMessage =
      'Terjadi kesalahan. Silakan coba lagi.';

  Future<LoginResponseModel> login(
    String emailOrUsername,
    String password,
  ) async {
    final uri = Uri.parse('$baseUrl${ApiConfig.loginEndpoint}');

    try {
      final response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email_or_username': emailOrUsername.trim(),
              'password': password,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      switch (response.statusCode) {
        case 200:
          return _handleSuccessResponse(response);

        case 401:
          throw const AuthException(
            message: 'Email/username atau password salah.',
            type: AuthFailureType.unauthorized,
            statusCode: 401,
          );

        case 422:
          throw AuthException(
            message: _extractValidationMessage(response),
            type: AuthFailureType.validation,
            statusCode: 422,
          );

        default:
          throw AuthException(
            message: _generalErrorMessage,
            type: AuthFailureType.server,
            statusCode: response.statusCode,
          );
      }
    } on AuthException {
      rethrow;
    } on SocketException {
      throw const AuthException(
        message: _generalErrorMessage,
        type: AuthFailureType.network,
      );
    } on TimeoutException {
      throw const AuthException(
        message: _generalErrorMessage,
        type: AuthFailureType.network,
      );
    } on http.ClientException {
      throw const AuthException(
        message: _generalErrorMessage,
        type: AuthFailureType.network,
      );
    } on FormatException {
      throw const AuthException(
        message: _generalErrorMessage,
        type: AuthFailureType.invalidResponse,
      );
    } catch (_) {
      throw const AuthException(
        message: _generalErrorMessage,
        type: AuthFailureType.server,
      );
    }
  }

  Future<void> register(RegisterRequestModel request) async {
    final uri = Uri.parse('$baseUrl${ApiConfig.registerEndpoint}');

    try {
      final response = await _client
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      if (response.statusCode == 400 ||
          response.statusCode == 409 ||
          response.statusCode == 422) {
        throw AuthException(
          message: _extractBackendErrorMessage(response.body),
          type: AuthFailureType.validation,
          statusCode: response.statusCode,
        );
      }

      throw AuthException(
        message: _generalErrorMessage,
        type: AuthFailureType.server,
        statusCode: response.statusCode,
      );
    } on AuthException {
      rethrow;
    } on SocketException {
      throw const AuthException(
        message: _generalErrorMessage,
        type: AuthFailureType.network,
      );
    } on TimeoutException {
      throw const AuthException(
        message: _generalErrorMessage,
        type: AuthFailureType.network,
      );
    } on http.ClientException {
      throw const AuthException(
        message: _generalErrorMessage,
        type: AuthFailureType.network,
      );
    } catch (_) {
      throw const AuthException(
        message: _generalErrorMessage,
        type: AuthFailureType.server,
      );
    }
  }

  LoginResponseModel _handleSuccessResponse(http.Response response) {
    final decoded = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Response login tidak valid.');
    }

    final result = LoginResponseModel.fromJson(decoded);

    if (result.accessToken.isEmpty || result.refreshToken.isEmpty) {
      throw const FormatException('Token autentikasi tidak tersedia.');
    }

    return result;
  }

  String _extractValidationMessage(http.Response response) {
    try {
      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'] ?? decoded['message'];

        if (detail is String && detail.trim().isNotEmpty) {
          return detail;
        }

        if (detail is List && detail.isNotEmpty) {
          return 'Email/username dan password wajib diisi atau data tidak valid.';
        }
      }
    } catch (_) {
      // Gunakan pesan default jika format response berbeda.
    }

    return 'Email/username dan password wajib diisi atau data tidak valid.';
  }

  String _extractBackendErrorMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return _invalidDataMessage;
    }

    try {
      final dynamic decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic>) {
        final message = _findMessage(decoded);

        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      return _invalidDataMessage;
    }

    return _invalidDataMessage;
  }

  String? _findMessage(Map<String, dynamic> data) {
    for (final key in <String>['message', 'detail', 'error', 'errors']) {
      final extracted = _extractValue(data[key]);

      if (extracted != null && extracted.trim().isNotEmpty) {
        return extracted.trim();
      }
    }

    return null;
  }

  String? _extractValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }

    if (value is List) {
      final messages = value
          .map(_extractValue)
          .whereType<String>()
          .where((message) => message.trim().isNotEmpty)
          .toList();

      return messages.isEmpty ? null : messages.join(' ');
    }

    if (value is Map) {
      final messages = <String>[];

      for (final entry in value.entries) {
        final extracted = _extractValue(entry.value);

        if (extracted != null && extracted.trim().isNotEmpty) {
          messages.add('${entry.key}: $extracted');
        }
      }

      return messages.isEmpty ? null : messages.join(' ');
    }

    return null;
  }

  void dispose() {
    _client.close();
  }
}
