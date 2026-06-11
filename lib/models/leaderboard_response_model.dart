import 'user_profile_model.dart';

class LeaderboardResponseModel {
  const LeaderboardResponseModel({
    required this.userRank,
    required this.userTotalXp,
    required this.topGlobal,
  });

  final int userRank;
  final int userTotalXp;
  final List<LeaderboardItemModel> topGlobal;

  factory LeaderboardResponseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['top_global'];

    return LeaderboardResponseModel(
      userRank: (json['user_rank'] as num?)?.toInt() ?? 0,
      userTotalXp: (json['user_total_xp'] as num?)?.toInt() ?? 0,
      topGlobal: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(LeaderboardItemModel.fromJson)
              .toList()
          : <LeaderboardItemModel>[],
    );
  }
}

class LeaderboardItemModel {
  const LeaderboardItemModel({
    required this.rank,
    required this.user,
    required this.xp,
  });

  final int rank;
  final UserProfileModel user;
  final int xp;

  factory LeaderboardItemModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];

    final userJson = rawUser is Map<String, dynamic>
        ? rawUser
        : <String, dynamic>{
            'id': json['user_id']?.toString() ?? '',
            'email': json['email']?.toString() ?? '',
            'username': json['username']?.toString(),
            'full_name':
                json['full_name']?.toString() ?? json['name']?.toString(),
          };

    return LeaderboardItemModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      user: UserProfileModel.fromJson(userJson),
      xp: (json['xp'] as num?)?.toInt() ??
          (json['total_xp'] as num?)?.toInt() ??
          0,
    );
  }
}
