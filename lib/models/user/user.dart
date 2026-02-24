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

  User({
    required this.username,
    required this.bio,
    required this.displayName,
    required this.avatar,
    required this.authProvider,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      bio: json['bio'] ?? '',
      displayName: json['displayName'] ?? '',
      avatar: json['avatar'] ?? '',
      authProvider: json['authProvider'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'bio': bio,
      'displayName': displayName,
      'avatar': avatar,
      'authProvider': authProvider,
    };
  }
}
