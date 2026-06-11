class UserProfileModel {
  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String? description;
  final String? phoneNumber;
  final String? nim;
  final DateTime? birthDate;
  final bool? notifications;
  final bool? shareLeaderboardStats;
  final int? totalXp;
  final int? currentLevel;

  UserProfileModel({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.description,
    this.phoneNumber,
    this.nim,
    this.birthDate,
    this.notifications,
    this.shareLeaderboardStats,
    this.totalXp,
    this.currentLevel,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString(),
      fullName: json['full_name']?.toString(),
      description: json['description']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      nim: json['nim']?.toString(),
      birthDate: DateTime.tryParse(json['birth_date']?.toString() ?? ''),
      notifications: json['notifications'] as bool?,
      shareLeaderboardStats: json['share_leaderboard_stats'] as bool?,
      totalXp: json['total_xp'] is int ? json['total_xp'] : 0,
      currentLevel: json['current_level'] is int ? json['current_level'] : 0,
    );
  }

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;

    final user = username?.trim();
    if (user != null && user.isNotEmpty) return user;

    return 'Mahasiswa';
  }
}
