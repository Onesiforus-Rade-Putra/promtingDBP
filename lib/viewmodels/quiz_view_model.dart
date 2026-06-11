import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/exceptions/api_exception.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';
import '../models/quiz_result_model.dart';
import '../models/start_quiz_response_model.dart';
import '../services/quiz_service.dart';

class QuizViewModel extends ChangeNotifier {
  QuizViewModel({required QuizService quizService}) : _quizService = quizService;

  final QuizService _quizService;
  Timer? _countdownTimer;
  final Map<int, QuizQuestionModel> _questionCache = <int, QuizQuestionModel>{};
  int? _activeQuizId;

  List<QuizModel> quizzes = <QuizModel>[];
  bool isLoadingQuizList = false;
  bool isStartingQuiz = false;
  bool isLoadingQuestion = false;
  bool isSubmittingQuiz = false;
  bool isExitingQuiz = false;
  bool isGeneratingCertificate = false;
  bool isTimeExpired = false;
  bool shouldRedirectToLogin = false;
  String? errorMessage;
  StartQuizResponseModel? activeAttempt;
  QuizQuestionModel? currentQuestion;
  QuizResultModel? quizResult;
  Map<int, String> selectedAnswers = <int, String>{};
  int currentQuestionNumber = 1;
  DateTime? endDateTime;
  Duration remainingTime = Duration.zero;

  int? get activeQuizId => _activeQuizId;
  int get totalQuestions => activeAttempt?.totalQuestions ?? 0;
  bool get isLastQuestion => totalQuestions > 0 && currentQuestionNumber >= totalQuestions;
  int get unansweredCount => totalQuestions - selectedAnswers.length;
  double get questionProgress => totalQuestions == 0 ? 0 : currentQuestionNumber / totalQuestions;
  bool get hasActiveAttempt => activeAttempt != null && _activeQuizId != null;

  Future<void> loadQuizzes() async {
    isLoadingQuizList = true;
    errorMessage = null;
    notifyListeners();
    try {
      quizzes = await _quizService.getAllQuizzes();
    } catch (error) {
      _registerError(error);
    } finally {
      isLoadingQuizList = false;
      notifyListeners();
    }
  }

  Future<bool> startQuiz(int quizId) async {
    isStartingQuiz = true;
    errorMessage = null;
    notifyListeners();
    try {
      final attempt = await _quizService.startQuiz(quizId);
      _countdownTimer?.cancel();
      _activeQuizId = quizId;
      activeAttempt = attempt;
      endDateTime = attempt.endDateTime;
      currentQuestion = attempt.firstQuestion;
      currentQuestionNumber = attempt.firstQuestion.currentNumber <= 0
          ? 1
          : attempt.firstQuestion.currentNumber;
      selectedAnswers = <int, String>{};
      _questionCache
        ..clear()
        ..[currentQuestionNumber] = attempt.firstQuestion;
      quizResult = null;
      isTimeExpired = false;
      remainingTime = _durationUntilEnd();
      return true;
    } catch (error) {
      _registerError(error);
      return false;
    } finally {
      isStartingQuiz = false;
      notifyListeners();
    }
  }

  Future<void> loadQuestion(int quizId, int questionNumber) async {
    if (questionNumber < 1 || questionNumber > totalQuestions) return;
    errorMessage = null;
    final cachedQuestion = _questionCache[questionNumber];
    if (cachedQuestion != null) {
      currentQuestion = cachedQuestion;
      currentQuestionNumber = questionNumber;
      notifyListeners();
      return;
    }

    isLoadingQuestion = true;
    notifyListeners();
    try {
      final question = await _quizService.getQuizQuestion(quizId, questionNumber);
      _questionCache[questionNumber] = question;
      currentQuestion = question;
      currentQuestionNumber = questionNumber;
    } catch (error) {
      // selectedAnswers tidak dibersihkan jika request soal gagal.
      _registerError(error);
    } finally {
      isLoadingQuestion = false;
      notifyListeners();
    }
  }

