class ChatTokenModel {
  final String token;
  final String userId;
  final String userName;
  final String? userImage;

  const ChatTokenModel({
    required this.token,
    required this.userId,
    required this.userName,
    this.userImage,
  });

  factory ChatTokenModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return ChatTokenModel(
      token: json['token'] as String,
      userId: user['id'] as String,
      userName: user['name'] as String,
      userImage: user['image'] as String?,
    );
  }
}