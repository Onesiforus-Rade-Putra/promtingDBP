import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../models/task_summary_model.dart';
import '../viewmodels/progress_tracking_view_model.dart';
import 'task_form_page.dart';

class TargetTaskPage extends StatefulWidget {
  const TargetTaskPage({super.key});

  @override
  State<TargetTaskPage> createState() => _TargetTaskPageState();
}

class _TargetTaskPageState extends State<TargetTaskPage> {
  static const Color _primaryRed = Color(0xFFE51E3A);
  static const Color _darkRed = Color(0xFFA80920);

  ProgressTrackingViewModel? _viewModel;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.read<ProgressTrackingViewModel>();
    if (_viewModel != viewModel) {
      _viewModel?.removeListener(_handleFeedback);
      _viewModel = viewModel..addListener(_handleFeedback);
    }
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) viewModel.refreshData();
      });
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_handleFeedback);
    super.dispose();
  }

  void _handleFeedback() {
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    final viewModel = _viewModel!;

    if (viewModel.takeSessionExpired()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
      return;
    }

    final error = viewModel.takeErrorMessage();
    final success = viewModel.takeSuccessMessage();
    if (error != null) {
      _showSnackBar(error);
    } else if (success != null) {
      _showSnackBar(success);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openAddTaskForm() async {
    final viewModel = context.read<ProgressTrackingViewModel>();
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider<ProgressTrackingViewModel>.value(
          value: viewModel,
          child: const TaskFormPage(),
        ),
      ),
    );

    if (!mounted || created != true) return;
    _showSnackBar(
      viewModel.takeSuccessMessage() ?? 'Tugas berhasil ditambahkan.',
    );
  }

  Future<void> _confirmDelete(TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Tugas?'),
        content: const Text('Apakah Anda yakin ingin menghapus tugas ini?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _primaryRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ProgressTrackingViewModel>().removeTask(task.id);
    }
  }

  void _showEditApiUnavailable() {
    _showSnackBar(
      'Endpoint edit detail tugas belum tersedia pada dokumentasi API.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProgressTrackingViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTaskForm,
        backgroundColor: _primaryRed,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.refreshData,
          color: _primaryRed,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _GradientHeader(
                  summary: viewModel.summary,
                  isLoading: viewModel.isLoadingSummary,
                  onBack: () => Navigator.maybePop(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 88),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed(
                    <Widget>[
                      _SummarySection(
                        summary: viewModel.summary,
                        isLoading: viewModel.isLoadingSummary,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Kategori',
                        style: TextStyle(
                          color: Color(0xFF171A23),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CategoryFilter(
                        selectedCategory: viewModel.selectedCategory,
                        onSelected: viewModel.changeCategoryFilter,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Daftar Tugas',
                            style: TextStyle(
                              color: Color(0xFF171A23),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${viewModel.tasks.length} tugas',
                            style: const TextStyle(
                              color: Color(0xFF7B7F8D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (viewModel.isLoadingTasks && viewModel.tasks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Center(
                            child:
                                CircularProgressIndicator(color: _primaryRed),
                          ),
                        )
                      else if (viewModel.tasks.isEmpty)
                        const _EmptyState()
                      else
                        ...viewModel.tasks.map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TaskCard(
                              task: task,
                              isUpdating: viewModel.isUpdating(task.id),
                              isDeleting: viewModel.isDeleting(task.id),
                              onToggleCompleted: (value) {
                                viewModel.changeTaskProgress(
                                  task.id,
                                  value
                                      ? TaskProgress.completed.apiValue
                                      : TaskProgress.todo.apiValue,
                                );
                              },
                              onProgressChanged: (progress) {
                                viewModel.changeTaskProgress(
                                  task.id,
                                  progress.apiValue,
                                );
                              },
                              onEdit: _showEditApiUnavailable,
                              onDelete: () => _confirmDelete(task),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientHeader extends StatelessWidget {
  const _GradientHeader({
    required this.summary,
    required this.isLoading,
    required this.onBack,
  });

  final TaskSummaryModel? summary;
  final bool isLoading;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final completed = summary?.taskCompleted ?? 0;
    final total = summary?.totalTasks ?? 0;
    final ratio = summary?.completionRatio ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 18, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            _TargetTaskPageState._primaryRed,
            _TargetTaskPageState._darkRed,
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Text(
                'Target dan Tugas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
              ),
            ),
            child: isLoading && summary == null
                ? const SizedBox(
                    height: 74,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$completed dari $total tugas selesai',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 13),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.28),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Konsistensi adalah kunci keberhasilan akademikmu!',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white,
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

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary, required this.isLoading});

  final TaskSummaryModel? summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && summary == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(
              color: _TargetTaskPageState._primaryRed),
        ),
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.78,
      children: <Widget>[
        _SummaryCard(
          title: 'Tugas Selesai',
          value: summary?.taskCompleted ?? 0,
          icon: Icons.check_circle_outline,
        ),
        _SummaryCard(
          title: 'Belum Dikerjakan',
          value: summary?.todo ?? 0,
          icon: Icons.assignment_outlined,
        ),
        _SummaryCard(
          title: 'Sedang Berjalan',
          value: summary?.onProgress ?? 0,
          icon: Icons.timelapse,
        ),
        _SummaryCard(
          title: 'Prioritas Tinggi',
          value: summary?.highPriority ?? 0,
          icon: Icons.priority_high_rounded,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 21,
              color: _TargetTaskPageState._primaryRed,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171A23),
                  ),
                ),
                Text(
                  title,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Color(0xFF717688),
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

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.selectedCategory,
    required this.onSelected,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    const categories = <String?, String>{
      null: 'Semua',
      'akademik': 'Akademik',
      'pribadi': 'Pribadi',
      'organisasi': 'Organisasi',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.entries.map((entry) {
          final selected = selectedCategory == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onSelected(entry.key),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFFFE5E8),
              labelStyle: TextStyle(
                color: selected
                    ? _TargetTaskPageState._primaryRed
                    : const Color(0xFF565B69),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              side: BorderSide(
                color: selected
                    ? const Color(0xFFF5B4BC)
                    : const Color(0xFFE9EBF0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.isUpdating,
    required this.isDeleting,
    required this.onToggleCompleted,
    required this.onProgressChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskModel task;
  final bool isUpdating;
  final bool isDeleting;
  final ValueChanged<bool> onToggleCompleted;
  final ValueChanged<TaskProgress> onProgressChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _priorityColor {
    switch (task.priority) {
      case 'tinggi':
        return const Color(0xFFD92743);
      case 'sedang':
        return const Color(0xFFF49A25);
      case 'rendah':
        return const Color(0xFF25A565);
      default:
        return const Color(0xFF777C89);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = isUpdating || isDeleting;
    final complete = task.isCompleted;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Checkbox(
            value: complete,
            activeColor: _TargetTaskPageState._primaryRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            onChanged:
                locked ? null : (value) => onToggleCompleted(value ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            color: const Color(0xFF171A23),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            decoration:
                                complete ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      _PriorityBadge(
                        label: task.priorityLabel,
                        color: _priorityColor,
                      ),
                    ],
                  ),
                  if (task.description != null &&
                      task.description!.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      task.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF737786),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      _MetaTag(
                        icon: Icons.sell_outlined,
                        label: task.categoryLabel,
                      ),
                      _MetaTag(
                        icon: Icons.calendar_month_outlined,
                        label: DateFormat('dd/MM/yyyy HH:mm')
                            .format(task.deadline.toLocal()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: DropdownButtonFormField<TaskProgress>(
                          value: task.displayedProgress,
                          isDense: true,
                          decoration: InputDecoration(
                            labelText: 'Progress',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11),
                              borderSide: const BorderSide(
                                color: Color(0xFFE6E8EE),
                              ),
                            ),
                          ),
                          items: TaskProgress.values
                              .map(
                                (status) => DropdownMenuItem<TaskProgress>(
                                  value: status,
                                  child: Text(
                                    status.label,
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: locked
                              ? null
                              : (status) {
                                  if (status != null &&
                                      status != task.displayedProgress) {
                                    onProgressChanged(status);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isUpdating || isDeleting)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _TargetTaskPageState._primaryRed,
                            ),
                          ),
                        )
                      else ...<Widget>[
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined, size: 21),
                          color: const Color(0xFF777C89),
                          onPressed: onEdit,
                        ),
                        IconButton(
                          tooltip: 'Hapus',
                          icon: const Icon(Icons.delete_outline, size: 22),
                          color: _TargetTaskPageState._primaryRed,
                          onPressed: onDelete,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: const Color(0xFF878C9A)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF727688)),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 43),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.assignment_add,
            size: 44,
            color: Color(0xFFE3A1AA),
          ),
          SizedBox(height: 13),
          Text(
            'Belum ada tugas.\nTambahkan target pertamamu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF727688),
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
