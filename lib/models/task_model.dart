enum TaskCategory {
  akademik,
  pribadi,
  organisasi,
}

extension TaskCategoryValue on TaskCategory {
  String get apiValue => name;

  String get label {
    switch (this) {
      case TaskCategory.akademik:
        return 'Akademik';
      case TaskCategory.pribadi:
        return 'Pribadi';
      case TaskCategory.organisasi:
        return 'Organisasi';
    }
  }
}

enum TaskPriority {
  tinggi,
  sedang,
  rendah,
}

extension TaskPriorityValue on TaskPriority {
  String get apiValue => name;

  String get label {
    switch (this) {
      case TaskPriority.tinggi:
        return 'High';
      case TaskPriority.sedang:
        return 'Medium';
      case TaskPriority.rendah:
        return 'Low';
    }
  }
}

/// Nilai sementara berdasarkan dokumentasi yang perlu dikonfirmasi backend.
enum TaskProgress {
  todo,
  onProgress,
  completed,
}

extension TaskProgressValue on TaskProgress {
  String get apiValue {
    switch (this) {
      case TaskProgress.todo:
        return 'todo';
      case TaskProgress.onProgress:
        return 'on_progress';
      case TaskProgress.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case TaskProgress.todo:
        return 'Belum Dikerjakan';
      case TaskProgress.onProgress:
        return 'Sedang Berjalan';
      case TaskProgress.completed:
        return 'Selesai';
    }
  }
}

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.deadline,
    required this.isCompleted,
    this.description,
    this.progress,
  });

  final int id;
  final String title;
  final String category;
  final String priority;
  final DateTime deadline;
  final String? description;
  final bool isCompleted;

  /// Field opsional untuk kompatibilitas jika backend kelak mengirim status rinci.
  /// Dokumentasi saat ini hanya menjamin `is_completed`.
  final String? progress;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final deadlineValue = json['deadline'] as String?;
    final parsedDeadline =
        deadlineValue == null ? null : DateTime.tryParse(deadlineValue);
    if (parsedDeadline == null) {
      throw const FormatException('Format deadline tugas tidak valid.');
    }

    return TaskModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      deadline: parsedDeadline,
      description: json['description'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      progress: json['progress'] as String?,
    );
  }

  TaskProgress get displayedProgress {
    switch (progress) {
      case 'completed':
        return TaskProgress.completed;
      case 'on_progress':
        return TaskProgress.onProgress;
      case 'todo':
        return TaskProgress.todo;
      default:
        return isCompleted ? TaskProgress.completed : TaskProgress.todo;
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'akademik':
        return 'Akademik';
      case 'pribadi':
        return 'Pribadi';
      case 'organisasi':
        return 'Organisasi';
      default:
        return category;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'tinggi':
        return 'High';
      case 'sedang':
        return 'Medium';
      case 'rendah':
        return 'Low';
      default:
        return priority;
    }
  }
}
