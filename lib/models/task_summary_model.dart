class TaskSummaryModel {
  const TaskSummaryModel({
    required this.taskCompleted,
    required this.todo,
    required this.onProgress,
    required this.highPriority,
  });

  final int taskCompleted;
  final int todo;
  final int onProgress;
  final int highPriority;

  factory TaskSummaryModel.fromJson(Map<String, dynamic> json) {
    return TaskSummaryModel(
      taskCompleted: (json['task_completed'] as num?)?.toInt() ?? 0,
      todo: (json['todo'] as num?)?.toInt() ?? 0,
      onProgress: (json['on_progress'] as num?)?.toInt() ?? 0,
      highPriority: (json['high_priority'] as num?)?.toInt() ?? 0,
    );
  }

  int get totalTasks => taskCompleted + todo + onProgress;

  double get completionRatio {
    if (totalTasks == 0) {
      return 0;
    }

    return taskCompleted / totalTasks;
  }
}
