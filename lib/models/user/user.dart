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
  final String username;
  final String bio;
  final String displayName;
  final String avatar;
  final String authProvider;
  final int follower;
  final int following;
  final int postNumber;

  User({
    required this.username,
    required this.bio,
    required this.displayName,
    required this.avatar,
    required this.authProvider,
    this.follower = 0,
    this.following = 0,
    this.postNumber = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      bio: json['bio'] ?? '',
      displayName: json['displayName'] ?? '',
      avatar: json['avatar'] ?? '',
      authProvider: json['authProvider'] ?? '',
      follower: json['followersCount'] ?? 0,
      following: json['followingCount'] ?? 0,
      postNumber: json['postNumber'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'bio': bio,
      'displayName': displayName,
      'avatar': avatar,
      'authProvider': authProvider,
      'follower': follower,
      'following': following,
      'postNumber': postNumber,
    };
  }

  User copyWith({
    String? username,
    String? bio,
    String? displayName,
    String? avatar,
    String? authProvider,
    int? follower,
    int? following,
    int? postNumber,
  }) {
    return User(
      username: username ?? this.username,
      bio: bio ?? this.bio,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      authProvider: authProvider ?? this.authProvider,
      follower: follower ?? this.follower,
      following: following ?? this.following,
      postNumber: postNumber ?? this.postNumber,
    );
  }
}
