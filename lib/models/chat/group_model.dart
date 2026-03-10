class GroupMemberModel {
  final String id;
  final String username;
  final String? displayName;
  final String? avatar;

  const GroupMemberModel({
    required this.id,
    required this.username,
    this.displayName,
    this.avatar,
  });

  String get name => displayName ?? username;

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['_id'] as String? ?? json['id'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      avatar: json['avatar'] as String?,
    );
  }
}

class GroupModel {
  final String groupId;
  final String name;
  final String ownerId;
  final String channelId;
  final int memberCount;
  final List<GroupMemberModel> members;
  final DateTime createdAt;

  const GroupModel({
    required this.groupId,
    required this.name,
    required this.ownerId,
    required this.channelId,
    required this.memberCount,
    required this.members,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List<dynamic>? ?? [];
    return GroupModel(
      groupId: json['groupId'] as String? ?? json['_id'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      channelId: json['channelId'] as String? ?? 'group-${json['groupId'] ?? json['_id']}',
      memberCount: json['memberCount'] as int? ?? membersJson.length,
      members: membersJson
          .map((m) => GroupMemberModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}