import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/create_task_request_model.dart';
import '../models/task_model.dart';
import '../models/task_summary_model.dart';
import 'progress_tracking_exception.dart';

class ProgressTrackingService {
  ProgressTrackingService({
    required String baseUrl,
    http.Client? client,
    FlutterSecureStorage? secureStorage,
  })  : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'access_token';
  static const Duration _timeout = Duration(seconds: 20);

  final String _baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  Future<TaskSummaryModel> getTaskSummary() async {
    final response = await _send(
      (headers) => _client.get(
        _uri('/api/v1/progress-tracking/summary'),
        headers: headers,
      ),
    );
    _ensureSuccess(response, const <int>{200});
    return TaskSummaryModel.fromJson(_decodeMap(response.body));
  }

  Future<List<TaskModel>> getTasks({String? category}) async {
    final response = await _send(
      (headers) => _client.get(
        _uri(
          '/api/v1/progress-tracking/tasks',
          category == null ? null : <String, String>{'category': category},
        ),
        headers: headers,
      ),
    );
    _ensureSuccess(response, const <int>{200});

    final decoded = _decodeJson(response.body);
    if (decoded is! List) {
      throw const ServerException('Format daftar tugas dari server tidak valid.');
    }
    try {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TaskModel.fromJson)
          .toList();
    } on FormatException {
      throw const ServerException('Format data tugas dari server tidak valid.');
    }
  }

  Future<TaskModel> createTask(CreateTaskRequestModel request) async {
    final response = await _send(
      (headers) => _client.post(
        _uri('/api/v1/progress-tracking/tasks'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      ),
    );
    _ensureSuccess(response, const <int>{201});
    try {
      return TaskModel.fromJson(_decodeMap(response.body));
    } on FormatException {
      throw const ServerException('Format data tugas dari server tidak valid.');
    }
  }

  Future<void> updateTaskProgress(int taskId, String progress) async {
    final encodedProgress = Uri.encodeComponent(progress);
    final response = await _send(
      (headers) => _client.post(
        _uri(
          '/api/v1/progress-tracking/tasks/$taskId/update_progress/$encodedProgress',
        ),
        headers: headers,
      ),
    );
    _ensureSuccess(response, const <int>{200});
    // Response sukses dapat kosong/null sesuai dokumentasi. Tidak di-decode.
  }

  Future<void> deleteTask(int taskId) async {
    final response = await _send(
      (headers) => _client.delete(
        _uri('/api/v1/progress-tracking/tasks/$taskId'),
        headers: headers,
      ),
    );
    _ensureSuccess(response, const <int>{200});
    // Response sukses dapat kosong/null sesuai dokumentasi. Tidak di-decode.
  }

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final uri = Uri.parse('$_baseUrl$path');
    return queryParameters == null
        ? uri
        : uri.replace(queryParameters: queryParameters);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null || token.trim().isEmpty) {
      throw const SessionExpiredException();
    }
    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    try {
      final headers = await _headers();
      return await request(headers).timeout(_timeout);
    } on ProgressTrackingException {
      rethrow;
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }
  }

  void _ensureSuccess(http.Response response, Set<int> successfulCodes) {
    if (successfulCodes.contains(response.statusCode)) return;

    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }
    if (response.statusCode == 422) {
      throw RequestValidationException(
        _extractMessage(response.body, 'Data tugas tidak valid.'),
      );
    }
    if (response.statusCode >= 500) {
      throw const ServerException();
    }
    throw ApiException(
      _extractMessage(response.body, 'Permintaan tidak dapat diproses.'),
    );
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const ServerException('Format respons server tidak valid.');
    }
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = _decodeJson(body);
    if (decoded is! Map<String, dynamic>) {
      throw const ServerException('Format respons server tidak valid.');
    }
    return decoded;
  }

  String _extractMessage(String body, String fallback) {
    if (body.trim().isEmpty) return fallback;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['message'] ?? decoded['detail'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } on FormatException {
      return fallback;
    }
    return fallback;
  }

  void dispose() {
    _client.close();
  }
}