  void selectAnswer(int questionId, String answer) {
    if (isTimeExpired || isSubmittingQuiz) return;
    if (!const <String>{'a', 'b', 'c', 'd'}.contains(answer)) return;
    selectedAnswers[questionId] = answer;
    notifyListeners();
  }

  String? getSelectedAnswer(int questionId) => selectedAnswers[questionId];

  Future<bool> submitQuiz(int quizId) async {
    if (isSubmittingQuiz) return false;
    isSubmittingQuiz = true;
    errorMessage = null;
    notifyListeners();
    try {
      quizResult = await _quizService.submitQuiz(quizId, selectedAnswers);
      _countdownTimer?.cancel();
      await loadQuizzes();
      return true;
    } catch (error) {
      _registerError(error);
      return false;
    } finally {
      isSubmittingQuiz = false;
      notifyListeners();
    }
  }

  Future<bool> exitQuiz(int quizId) async {
    isExitingQuiz = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _quizService.exitQuizEarly(quizId);
      clearActiveQuiz();
      await loadQuizzes();
      return true;
    } catch (error) {
      _registerError(error);
      return false;
    } finally {
      isExitingQuiz = false;
      notifyListeners();
    }
  }

  Future<String?> generateCertificate(int quizId) async {
    if (quizResult?.passed != true) return null;
    final existingId = quizResult?.certificateId;
    if (existingId != null && existingId.isNotEmpty) return existingId;

    isGeneratingCertificate = true;
    errorMessage = null;
    notifyListeners();
    try {
      final certificate = await _quizService.generateCertificate(quizId);
      quizResult = quizResult?.copyWith(certificateId: certificate.certificateId);
      await loadQuizzes();
      return certificate.certificateId;
    } catch (error) {
      _registerError(error);
      return null;
    } finally {
      isGeneratingCertificate = false;
      notifyListeners();
    }
  }

  void startServerTimer() {
    _countdownTimer?.cancel();
    remainingTime = _durationUntilEnd();
    notifyListeners();
    if (remainingTime == Duration.zero) {
      _handleTimeExpired();
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      remainingTime = _durationUntilEnd();
      notifyListeners();
      if (remainingTime == Duration.zero) {
        _handleTimeExpired();
      }
    });
  }

  Future<void> _handleTimeExpired() async {
    if (isTimeExpired || isSubmittingQuiz || _activeQuizId == null) return;
    isTimeExpired = true;
    _countdownTimer?.cancel();
    notifyListeners();
    await submitQuiz(_activeQuizId!);
  }

  QuizResultModel? consumeResultForNavigation() {
    final result = quizResult;
    if (result == null) return null;
    _clearAttemptState(keepResult: true);
    return result;
  }

  void clearActiveQuiz() {
    _clearAttemptState(keepResult: false);
    notifyListeners();
  }

  void consumeLoginRedirect() {
    shouldRedirectToLogin = false;
  }

  Duration _durationUntilEnd() {
    if (endDateTime == null) return Duration.zero;
    final difference = endDateTime!.toUtc().difference(DateTime.now().toUtc());
    return difference.isNegative ? Duration.zero : difference;
  }

  void _clearAttemptState({required bool keepResult}) {
    _countdownTimer?.cancel();
    _activeQuizId = null;
    activeAttempt = null;
    currentQuestion = null;
    selectedAnswers = <int, String>{};
    currentQuestionNumber = 1;
    endDateTime = null;
    remainingTime = Duration.zero;
    isTimeExpired = false;
    _questionCache.clear();
    if (!keepResult) quizResult = null;
  }

  void _registerError(Object error) {
    if (error is SessionExpiredException) {
      shouldRedirectToLogin = true;
      errorMessage = error.message;
    } else if (error is ApiException) {
      errorMessage = error.message;
    } else {
      errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
