import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/achievement_model.dart';
import '../../models/leaderboard_response_model.dart';
import '../../models/quest_model.dart';
import '../../viewmodels/dashboard_viewmodel.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color primaryRed = Color(0xFFE53935);
  static const Color darkRed = Color(0xFFB71C1C);
  static const Color softRed = Color(0xFFFFEBEE);
  static const Color textDark = Color(0xFF222222);

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final vm = context.read<DashboardViewModel>();
      await vm.loadDashboardData();

      if (!mounted) return;
      _handleSessionExpired(vm);
    });
  }

  void _handleSessionExpired(DashboardViewModel vm) {
    if (!vm.isSessionExpired) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(vm.errorMessage ??
            'Sesi Anda telah berakhir. Silakan login kembali.'),
      ),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  Future<void> _navigateAndRefresh(String routeName) async {
    await Navigator.pushNamed(context, routeName);

    if (!mounted) return;

    final vm = context.read<DashboardViewModel>();
    await vm.refreshDashboard();

    if (!mounted) return;
    _handleSessionExpired(vm);
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
  }

  double _percentToProgress(int percentage) {
    return (percentage / 100).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading && !vm.hasAnyData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!vm.hasAnyData && vm.errorMessage != null) {
          return Scaffold(
            body: _FullPageError(
              message: vm.errorMessage!,
              onRetry: () async {
                await vm.refreshDashboard();

                if (!context.mounted) return;
                _handleSessionExpired(vm);
              },
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F8F8),
          bottomNavigationBar: _BottomNavBar(
            onTap: (index) {
              switch (index) {
                case 0:
                  break;
                case 1:
                  _navigateAndRefresh('/forum');
                  break;
                case 2:
                  _navigateAndRefresh('/quiz-list');
                  break;
                case 3:
                  _navigateAndRefresh('/leaderboard');
                  break;
                case 4:
                  _navigateAndRefresh('/settings');
                  break;
              }
            },
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await vm.refreshDashboard();

              if (!context.mounted) return;
              _handleSessionExpired(vm);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryRed, darkRed],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeaderSection(
                              vm: vm,
                              formatNumber: _formatNumber,
                              onProfileTap: () =>
                                  _navigateAndRefresh('/profile'),
                            ),
                            const SizedBox(height: 20),
                            _HeaderStatsSection(
                              vm: vm,
                              formatNumber: _formatNumber,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ProgressWelcomeCard(
                          vm: vm,
                          formatNumber: _formatNumber,
                        ),
                        const SizedBox(height: 16),
                        _ActionButtons(
                          onQuizTap: () => _navigateAndRefresh('/quiz-list'),
                          onTargetTap: () =>
                              _navigateAndRefresh('/target-task/add'),
                        ),
                        const SizedBox(height: 16),
                        _GamificationSection(
                          vm: vm,
                          formatNumber: _formatNumber,
                        ),
                        const SizedBox(height: 16),
                        _QuestSection(
                          vm: vm,
                          percentToProgress: _percentToProgress,
                          onRetry: () => vm.loadQuests(
                            frequency: vm.selectedQuestFrequency,
                          ),
                          onViewAll: () => _navigateAndRefresh('/quest'),
                        ),
                        const SizedBox(height: 16),
                        _ExploreFeatureGrid(
                          onAchievementTap: () =>
                              _navigateAndRefresh('/achievement'),
                          onTargetTap: () =>
                              _navigateAndRefresh('/target-task'),
                          onForumTap: () => _navigateAndRefresh('/forum'),
                          onLeaderboardTap: () =>
                              _navigateAndRefresh('/leaderboard'),
                        ),
                        const SizedBox(height: 16),
                        _TaskSummarySection(
                          vm: vm,
                          onTap: () => _navigateAndRefresh('/target-task'),
                          onRetry: vm.loadTaskSummary,
                        ),
                        const SizedBox(height: 16),
                        _AchievementSection(
                          vm: vm,
                          percentToProgress: _percentToProgress,
                          onRetry: vm.loadAchievements,
                          onViewAll: () => _navigateAndRefresh('/achievement'),
                        ),
                        const SizedBox(height: 16),
                        _LeaderboardSection(
                          vm: vm,
                          formatNumber: _formatNumber,
                          onRetry: vm.loadLeaderboard,
                          onViewAll: () => _navigateAndRefresh('/leaderboard'),
                        ),
                        const SizedBox(height: 16),
                        _RecentActivitySection(
                          quests: vm.quests,
                          achievements: vm.achievements,
                          formatNumber: _formatNumber,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final DashboardViewModel vm;
  final String Function(int value) formatNumber;
  final VoidCallback onProfileTap;

  const _HeaderSection({
    required this.vm,
    required this.formatNumber,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final profile = vm.profile;
    final summary = vm.gamificationSummary;

    final name = profile?.displayName ?? 'Mahasiswa';
    final level = summary?.currentLevel ?? profile?.currentLevel ?? 0;
    final xp = summary?.totalXpEarned ?? profile?.totalXp ?? 0;

    return Row(
      children: [
        Expanded(
          child: vm.isLoadingProfile
              ? const _SmallWhiteLoader()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, $name!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Siap Belajar Hari ini?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level $level • ${formatNumber(xp)} XP',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderStatsSection extends StatelessWidget {
  final DashboardViewModel vm;
  final String Function(int value) formatNumber;

  const _HeaderStatsSection({
    required this.vm,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    final summary = vm.gamificationSummary;
    final profile = vm.profile;
    final leaderboard = vm.leaderboard;

    final xp = summary?.totalXpEarned ?? profile?.totalXp ?? 0;
    final rank = summary?.currentRanking ?? leaderboard?.userRank ?? 0;
    final streak = summary?.currentStreak ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.bolt_rounded,
            label: 'Total XP',
            value: formatNumber(xp),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events_rounded,
            label: 'Ranking',
            value: rank > 0 ? '#$rank' : '-',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Streak',
            value: '$streak hari',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressWelcomeCard extends StatelessWidget {
  final DashboardViewModel vm;
  final String Function(int value) formatNumber;

  const _ProgressWelcomeCard({
    required this.vm,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    final summary = vm.gamificationSummary;
    final completed = summary?.totalQuestCompleted ?? 0;
    final total = summary?.totalQuest ?? 0;
    final currentXp = summary?.currentLevelXp ?? 0;
    final remainingXp = summary?.nextLevelRequiredXpDiff ?? 0;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selamat Datang Kembali',
            style: TextStyle(
              color: Color(0xFF222222),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            total > 0
                ? '$completed dari $total quest selesai hari ini'
                : 'Mulai quest untuk meningkatkan XP kamu',
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: vm.levelProgress,
              minHeight: 10,
              backgroundColor: const Color(0xFFFFCDD2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFE53935),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            remainingXp > 0
                ? '${formatNumber(currentXp)} XP terkumpul • Butuh ${formatNumber(remainingXp)} XP lagi'
                : '${formatNumber(currentXp)} XP pada level saat ini',
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onQuizTap;
  final VoidCallback onTargetTap;

  const _ActionButtons({
    required this.onQuizTap,
    required this.onTargetTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onQuizTap,
            icon: const Icon(Icons.quiz_rounded),
            label: const Text('Mulai Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE53935),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTargetTap,
            icon: const Icon(Icons.add_task_rounded),
            label: const Text('Tambah Target'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFFE53935),
              side: const BorderSide(color: Color(0xFFE53935)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GamificationSection extends StatelessWidget {
  final DashboardViewModel vm;
  final String Function(int value) formatNumber;

  const _GamificationSection({
    required this.vm,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    final summary = vm.gamificationSummary;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Progress Belajar',
            icon: Icons.auto_graph_rounded,
          ),
          const SizedBox(height: 14),
          if (vm.isLoadingGamification)
            const _SectionLoader()
          else if (vm.gamificationError != null)
            _SectionError(
              message: vm.gamificationError!,
              onRetry: vm.loadGamificationSummary,
            )
          else if (summary == null)
            const _EmptyText('Data gamifikasi belum tersedia.')
          else ...[
            Row(
              children: [
                Expanded(
                  child: _MiniInfoBox(
                    label: 'Level',
                    value: '${summary.currentLevel}',
                    icon: Icons.military_tech_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniInfoBox(
                    label: 'Ranking',
                    value: summary.currentRanking > 0
                        ? '#${summary.currentRanking}'
                        : '-',
                    icon: Icons.leaderboard_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniInfoBox(
                    label: 'XP',
                    value: formatNumber(summary.totalXpEarned),
                    icon: Icons.bolt_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniInfoBox(
                    label: 'Streak',
                    value: '${summary.currentStreak} hari',
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestSection extends StatelessWidget {
  final DashboardViewModel vm;
  final double Function(int percentage) percentToProgress;
  final VoidCallback onRetry;
  final VoidCallback onViewAll;

  const _QuestSection({
    required this.vm,
    required this.percentToProgress,
    required this.onRetry,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final completed = vm.gamificationSummary?.totalQuestCompleted ?? 0;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeaderWithAction(
            title: 'Quest Harian',
            icon: Icons.flag_rounded,
            actionLabel: 'Lihat Semua',
            onActionTap: onViewAll,
          ),
          const SizedBox(height: 6),
          const Text(
            'Selesaikan 3 Quest & Raih Bonus',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(3, (index) {
              final isActive = index < completed;

              return Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isActive
                          ? const Color(0xFFE53935)
                          : const Color(0xFFFFCDD2),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color:
                              isActive ? Colors.white : const Color(0xFFE53935),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (index != 2)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: isActive
                              ? const Color(0xFFE53935)
                              : const Color(0xFFFFCDD2),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _FrequencyChip(
                label: 'Harian',
                selected: vm.selectedQuestFrequency == 'harian',
                onTap: () => vm.changeQuestFrequency('harian'),
              ),
              const SizedBox(width: 8),
              _FrequencyChip(
                label: 'Mingguan',
                selected: vm.selectedQuestFrequency == 'mingguan',
                onTap: () => vm.changeQuestFrequency('mingguan'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (vm.isLoadingQuests)
            const _SectionLoader()
          else if (vm.questsError != null)
            _SectionError(
              message: vm.questsError!,
              onRetry: onRetry,
            )
          else if (vm.quests.isEmpty)
            const _EmptyText('Belum ada quest.')
          else
            Column(
              children: vm.quests.take(3).map((quest) {
                return _QuestItem(
                  quest: quest,
                  progress: percentToProgress(quest.progressPercentage),
                );
              }).toList(),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Mulai'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FrequencyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFE53935),
      backgroundColor: const Color(0xFFFFEBEE),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFFE53935),
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE53935)),
      ),
    );
  }
}

class _QuestItem extends StatelessWidget {
  final QuestModel quest;
  final double progress;

  const _QuestItem({
    required this.quest,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  quest.title,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '+${quest.xpReward} XP',
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            quest.description,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFFFCDD2),
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _DifficultyLabel(value: quest.difficulty),
              const Spacer(),
              Text(
                quest.isCompleted ? 'Selesai' : '${quest.progressPercentage}%',
                style: TextStyle(
                  color: quest.isCompleted
                      ? Colors.green
                      : const Color(0xFF777777),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExploreFeatureGrid extends StatelessWidget {
  final VoidCallback onAchievementTap;
  final VoidCallback onTargetTap;
  final VoidCallback onForumTap;
  final VoidCallback onLeaderboardTap;

  const _ExploreFeatureGrid({
    required this.onAchievementTap,
    required this.onTargetTap,
    required this.onForumTap,
    required this.onLeaderboardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionTitle(
          title: 'Jelajahi Fitur',
          icon: Icons.dashboard_customize_rounded,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _FeatureCard(
              icon: Icons.emoji_events_rounded,
              title: 'Achievement',
              description: 'Lihat pencapaianmu',
              onTap: onAchievementTap,
            ),
            _FeatureCard(
              icon: Icons.task_alt_rounded,
              title: 'Target dan Tugas',
              description: 'Kelola target belajar',
              onTap: onTargetTap,
            ),
            _FeatureCard(
              icon: Icons.forum_rounded,
              title: 'Forum',
              description: 'Diskusi bersama teman',
              onTap: onForumTap,
            ),
            _FeatureCard(
              icon: Icons.leaderboard_rounded,
              title: 'Leaderboard',
              description: 'Cek ranking belajar',
              onTap: onLeaderboardTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE53935), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFFFEBEE),
                child: Icon(icon, color: const Color(0xFFE53935), size: 22),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF222222),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskSummarySection extends StatelessWidget {
  final DashboardViewModel vm;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  const _TaskSummarySection({
    required this.vm,
    required this.onTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final task = vm.taskSummary;

    return _SectionCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Target Aktif',
            icon: Icons.track_changes_rounded,
          ),
          const SizedBox(height: 14),
          if (vm.isLoadingTaskSummary)
            const _SectionLoader()
          else if (vm.taskSummaryError != null)
            _SectionError(
              message: vm.taskSummaryError!,
              onRetry: onRetry,
            )
          else if (task == null)
            const _EmptyText('Ringkasan target belum tersedia.')
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MiniInfoBox(
                        label: 'Selesai',
                        value: '${task.taskCompleted}',
                        icon: Icons.check_circle_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniInfoBox(
                        label: 'Todo',
                        value: '${task.todo}',
                        icon: Icons.radio_button_unchecked_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniInfoBox(
                        label: 'On Progress',
                        value: '${task.onProgress}',
                        icon: Icons.timelapse_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniInfoBox(
                        label: 'High Priority',
                        value: '${task.highPriority}',
                        icon: Icons.priority_high_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 12),
          const _SampleTargetCard(
            title: 'Belajar Flutter MVVM',
            description: 'Selesaikan integrasi dashboard dengan API',
            deadline: 'Deadline: Hari ini',
            priority: 'High',
          ),
        ],
      ),
    );
  }
}

class _SampleTargetCard extends StatelessWidget {
  final String title;
  final String description;
  final String deadline;
  final String priority;

  const _SampleTargetCard({
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
  });

  Color _priorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deadline,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              priority,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementSection extends StatelessWidget {
  final DashboardViewModel vm;
  final double Function(int percentage) percentToProgress;
  final VoidCallback onRetry;
  final VoidCallback onViewAll;

  const _AchievementSection({
    required this.vm,
    required this.percentToProgress,
    required this.onRetry,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeaderWithAction(
            title: 'Achievement',
            icon: Icons.workspace_premium_rounded,
            actionLabel: 'Lihat Semua',
            onActionTap: onViewAll,
          ),
          const SizedBox(height: 14),
          if (vm.isLoadingAchievements)
            const _SectionLoader()
          else if (vm.achievementsError != null)
            _SectionError(
              message: vm.achievementsError!,
              onRetry: onRetry,
            )
          else if (vm.achievements.isEmpty)
            const _EmptyText('Belum ada achievement.')
          else
            Column(
              children: vm.achievements.take(3).map((achievement) {
                return _AchievementItem(
                  achievement: achievement,
                  progress: percentToProgress(achievement.progressPercentage),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final AchievementModel achievement;
  final double progress;

  const _AchievementItem({
    required this.achievement,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achievement.isCompleted
            ? Colors.green.withOpacity(0.08)
            : const Color(0xFFFFFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: achievement.isCompleted
              ? Colors.green.withOpacity(0.35)
              : const Color(0xFFFFCDD2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                achievement.isCompleted
                    ? Icons.verified_rounded
                    : Icons.workspace_premium_rounded,
                color: achievement.isCompleted
                    ? Colors.green
                    : const Color(0xFFE53935),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  achievement.title,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '+${achievement.xpReward} XP',
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFFFCDD2),
            valueColor: AlwaysStoppedAnimation<Color>(
              achievement.isCompleted ? Colors.green : const Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _DifficultyLabel(value: achievement.difficulty),
              const Spacer(),
              Text(
                achievement.isCompleted
                    ? 'Selesai'
                    : '${achievement.progressPercentage}%',
                style: TextStyle(
                  color: achievement.isCompleted
                      ? Colors.green
                      : const Color(0xFF777777),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardSection extends StatelessWidget {
  final DashboardViewModel vm;
  final String Function(int value) formatNumber;
  final VoidCallback onRetry;
  final VoidCallback onViewAll;

  const _LeaderboardSection({
    required this.vm,
    required this.formatNumber,
    required this.onRetry,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final leaderboard = vm.leaderboard;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeaderWithAction(
            title: 'Leaderboard',
            icon: Icons.leaderboard_rounded,
            actionLabel: 'Lihat Leaderboard',
            onActionTap: onViewAll,
          ),
          const SizedBox(height: 14),
          if (vm.isLoadingLeaderboard)
            const _SectionLoader()
          else if (vm.leaderboardError != null)
            _SectionError(
              message: vm.leaderboardError!,
              onRetry: onRetry,
            )
          else if (leaderboard == null)
            const _EmptyText('Leaderboard belum tersedia.')
          else ...[
            Row(
              children: [
                Expanded(
                  child: _MiniInfoBox(
                    label: 'Ranking Kamu',
                    value: leaderboard.userRank > 0
                        ? '#${leaderboard.userRank}'
                        : '-',
                    icon: Icons.emoji_events_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniInfoBox(
                    label: 'Total XP',
                    value: formatNumber(leaderboard.userTotalXp),
                    icon: Icons.bolt_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (leaderboard.topGlobal.isEmpty)
              const _EmptyText('Belum ada data top global.')
            else
              Column(
                children: leaderboard.topGlobal.take(3).map((item) {
                  return _LeaderboardItem(
                    item: item,
                    formatNumber: formatNumber,
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final LeaderboardItemModel item;
  final String Function(int value) formatNumber;

  const _LeaderboardItem({
    required this.item,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: const Color(0xFFFFEBEE),
            child: Text(
              '#${item.rank}',
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.user.displayName,
              style: const TextStyle(
                color: Color(0xFF222222),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${formatNumber(item.xp)} XP',
            style: const TextStyle(
              color: Color(0xFFE53935),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  final List<QuestModel> quests;
  final List<AchievementModel> achievements;
  final String Function(int value) formatNumber;

  const _RecentActivitySection({
    required this.quests,
    required this.achievements,
    required this.formatNumber,
  });

  @override
  Widget build(BuildContext context) {
    final completedQuest = quests.where((quest) => quest.isCompleted).toList();
    final completedAchievement =
        achievements.where((achievement) => achievement.isCompleted).toList();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Aktivitas Terbaru',
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: 14),
          if (completedQuest.isEmpty && completedAchievement.isEmpty)
            const _EmptyText('Belum ada aktivitas terbaru.')
          else ...[
            if (completedQuest.isNotEmpty)
              _ActivityItem(
                title: 'Menyelesaikan quest',
                time: 'Baru saja',
                reward: '+${formatNumber(completedQuest.first.xpReward)} XP',
              ),
            if (completedAchievement.isNotEmpty)
              _ActivityItem(
                title: 'Membuka achievement',
                time: 'Baru saja',
                reward:
                    '+${formatNumber(completedAchievement.first.xpReward)} XP',
              ),
          ],
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final String reward;

  const _ActivityItem({
    required this.title,
    required this.time,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFFFEBEE),
            child: Icon(
              Icons.check_rounded,
              color: Color(0xFFE53935),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            reward,
            style: const TextStyle(
              color: Color(0xFFE53935),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _SectionCard({
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: card,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE53935), size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderWithAction extends StatelessWidget {
  final String title;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onActionTap;

  const _SectionHeaderWithAction({
    required this.title,
    required this.icon,
    required this.actionLabel,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SectionTitle(title: title, icon: icon),
        ),
        TextButton(
          onPressed: onActionTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: Color(0xFFE53935),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniInfoBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyLabel extends StatelessWidget {
  final String value;

  const _DifficultyLabel({
    required this.value,
  });

  Color _color() {
    switch (value.toLowerCase()) {
      case 'hard':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'easy':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SectionLoader extends StatelessWidget {
  const _SectionLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _SmallWhiteLoader extends StatelessWidget {
  const _SmallWhiteLoader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Memuat profil...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

class _SectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SectionError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE53935),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
              side: const BorderSide(color: Color(0xFFE53935)),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String message;

  const _EmptyText(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF777777),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _FullPageError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FullPageError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE53935),
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFE53935),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withOpacity(0.65),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum_rounded),
          label: 'Forum',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz_rounded),
          label: 'Quiz',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard_rounded),
          label: 'Leaderboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }
}
