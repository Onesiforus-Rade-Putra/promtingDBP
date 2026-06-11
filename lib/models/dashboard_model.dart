class DashboardModel {
  final UserSummaryModel user;
  final List<StatItemModel> stats;
  final DailyQuestModel dailyQuest;
  final ProgressSectionModel progress;
  final List<FeatureItemModel> features;
  final List<TargetItemModel> activeTargets;
  final List<ActivityItemModel> recentActivities;

  DashboardModel({
    required this.user,
    required this.stats,
    required this.dailyQuest,
    required this.progress,
    required this.features,
    required this.activeTargets,
    required this.recentActivities,
  });
}

class UserSummaryModel {
  final String greeting;
  final String heading;
  final String avatarInitial;

  UserSummaryModel({
    required this.greeting,
    required this.heading,
    required this.avatarInitial,
  });
}

class StatItemModel {
  final String title;
  final String value;
  final String iconKey;

  StatItemModel({
    required this.title,
    required this.value,
    required this.iconKey,
  });
}

class DailyQuestModel {
  final String title;
  final String description;
  final int completedStep;
  final int totalStep;

  DailyQuestModel({
    required this.title,
    required this.description,
    required this.completedStep,
    required this.totalStep,
  });
}

class ProgressSectionModel {
  final String title;
  final String subtitle;
  final double progressValue;

  ProgressSectionModel({
    required this.title,
    required this.subtitle,
    required this.progressValue,
  });
}

class FeatureItemModel {
  final String title;
  final String description;
  final String iconKey;
  final String routeKey;

  FeatureItemModel({
    required this.title,
    required this.description,
    required this.iconKey,
    required this.routeKey,
  });
}

class TargetItemModel {
  final String title;
  final String description;
  final String deadline;
  final String priority;

  TargetItemModel({
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
  });
}

class ActivityItemModel {
  final String title;
  final String time;
  final String reward;

  ActivityItemModel({
    required this.title,
    required this.time,
    required this.reward,
  });
}
