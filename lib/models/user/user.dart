class User {
  final String id;
  final String name;
  final String username;
  final String bio;
  final String email;
  final String profileImg;
  final String _password;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.bio,
    required this.email,
    required this.profileImg,
    required String password,
  })  : _password = password;

  String get password => _password;
}
