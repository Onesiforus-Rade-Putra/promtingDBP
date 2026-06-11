import 'package:flutter/material.dart';

import '../models/achievement_model.dart';
import '../models/gamification_summary_model.dart';
import '../models/leaderboard_response_model.dart';
import '../models/quest_model.dart';
import '../models/task_summary_model.dart';
import '../models/user_profile_model.dart';
import '../services/dashboard_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardService _service;

  DashboardViewModel({
    DashboardService? service,
  }) : _service = service ?? DashboardService();

  UserProfileModel? profile;
  TaskSummaryModel? taskSummary;
  GamificationSummaryModel? gamificationSummary;
  List<AchievementModel> achievements = <AchievementModel>[];
  List<QuestModel> quests = <QuestModel>[];
  LeaderboardResponseModel? leaderboard;

  bool isLoading = false;
  bool isLoadingProfile = false;
  bool isLoadingTaskSummary = false;
  bool isLoadingGamification = false;
  bool isLoadingAchievements = false;
  bool isLoadingQuests = false;
  bool isLoadingLeaderboard = false;

  String? errorMessage;
  String? profileError;
  String? taskSummaryError;
  String? gamificationError;
  String? achievementsError;
  String? questsError;
  String? leaderboardError;

  bool isSessionExpired = false;

  String selectedQuestFrequency = 'harian';

  double get levelProgress {
    final summary = gamificationSummary;
    if (summary == null) return 0;

    final currentXp = summary.currentLevelXp;
    final remainingXp = summary.nextLevelRequiredXpDiff;
    final totalNeeded = currentXp + remainingXp;

    if (totalNeeded <= 0) return 0;

    return (currentXp / totalNeeded).clamp(0.0, 1.0);
  }

  bool get hasAnyData {
    return profile != null ||
        taskSummary != null ||
        gamificationSummary != null ||
        achievements.isNotEmpty ||
        quests.isNotEmpty ||
        leaderboard != null;
  }

  Future<void> loadDashboardData() async {
    isLoading = true;
    errorMessage = null;
    isSessionExpired = false;
    notifyListeners();

    await Future.wait([
      loadProfile(),
      loadTaskSummary(),
      loadGamificationSummary(),
      loadAchievements(),
      loadQuests(frequency: selectedQuestFrequency),
      loadLeaderboard(),
    ]);

    isLoading = false;

    if (!hasAnyData && errorMessage == null) {
      errorMessage = 'Gagal memuat data dashboard.';
    }

    notifyListeners();
  }

  Future<void> loadProfile() async {
    isLoadingProfile = true;
    profileError = null;
    notifyListeners();

    try {
      profile = await _service.getMyProfile();
    } catch (e) {
      _handleSectionError(e, (message) => profileError = message);
    } finally {
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> loadTaskSummary() async {
    isLoadingTaskSummary = true;
    taskSummaryError = null;
    notifyListeners();

    try {
      taskSummary = await _service.getTaskSummary();
    } catch (e) {
      _handleSectionError(e, (message) => taskSummaryError = message);
    } finally {
      isLoadingTaskSummary = false;
      notifyListeners();
    }
  }

  Future<void> loadGamificationSummary() async {
    isLoadingGamification = true;
    gamificationError = null;
    notifyListeners();

    try {
      gamificationSummary = await _service.getGamificationSummary();
    } catch (e) {
      _handleSectionError(e, (message) => gamificationError = message);
    } finally {
      isLoadingGamification = false;
      notifyListeners();
    }
  }

  Future<void> loadAchievements({
    String? achievementType,
  }) async {
    isLoadingAchievements = true;
    achievementsError = null;
    notifyListeners();

    try {
      achievements = await _service.getAchievements(
        achievementType: achievementType,
      );
    } catch (e) {
      _handleSectionError(e, (message) => achievementsError = message);
    } finally {
      isLoadingAchievements = false;
      notifyListeners();
    }
  }

  Future<void> loadQuests({
    String frequency = 'harian',
  }) async {
    isLoadingQuests = true;
    questsError = null;
    selectedQuestFrequency = frequency;
    notifyListeners();

    try {
      quests = await _service.getQuests(frequency: frequency);
    } catch (e) {
      _handleSectionError(e, (message) => questsError = message);
    } finally {
      isLoadingQuests = false;
      notifyListeners();
    }
  }

  Future<void> changeQuestFrequency(String frequency) async {
    if (frequency != 'harian' && frequency != 'mingguan') return;
    await loadQuests(frequency: frequency);
  }

  Future<void> loadLeaderboard() async {
    isLoadingLeaderboard = true;
    leaderboardError = null;
    notifyListeners();

    try {
      leaderboard = await _service.getLeaderboard();
    } catch (e) {
      _handleSectionError(e, (message) => leaderboardError = message);
    } finally {
      isLoadingLeaderboard = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  void _handleSectionError(
    Object error,
    void Function(String message) setSectionError,
  ) {
    String message = 'Terjadi kesalahan. Silakan coba lagi.';

    if (error is SessionExpiredException) {
      message = error.message;
      isSessionExpired = true;
      errorMessage = error.message;
    } else if (error is ApiException) {
      message = error.message;
    }

    setSectionError(message);
  }
}
