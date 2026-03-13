class FollowUser {
  final String id;
  final String username;
  final String displayName;
  final String avatar;
  final bool isMutual;

  const FollowUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatar,
    required this.isMutual,
  });

  factory FollowUser.fromJson(Map<String, dynamic> json) => FollowUser(
    id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
    username: json['username'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
    avatar: json['avatar'] as String? ?? '',
    isMutual: json['isMutual'] as bool? ?? false,
  );
}
