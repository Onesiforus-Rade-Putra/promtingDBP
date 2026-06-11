import 'package:flutter/foundation.dart';

import '../models/create_task_request_model.dart';
import '../models/task_model.dart';
import '../models/task_summary_model.dart';
import '../services/progress_tracking_exception.dart';
import '../services/progress_tracking_service.dart';

class ProgressTrackingViewModel extends ChangeNotifier {
  ProgressTrackingViewModel({required ProgressTrackingService service})
      : _service = service;

  final ProgressTrackingService _service;

  TaskSummaryModel? summary;
  List<TaskModel> tasks = <TaskModel>[];

  bool isLoadingSummary = false;
  bool isLoadingTasks = false;
  bool isCreatingTask = false;

  String? errorMessage;
  String? successMessage;
  String? selectedCategory;

  bool _sessionExpiredPending = false;
  final Set<int> _updatingTaskIds = <int>{};
  final Set<int> _deletingTaskIds = <int>{};

  bool get isUpdatingTask => _updatingTaskIds.isNotEmpty;
  bool get isDeletingTask => _deletingTaskIds.isNotEmpty;

  bool isUpdating(int taskId) => _updatingTaskIds.contains(taskId);
  bool isDeleting(int taskId) => _deletingTaskIds.contains(taskId);

  Future<void> loadSummary() async {
    isLoadingSummary = true;
    notifyListeners();
    try {
      summary = await _service.getTaskSummary();
    } on ProgressTrackingException catch (e) {
      _registerError(e);
    } finally {
      isLoadingSummary = false;
      notifyListeners();
    }
  }

  Future<void> loadTasks({String? category}) async {
    isLoadingTasks = true;
    notifyListeners();
    try {
      tasks = await _service.getTasks(category: category);
    } on ProgressTrackingException catch (e) {
      _registerError(e);
    } finally {
      isLoadingTasks = false;
      notifyListeners();
    }
  }

  Future<void> changeCategoryFilter(String? category) async {
    selectedCategory = category;
    notifyListeners();
    await loadTasks(category: selectedCategory);
  }

  Future<bool> addTask(CreateTaskRequestModel request) async {
    isCreatingTask = true;
    _clearFeedback();
    notifyListeners();
    try {
      await _service.createTask(request);
      await refreshData();
      successMessage = 'Tugas berhasil ditambahkan.';
      notifyListeners();
      return true;
    } on ProgressTrackingException catch (e) {
      _registerError(e);
      notifyListeners();
      return false;
    } finally {
      isCreatingTask = false;
      notifyListeners();
    }
  }

  Future<bool> changeTaskProgress(int taskId, String progress) async {
    if (_updatingTaskIds.contains(taskId)) return false;
    _updatingTaskIds.add(taskId);
    _clearFeedback();
    notifyListeners();
    try {
      await _service.updateTaskProgress(taskId, progress);
      await refreshData();
      successMessage = 'Progress tugas berhasil diperbarui.';
      notifyListeners();
      return true;
    } on ProgressTrackingException catch (e) {
      _registerError(e);
      notifyListeners();
      return false;
    } finally {
      _updatingTaskIds.remove(taskId);
      notifyListeners();
    }
  }

  Future<bool> removeTask(int taskId) async {
    if (_deletingTaskIds.contains(taskId)) return false;
    _deletingTaskIds.add(taskId);
    _clearFeedback();
    notifyListeners();
    try {
      await _service.deleteTask(taskId);
      await refreshData();
      successMessage = 'Tugas berhasil dihapus.';
      notifyListeners();
      return true;
    } on ProgressTrackingException catch (e) {
      _registerError(e);
      notifyListeners();
      return false;
    } finally {
      _deletingTaskIds.remove(taskId);
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    _clearFeedback();
    await Future.wait<void>(<Future<void>>[
      loadSummary(),
      loadTasks(category: selectedCategory),
    ]);
  }

  String? takeErrorMessage() {
    final value = errorMessage;
    errorMessage = null;
    return value;
  }

  String? takeSuccessMessage() {
    final value = successMessage;
    successMessage = null;
    return value;
  }

  bool takeSessionExpired() {
    final value = _sessionExpiredPending;
    _sessionExpiredPending = false;
    return value;
  }

  void _registerError(ProgressTrackingException exception) {
    errorMessage = exception.message;
    if (exception is SessionExpiredException) {
      _sessionExpiredPending = true;
    }
  }

  void _clearFeedback() {
    errorMessage = null;
    successMessage = null;
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
