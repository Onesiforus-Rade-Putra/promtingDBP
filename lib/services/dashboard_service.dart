import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/achievement_model.dart';
import '../models/gamification_summary_model.dart';
import '../models/leaderboard_response_model.dart';
import '../models/quest_model.dart';
import '../models/task_summary_model.dart';
import '../models/user_profile_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class SessionExpiredException extends ApiException {
  SessionExpiredException()
      : super(
          'Sesi Anda telah berakhir. Silakan login kembali.',
          statusCode: 401,
        );
}

class DashboardService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  DashboardService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<UserProfileModel> getMyProfile() async {
    final json = await _get('/api/v1/user/profile');
    return UserProfileModel.fromJson(json as Map<String, dynamic>);
  }

  Future<TaskSummaryModel> getTaskSummary() async {
    final json = await _get('/api/v1/progress-tracking/summary');
    return TaskSummaryModel.fromJson(json as Map<String, dynamic>);
  }

  Future<GamificationSummaryModel> getGamificationSummary() async {
    final json = await _get('/api/v1/gamification/summary');
    return GamificationSummaryModel.fromJson(json as Map<String, dynamic>);
  }

  Future<List<AchievementModel>> getAchievements({
    String? achievementType,
  }) async {
    final query = <String, String>{};

    if (achievementType != null && achievementType.isNotEmpty) {
      query['achievement_type'] = achievementType;
    }

    final json = await _get(
      '/api/v1/gamification/achievement',
      queryParameters: query,
    );

    if (json is! List) return <AchievementModel>[];

    return json
        .whereType<Map<String, dynamic>>()
        .map(AchievementModel.fromJson)
        .toList();
  }

  Future<List<QuestModel>> getQuests({
    String? frequency,
  }) async {
    final query = <String, String>{};

    if (frequency != null && frequency.isNotEmpty) {
      query['frequency'] = frequency;
    }

    final json = await _get(
      '/api/v1/gamification/quests',
      queryParameters: query,
    );

    if (json is! List) return <QuestModel>[];

    return json
        .whereType<Map<String, dynamic>>()
        .map(QuestModel.fromJson)
        .toList();
  }

  Future<LeaderboardResponseModel> getLeaderboard() async {
    final json = await _get('/api/v1/gamification/leaderboard');
    return LeaderboardResponseModel.fromJson(json as Map<String, dynamic>);
  }

  Future<dynamic> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final headers = await _buildHeaders();

      final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
        queryParameters: queryParameters != null && queryParameters.isNotEmpty
            ? queryParameters
            : null,
      );

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 20));

      return _handleResponse(response);
    } on SessionExpiredException {
      rethrow;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw ApiException(
        'Koneksi terlalu lama. Periksa koneksi internet Anda.',
      );
    } catch (_) {
      throw ApiException('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  Future<Map<String, String>> _buildHeaders() async {
    final token = await _storage.read(key: 'access_token');

    if (token == null || token.isEmpty) {
      throw SessionExpiredException();
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode == 200) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401) {
      await _storage.delete(key: 'access_token');
      throw SessionExpiredException();
    }

    if (response.statusCode == 422) {
      throw ApiException(
        'Permintaan data tidak valid.',
        statusCode: 422,
      );
    }

    if (response.statusCode >= 500) {
      throw ApiException(
        'Server sedang bermasalah. Silakan coba lagi nanti.',
        statusCode: response.statusCode,
      );
    }

    throw ApiException(
      'Gagal memuat data dashboard.',
      statusCode: response.statusCode,
    );
  }
}
