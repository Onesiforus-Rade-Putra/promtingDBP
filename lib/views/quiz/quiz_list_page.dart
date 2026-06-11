import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/quiz_model.dart';
import '../../viewmodels/quiz_view_model.dart';
import '../widgets/quiz_palette.dart';
import 'quiz_play_page.dart';

class QuizListPage extends StatefulWidget {
  const QuizListPage({super.key, this.onBottomNavigationTap});

  /// Hubungkan callback ini ke shell navigation aplikasi Anda.
  final ValueChanged<int>? onBottomNavigationTap;

  @override
  State<QuizListPage> createState() => _QuizListPageState();
}

class _QuizListPageState extends State<QuizListPage> {
  QuizViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.read<QuizViewModel>();
    if (_viewModel == viewModel) return;
    _viewModel?.removeListener(_handleViewModelEvent);
    _viewModel = viewModel..addListener(_handleViewModelEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && viewModel.quizzes.isEmpty && !viewModel.isLoadingQuizList) {
        viewModel.loadQuizzes();
      }
    });
  }

  void _handleViewModelEvent() {
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
    _viewModel?.removeListener(_handleViewModelEvent);
    super.dispose();
  }

  Future<void> _confirmAndStartQuiz(QuizModel quiz) async {
    final start = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mulai Quiz?'),
        content: const Text(
          'Apakah Anda siap memulai quiz? Waktu akan berjalan setelah quiz dimulai.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: QuizPalette.primary),
            child: const Text('Mulai'),
          ),
        ],
      ),
    );
    if (start != true || !mounted) return;

    final viewModel = context.read<QuizViewModel>();
    final success = await viewModel.startQuiz(quiz.id);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Quiz gagal dimulai.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizPlayPage(quizId: quiz.id, quizTitle: quiz.title),
      ),
    );
    if (mounted) await viewModel.loadQuizzes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuizPalette.background,
      body: SafeArea(
        child: Consumer<QuizViewModel>(
          builder: (context, viewModel, _) {
            return RefreshIndicator(
              color: QuizPalette.primary,
              onRefresh: viewModel.loadQuizzes,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _QuizHeader(viewModel: viewModel),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _Tabs(),
                        const SizedBox(height: 18),
                        _StreakCard(viewModel: viewModel),
                        const SizedBox(height: 22),
                        if (viewModel.isLoadingQuizList && viewModel.quizzes.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(36),
                              child: CircularProgressIndicator(color: QuizPalette.primary),
                            ),
                          )
                        else if (viewModel.errorMessage != null && viewModel.quizzes.isEmpty)
                          _ErrorState(
                            message: viewModel.errorMessage!,
                            onRetry: viewModel.loadQuizzes,
                          )
                        else if (viewModel.quizzes.isEmpty)
                          const _EmptyState()
                        else ...<Widget>[
                          const Text(
                            'Rekomendasi Untuk Kamu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: QuizPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _RecommendedCard(
                            quiz: _recommendedQuiz(viewModel.quizzes),
                            isBusy: viewModel.isStartingQuiz,
                            onStart: _confirmAndStartQuiz,
                          ),
                          const SizedBox(height: 25),
                          const Text(
                            'Semua Quiz',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: QuizPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...viewModel.quizzes.map(
                            (quiz) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _QuizCard(
                                quiz: quiz,
                                isBusy: viewModel.isStartingQuiz,
                                onStart: _confirmAndStartQuiz,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        indicatorColor: QuizPalette.primarySoft,
        onDestinationSelected: (index) {
          if (index != 2) widget.onBottomNavigationTap?.call(index);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), label: 'Forum'),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz, color: QuizPalette.primary),
            label: 'Quiz',
          ),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), label: 'Leaderboard'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  QuizModel _recommendedQuiz(List<QuizModel> quizzes) {
    return quizzes.firstWhere(
      (quiz) => !quiz.lastAttemptSuccessfull,
      orElse: () => quizzes.first,
    );
  }
}

class _QuizHeader extends StatelessWidget {
  const _QuizHeader({required this.viewModel});

  final QuizViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final completed = viewModel.quizzes.where((quiz) => quiz.lastAttemptSuccessfull).length;
    const dailyTarget = 4;
    final shownCompleted = completed.clamp(0, dailyTarget);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF54850), QuizPalette.primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Quiz dan Quest',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 7),
          const Text(
            'Selesaikan tantangan untuk mendapatkan XP dan Sertifikat!',
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Progress Harian',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '$shownCompleted/$dailyTarget Quiz',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: shownCompleted / dailyTarget,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: QuizPalette.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Quiz',
                style: TextStyle(color: QuizPalette.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Quest', style: TextStyle(color: QuizPalette.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.viewModel});

  final QuizViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final streak = viewModel.quizResult?.streakCount;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: QuizPalette.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.local_fire_department, color: Color(0xFFF57C00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Streak Kamu', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  streak == null ? 'Selesaikan quiz hari ini' : '$streak hari · Teruskan!',
                  style: const TextStyle(color: QuizPalette.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.quiz, required this.isBusy, required this.onStart});

  final QuizModel quiz;
  final bool isBusy;
  final ValueChanged<QuizModel> onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: QuizPalette.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(quiz.category, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              _DifficultyBadge(difficulty: quiz.difficulty, light: true),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quiz.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _WhiteMeta(icon: Icons.schedule, label: '${quiz.durationMinutes} menit'),
              const SizedBox(width: 16),
              _WhiteMeta(icon: Icons.star_border, label: '+${quiz.xpReward} XP'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isBusy ? null : () => onStart(quiz),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: QuizPalette.primary,
                disabledBackgroundColor: Colors.white60,
              ),
              child: const Text('Mulai Quiz'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.quiz, required this.isBusy, required this.onStart});

  final QuizModel quiz;
  final bool isBusy;
  final ValueChanged<QuizModel> onStart;

  @override
  Widget build(BuildContext context) {
    final passed = quiz.lastAttemptSuccessfull;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: QuizPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  quiz.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              _DifficultyBadge(difficulty: quiz.difficulty),
            ],
          ),
          const SizedBox(height: 5),
          Text(quiz.category, style: const TextStyle(color: QuizPalette.textSecondary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 13,
            runSpacing: 8,
            children: <Widget>[
              _Meta(icon: Icons.schedule_outlined, label: '${quiz.durationMinutes} menit'),
              _Meta(icon: Icons.star_outline, label: '${quiz.xpReward} XP'),
              _Meta(icon: Icons.flag_outlined, label: 'Min ${quiz.minimumScore}'),
              _Meta(icon: Icons.done_all, label: '${quiz.completionCount}x selesai'),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: passed ? QuizPalette.successSoft : QuizPalette.primarySoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  passed ? 'Lulus' : 'Belum lulus',
                  style: TextStyle(
                    color: passed ? QuizPalette.success : QuizPalette.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (passed && quiz.certificateId != null) ...<Widget>[
                const SizedBox(width: 8),
                const Icon(Icons.workspace_premium_outlined, size: 19, color: QuizPalette.success),
                const Text(
                  ' Sertifikat',
                  style: TextStyle(color: QuizPalette.success, fontSize: 12),
                ),
              ],
              const Spacer(),
              TextButton(
                onPressed: isBusy ? null : () => onStart(quiz),
                child: Text(passed ? 'Ulangi' : 'Mulai Quiz'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 15, color: QuizPalette.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: QuizPalette.textSecondary)),
      ],
    );
  }
}

class _WhiteMeta extends StatelessWidget {
  const _WhiteMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty, this.light = false});

  final String difficulty;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final text = switch (difficulty.toLowerCase()) {
      'hard' => 'Sulit',
      'medium' => 'Sedang',
      _ => 'Mudah',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: light ? Colors.white24 : QuizPalette.primarySoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: light ? Colors.white : QuizPalette.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 34),
        child: Column(
          children: <Widget>[
            const Icon(Icons.cloud_off_outlined, size: 44, color: QuizPalette.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 42),
      child: Center(child: Text('Belum ada quiz yang tersedia.')),
    );
  }
}
