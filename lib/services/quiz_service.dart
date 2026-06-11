import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../core/exceptions/api_exception.dart';
import '../models/generate_certificate_response_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';
import '../models/quiz_result_model.dart';
import '../models/start_quiz_response_model.dart';
import '../models/submit_quiz_request_model.dart';

class QuizService {
  QuizService({
    required http.Client client,
    required FlutterSecureStorage storage,
  })  : _client = client,
        _storage = storage;

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.trim().isEmpty) {
      throw const SessionExpiredException();
    }

    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<QuizModel>> getAllQuizzes() async {
    return _execute<List<QuizModel>>(
      () async => _client.get(
        _uri('/api/v1/quiz/'),
        headers: await _authorizedHeaders(),
      ),
      (response) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((item) => QuizModel.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<StartQuizResponseModel> startQuiz(int quizId) async {
    return _execute<StartQuizResponseModel>(
      () async => _client.post(
        _uri('/api/v1/quiz/$quizId/start'),
        headers: await _authorizedHeaders(),
      ),
      (response) => StartQuizResponseModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      ),
    );
  }

  Future<QuizQuestionModel> getQuizQuestion(int quizId, int questionNum) async {
    return _execute<QuizQuestionModel>(
      () async => _client.get(
        _uri('/api/v1/quiz/$quizId/questions/$questionNum'),
        headers: await _authorizedHeaders(),
      ),
      (response) => QuizQuestionModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      ),
    );
  }

  Future<QuizResultModel> submitQuiz(
    int quizId,
    Map<int, String> selectedAnswers,
  ) async {
    final request = SubmitQuizRequestModel.fromSelectedAnswers(selectedAnswers);
    return _execute<QuizResultModel>(
      () async => _client.post(
        _uri('/api/v1/quiz/$quizId/submit'),
        headers: await _authorizedHeaders(),
        body: jsonEncode(request.toJson()),
      ),
      (response) => QuizResultModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      ),
    );
  }

  Future<void> exitQuizEarly(int quizId) async {
    await _execute<void>(
      () async => _client.post(
        _uri('/api/v1/quiz/$quizId/exit'),
        headers: await _authorizedHeaders(),
      ),
      (_) {
        // Response sukses endpoint exit dapat bernilai null/kosong.
        // Tidak ada JSON object yang perlu di-decode.
      },
    );
  }

  Future<GenerateCertificateResponseModel> generateCertificate(int quizId) async {
    return _execute<GenerateCertificateResponseModel>(
      () async => _client.post(
        _uri('/api/v1/quiz/$quizId/certificate'),
        headers: await _authorizedHeaders(),
      ),
      (response) => GenerateCertificateResponseModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      ),
    );
  }

  Future<T> _execute<T>(
    Future<http.Response> Function() request,
    T Function(http.Response response) parser,
  ) async {
    try {
      final response = await request().timeout(ApiConfig.requestTimeout);
      _validateResponse(response);
      return parser(response);
    } on SessionExpiredException {
      rethrow;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on FormatException {
      throw const ApiException('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }
    if (response.statusCode == 422) {
      throw ApiException(
        _extractMessage(response.body) ??
            'Permintaan tidak valid. Silakan coba kembali.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 500) {
      throw ApiException(
        'Terjadi kesalahan. Silakan coba lagi.',
        statusCode: response.statusCode,
      );
    }
    throw ApiException(
      _extractMessage(response.body) ?? 'Terjadi kesalahan. Silakan coba lagi.',
      statusCode: response.statusCode,
    );
  }

  String? _extractMessage(String responseBody) {
    if (responseBody.trim().isEmpty || responseBody.trim() == 'null') {
      return null;
    }
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['message'] ?? decoded['detail'] ?? decoded['error'];
        return value is String && value.trim().isNotEmpty ? value : null;
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}
