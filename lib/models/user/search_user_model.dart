import 'package:lockedin_frontend/models/user/streak.dart';

class SearchUserResult {
  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String avatar;
  final bool isFollowing;
  final int followers;
  final int following;
  final Streak? streak;

  const SearchUserResult({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.avatar,
    required this.isFollowing,
    required this.followers,
    required this.following,
    this.streak,
  });

  factory SearchUserResult.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>?;
    return SearchUserResult(
      id: json['_id'] as String? ?? json['id']?.toString() ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      isFollowing: json['isFollowing'] as bool? ?? false,
      followers: (stats?['followers'] as int?) ?? 0,
      following: (stats?['following'] as int?) ?? 0,
      streak: json['streak'] != null
          ? Streak.fromJson(json['streak'] as Map<String, dynamic>)
          : null,
    );
  }

  SearchUserResult copyWith({bool? isFollowing}) {
    return SearchUserResult(
      id: id,
      username: username,
      displayName: displayName,
      bio: bio,
      avatar: avatar,
      isFollowing: isFollowing ?? this.isFollowing,
      followers: followers,
      following: following,
      streak: streak,
    );
  }
}
