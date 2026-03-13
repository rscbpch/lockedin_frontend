import 'package:lockedin_frontend/models/user/streak.dart';

// class User {
//   final String id;
//   final String name;
//   final String username;
//   final String bio;
//   final String email;
//   final String profileImg;
//   final String _password;

//   User({
//     required this.id,
//     required this.name,
//     required this.username,
//     required this.bio,
//     required this.email,
//     required this.profileImg,
//     required String password,
//   })  : _password = password;

//   String get password => _password;
// }

class User {
  final String? id; // add
  final String username;
  final String bio;
  final String displayName;
  final String avatar;
  final String authProvider;
  final int follower;
  final int following;
  final int postNumber;
  final Streak? streak;
  final bool isFollowing; // add

  User({
    this.id,
    required this.username,
    required this.bio,
    required this.displayName,
    required this.avatar,
    required this.authProvider,
    this.follower = 0,
    this.following = 0,
    this.postNumber = 0,
    this.streak,
    this.isFollowing = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both flat shape (/setting/me) and nested shape (/users/:username)
    final stats = json['stats'] as Map<String, dynamic>?;

    return User(
      id: json['_id'] as String? ?? json['id'] as String?,
      username: json['username'] ?? '',
      bio: json['bio'] ?? '',
      displayName: json['displayName'] ?? '',
      avatar: json['avatar'] ?? '',
      authProvider: json['authProvider'] ?? '',
      follower:
          (stats?['followers'] as int?) ??
          (json['followersCount'] as int?) ??
          0,
      following:
          (stats?['following'] as int?) ??
          (json['followingCount'] as int?) ??
          0,
      postNumber: json['postNumber'] ?? 0,
      streak: json['streak'] != null ? Streak.fromJson(json['streak']) : null,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? bio,
    String? displayName,
    String? avatar,
    String? authProvider,
    int? follower,
    int? following,
    int? postNumber,
    Streak? streak,
    bool? isFollowing,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      authProvider: authProvider ?? this.authProvider,
      follower: follower ?? this.follower,
      following: following ?? this.following,
      postNumber: postNumber ?? this.postNumber,
      streak: streak ?? this.streak,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
