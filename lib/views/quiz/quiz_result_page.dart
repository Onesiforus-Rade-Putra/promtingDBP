import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/quiz_result_model.dart';
import '../../viewmodels/quiz_view_model.dart';
import '../widgets/quiz_palette.dart';
import 'quiz_play_page.dart';

class QuizResultPage extends StatefulWidget {
  const QuizResultPage({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.initialResult,
  });

  final int quizId;
  final String quizTitle;
  final QuizResultModel initialResult;

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  QuizViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.read<QuizViewModel>();
    if (_viewModel == viewModel) return;
    _viewModel?.removeListener(_handleSessionExpired);
    _viewModel = viewModel..addListener(_handleSessionExpired);
  }

  void _handleSessionExpired() {
    final viewModel = _viewModel;
    if (!mounted || viewModel == null || !viewModel.shouldRedirectToLogin) return;
    viewModel.consumeLoginRedirect();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi Anda telah berakhir. Silakan login kembali.')),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    });
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_handleSessionExpired);
    super.dispose();
  }

  Future<void> _backToQuest() async {
    context.read<QuizViewModel>().clearActiveQuiz();
    Navigator.of(context).pop();
  }

  Future<void> _retryQuiz() async {
    final viewModel = context.read<QuizViewModel>();
    final begin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ulangi Quiz?'),
        content: const Text('Waktu akan berjalan kembali setelah quiz dimulai.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: QuizPalette.primary),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
    if (begin != true || !mounted) return;
    viewModel.clearActiveQuiz();
    final success = await viewModel.startQuiz(widget.quizId);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => QuizPlayPage(quizId: widget.quizId, quizTitle: widget.quizTitle),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Quiz gagal dimulai.')),
      );
    }
  }

  Future<void> _generateCertificate() async {
    final viewModel = context.read<QuizViewModel>();
    final id = await viewModel.generateCertificate(widget.quizId);
    if (!mounted) return;
    if (id != null && id.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sertifikat berhasil dibuat.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Sertifikat gagal dibuat.')),
      );
    }
  }

  void _showCertificateInformation(String certificateId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sertifikat tersedia (ID: $certificateId). Endpoint download file belum tersedia pada dokumentasi API.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizPalette.background,
      appBar: AppBar(
        title: const Text('Quiz Selesai'),
        automaticallyImplyLeading: false,
        backgroundColor: QuizPalette.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Consumer<QuizViewModel>(
          builder: (context, viewModel, _) {
            final result = viewModel.quizResult ?? widget.initialResult;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: QuizPalette.primary.withValues(alpha: 0.18)),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(color: Color(0x10000000), blurRadius: 22, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 70,
                        width: 70,
                        decoration: const BoxDecoration(
                          color: QuizPalette.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events, color: Colors.white, size: 37),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Quiz Selesai!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        result.passed
                            ? 'Selamat, Anda lulus! Kamu menjawab ${result.correctAnswers} dari ${result.totalQuestions} soal dengan benar.'
                            : 'Anda belum lulus. Kamu menjawab ${result.correctAnswers} dari ${result.totalQuestions} soal dengan benar. Coba lagi.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: QuizPalette.textSecondary, height: 1.45),
                      ),
                      const SizedBox(height: 19),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: result.passed ? QuizPalette.successSoft : QuizPalette.primarySoft,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          result.passed
                              ? 'Lulus · Minimum score ${result.minimumScore}'
                              : 'Belum lulus · Minimum score ${result.minimumScore}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: result.passed ? QuizPalette.success : QuizPalette.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _RewardCard(
                              icon: Icons.star_rounded,
                              title: '+${result.pointsGained} Poin',
                              subtitle: 'XP Reward',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RewardCard(
                              icon: Icons.local_fire_department,
                              title: '${result.streakCount} Streak',
                              subtitle: '+${result.streakBonus} Bonus',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 23),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _backToQuest,
                          style: FilledButton.styleFrom(
                            backgroundColor: QuizPalette.primary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Kembali ke Quest'),
                        ),
                      ),
                      if (result.passed) ...<Widget>[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: viewModel.isGeneratingCertificate
                                ? null
                                : result.certificateId == null
                                    ? _generateCertificate
                                    : () => _showCertificateInformation(result.certificateId!),
                            style: FilledButton.styleFrom(
                              backgroundColor: QuizPalette.success,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            icon: viewModel.isGeneratingCertificate
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.workspace_premium_outlined),
                            label: Text(
                              result.certificateId == null
                                  ? 'Generate Sertifikat'
                                  : 'Download Sertifikat',
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _retryQuiz,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: QuizPalette.primary,
                            side: const BorderSide(color: QuizPalette.primary),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 14),
      decoration: BoxDecoration(
        color: QuizPalette.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: QuizPalette.primary),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: QuizPalette.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: QuizPalette.textSecondary)),
        ],
      ),
    );
  }
}
