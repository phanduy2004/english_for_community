// core/entity/leaderboard_entity.dart

class LeaderboardUserEntity {
  final String id;
  final String name;
  final String avatarUrl;
  final String xp; // Backend trả về chuỗi "100 XP"
  final int rank;
  final bool isMe;
  final bool isSeparator; // Dùng để hiển thị dấu "..."

  const LeaderboardUserEntity({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.xp,
    required this.rank,
    required this.isMe,
    this.isSeparator = false,
  });

  factory LeaderboardUserEntity.fromJson(Map<String, dynamic> json) {
    return LeaderboardUserEntity(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      avatarUrl: json['avatarUrl'] ?? '',
      xp: json['xp'] ?? '0 XP',
      rank: json['rank'] ?? 0,
      isMe: json['isMe'] ?? false,
      isSeparator: json['isSeparator'] ?? false,
    );
  }
}

// Class bao bọc toàn bộ response để lấy cả myRank
class LeaderboardResultEntity {
  final List<LeaderboardUserEntity> leaderboard;
  final int myRank;
  final int totalUsers;

  const LeaderboardResultEntity({
    required this.leaderboard,
    required this.myRank,
    required this.totalUsers,
  });

  factory LeaderboardResultEntity.fromJson(Map<String, dynamic> json) {
    return LeaderboardResultEntity(
      leaderboard: (json['leaderboard'] as List)
          .map((e) => LeaderboardUserEntity.fromJson(e))
          .toList(),
      myRank: json['myRank'] ?? 0,
      totalUsers: json['totalUsers'] ?? 0,
    );
  }
}