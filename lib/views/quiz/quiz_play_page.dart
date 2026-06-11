import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/answer_option.dart';
import '../../models/quiz_question_model.dart';
import '../../models/quiz_result_model.dart';
import '../../viewmodels/quiz_view_model.dart';
import '../widgets/quiz_palette.dart';
import 'quiz_result_page.dart';

class QuizPlayPage extends StatefulWidget {
  const QuizPlayPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  final int quizId;
  final String quizTitle;

  @override
  State<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends State<QuizPlayPage> {
  QuizViewModel? _viewModel;
  bool _navigatingToResult = false;
  bool _timeExpiredMessageShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.read<QuizViewModel>();
    if (_viewModel == viewModel) return;
    _viewModel?.removeListener(_handleViewModelEvent);
    _viewModel = viewModel..addListener(_handleViewModelEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) viewModel.startServerTimer();
    });
  }

  void _handleViewModelEvent() {
    final viewModel = _viewModel;
    if (!mounted || viewModel == null) return;

    if (viewModel.shouldRedirectToLogin) {
      viewModel.consumeLoginRedirect();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi Anda telah berakhir. Silakan login kembali.')),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      });
      return;
    }

    if (viewModel.isTimeExpired && !_timeExpiredMessageShown) {
      _timeExpiredMessageShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Waktu pengerjaan telah habis. Jawaban dikirim otomatis.')),
          );
        }
      });
    }

    if (viewModel.quizResult != null && !_navigatingToResult) {
      _navigatingToResult = true;
      final result = viewModel.consumeResultForNavigation();
      if (result == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => QuizResultPage(
              quizId: widget.quizId,
              quizTitle: widget.quizTitle,
              initialResult: result,
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_handleViewModelEvent);
    super.dispose();
  }

  Future<void> _loadQuestion(int number) async {
    await context.read<QuizViewModel>().loadQuestion(widget.quizId, number);
  }

  Future<void> _submitQuiz() async {
    final viewModel = context.read<QuizViewModel>();
    if (viewModel.unansweredCount > 0) {
      final continueSubmit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Masih ada jawaban kosong'),
          content: Text(
            '${viewModel.unansweredCount} soal belum dijawab. Tetap kirim jawaban quiz?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Periksa Lagi'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: QuizPalette.primary),
              child: const Text('Tetap Kirim'),
            ),
          ],
        ),
      );
      if (continueSubmit != true || !mounted) return;
    }

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan Quiz'),
        content: const Text('Kirim jawaban quiz sekarang?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: QuizPalette.primary),
            child: const Text('Ya, Kirim'),
          ),
        ],
      ),
    );
    if (submit != true || !mounted) return;

    final success = await viewModel.submitQuiz(widget.quizId);
    if (!mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(viewModel.errorMessage ?? 'Gagal mengirim jawaban.')),
    );
  }

  Future<void> _confirmExit() async {
    final viewModel = context.read<QuizViewModel>();
    if (viewModel.isSubmittingQuiz || viewModel.isExitingQuiz) return;
    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Quiz?'),
        content: const Text(
          'Apakah Anda yakin ingin keluar? Jawaban quiz yang belum dikirim dapat hilang.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: QuizPalette.primary),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (exit != true || !mounted) return;
    final success = await viewModel.exitQuiz(widget.quizId);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz dibatalkan.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Gagal keluar dari quiz.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _confirmExit();
      },
      child: Scaffold(
        backgroundColor: QuizPalette.background,
        body: SafeArea(
          child: Consumer<QuizViewModel>(
            builder: (context, viewModel, _) {
              final question = viewModel.currentQuestion;
              return Column(
                children: <Widget>[
                  _PlayHeader(
                    remainingTime: viewModel.remainingTime,
                    questionNumber: viewModel.currentQuestionNumber,
                    totalQuestions: viewModel.totalQuestions,
                    progress: viewModel.questionProgress,
                    onBack: _confirmExit,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                      child: viewModel.isLoadingQuestion
                          ? const Padding(
                              padding: EdgeInsets.only(top: 80),
                              child: CircularProgressIndicator(color: QuizPalette.primary),
                            )
                          : question == null
                              ? _QuestionErrorState(
                                  message: viewModel.errorMessage ?? 'Soal gagal dimuat.',
                                  onRetry: () => _loadQuestion(viewModel.currentQuestionNumber),
                                )
                              : _QuestionCard(
                                  question: question,
                                  selectedValue: viewModel.getSelectedAnswer(question.id),
                                  disabled: viewModel.isTimeExpired || viewModel.isSubmittingQuiz,
                                  onSelect: (answer) => viewModel.selectAnswer(question.id, answer),
                                ),
                    ),
                  ),
                  _PlayActions(
                    isFirstQuestion: viewModel.currentQuestionNumber <= 1,
                    isLastQuestion: viewModel.isLastQuestion,
                    isBusy: viewModel.isLoadingQuestion ||
                        viewModel.isSubmittingQuiz ||
                        viewModel.isExitingQuiz ||
                        viewModel.isTimeExpired,
                    onPrevious: () => _loadQuestion(viewModel.currentQuestionNumber - 1),
                    onNext: () => _loadQuestion(viewModel.currentQuestionNumber + 1),
                    onSubmit: _submitQuiz,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlayHeader extends StatelessWidget {
  const _PlayHeader({
    required this.remainingTime,
    required this.questionNumber,
    required this.totalQuestions,
    required this.progress,
    required this.onBack,
  });

  final Duration remainingTime;
  final int questionNumber;
  final int totalQuestions;
  final double progress;
  final VoidCallback onBack;

  String get formattedTime {
    final minutes = remainingTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remainingTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 11, 20, 16),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new)),
              const Expanded(
                child: Text('Soal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: QuizPalette.primarySoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.timer_outlined, size: 16, color: QuizPalette.primary),
                    const SizedBox(width: 5),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        color: QuizPalette.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Soal $questionNumber dari $totalQuestions',
                  style: const TextStyle(color: QuizPalette.textSecondary, fontSize: 13),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(color: QuizPalette.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              borderRadius: BorderRadius.circular(10),
              color: QuizPalette.primary,
              backgroundColor: QuizPalette.primarySoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectedValue,
    required this.disabled,
    required this.onSelect,
  });

  final QuizQuestionModel question;
  final String? selectedValue;
  final bool disabled;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: QuizPalette.primary.withValues(alpha: 0.22)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Pilih Jawaban',
            style: TextStyle(color: QuizPalette.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 15),
          Text(
            question.text,
            style: const TextStyle(
              color: QuizPalette.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          ...question.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _OptionButton(
                option: option,
                selected: selectedValue == option.value,
                disabled: disabled,
                onTap: () => onSelect(option.value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.option,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final AnswerOption option;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? QuizPalette.primarySoft : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? QuizPalette.primary : QuizPalette.primary.withValues(alpha: 0.36),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 23,
                width: 23,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? QuizPalette.primary : QuizPalette.textSecondary,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: QuizPalette.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                '${option.label}.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(option.text, style: const TextStyle(height: 1.35)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayActions extends StatelessWidget {
  const _PlayActions({
    required this.isFirstQuestion,
    required this.isLastQuestion,
    required this.isBusy,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  final bool isFirstQuestion;
  final bool isLastQuestion;
  final bool isBusy;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(color: Color(0x0D000000), blurRadius: 14, offset: Offset(0, -5)),
        ],
      ),
      child: Row(
        children: <Widget>[
          if (!isFirstQuestion) ...<Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy ? null : onPrevious,
                style: OutlinedButton.styleFrom(
                  foregroundColor: QuizPalette.primary,
                  side: const BorderSide(color: QuizPalette.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Sebelumnya'),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: FilledButton(
              onPressed: isBusy ? null : (isLastQuestion ? onSubmit : onNext),
              style: FilledButton.styleFrom(
                backgroundColor: QuizPalette.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(isLastQuestion ? 'Selesai' : 'Selanjutnya'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionErrorState extends StatelessWidget {
  const _QuestionErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Center(
        child: Column(
          children: <Widget>[
            const Icon(Icons.error_outline, color: QuizPalette.primary, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
