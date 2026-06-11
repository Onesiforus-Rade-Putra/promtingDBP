class UserModel {
  final String id;
  final String email;
  final String role;
  final String phoneNumber;
  final String userName;
  final String nim;
  final String fullName;
  final String description;
  final DateTime? birthDate;
  final int totalXp;
  final DateTime? lastSeenAt;
  final DateTime? lastLoginAt;
  final int currentStreak;
  final int longestStreak;
  final bool notificationOn;
  final bool shareLeaderboardStats;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.userName,
    required this.nim,
    required this.fullName,
    required this.description,
    required this.birthDate,
    required this.totalXp,
    required this.lastSeenAt,
    required this.lastLoginAt,
    required this.currentStreak,
    required this.longestStreak,
    required this.notificationOn,
    required this.shareLeaderboardStats,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      nim: json['nim']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      birthDate: _parseDate(json['birth_date']),
      totalXp: _parseInt(json['total_xp']),
      lastSeenAt: _parseDate(json['last_seen_at']),
      lastLoginAt: _parseDate(json['last_login_at']),
      currentStreak: _parseInt(json['current_streak']),
      longestStreak: _parseInt(json['longest_streak']),
      notificationOn: json['notification_on'] as bool? ?? false,
      shareLeaderboardStats: json['share_leaderboard_stats'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'phone_number': phoneNumber,
      'user_name': userName,
      'nim': nim,
      'full_name': fullName,
      'description': description,
      'birth_date': birthDate?.toIso8601String(),
      'total_xp': totalXp,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'notification_on': notificationOn,
      'share_leaderboard_stats': shareLeaderboardStats,
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
