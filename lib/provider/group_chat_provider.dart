import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../models/chat/group_model.dart';
import '../services/group_chat_service.dart';

enum GroupStatus { idle, loading, success, error }

class GroupChatProvider extends ChangeNotifier {
  final GroupChatService _service;
  final StreamChatClient streamClient;

  GroupStatus _status = GroupStatus.idle;
  String? _errorMessage;
  List<GroupModel> _groups = [];

  GroupChatProvider({
    required this.streamClient,
    required GroupChatService service,
  }) : _service = service;

  GroupStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<GroupModel> get groups => _groups;

  /// Fetch all groups the user belongs to
  Future<void> fetchGroups() async {
    _setStatus(GroupStatus.loading);
    try {
      _groups = await _service.getUserGroups();
      _setStatus(GroupStatus.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(GroupStatus.error);
    }
  }

  /// Create a new group and return the Stream channel
  /// Backend handles: user upsert + Stream channel creation + adding members
  /// Flutter just watches the already-created channel
  Future<Channel?> createGroup({
    required String name,
    required List<String> memberIds,
  }) async {
    _setStatus(GroupStatus.loading);
    try {
      final result = await _service.createGroup(
        name: name,
        memberIds: memberIds,
      );

      // ✅ Backend already created the channel with all members
      // Just watch it — do NOT call updateUsers or addMembers from client
      final channel = streamClient.channel(
        'messaging',
        id: result['channelId'],
      );
      await channel.watch();

      await fetchGroups();
      _setStatus(GroupStatus.success);
      return channel;
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(GroupStatus.error);
      return null;
    }
  }

  /// Open an existing group channel
  Future<Channel> openGroupChannel(String channelId) async {
    final channel = streamClient.channel('messaging', id: channelId);
    await channel.watch();
    return channel;
  }

  /// Get full group details including members
  Future<GroupModel?> getGroupDetails(String groupId) async {
    try {
      debugPrint('🔍 Fetching group details for: $groupId');
      final result = await _service.getGroupDetails(groupId);
      debugPrint(
        '✅ Group details: ${result.name}, members: ${result.members.length}',
      );
      return result;
    } catch (e) {
      debugPrint('❌ getGroupDetails error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Add members to a group
  Future<bool> addMembers({
    required String groupId,
    required List<String> userIds,
  }) async {
    try {
      await _service.addMembers(groupId: groupId, userIds: userIds);
      await fetchGroups();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove members from a group
  Future<bool> removeMembers({
    required String groupId,
    required List<String> userIds,
  }) async {
    debugPrint('🗑️ removeMembers: groupId=$groupId, userIds=$userIds');
    try {
      await _service.removeMembers(groupId: groupId, userIds: userIds);
      debugPrint('✅ removeMembers success');
      await fetchGroups();
      return true;
    } catch (e) {
      debugPrint('❌ removeMembers error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Rename a group
  Future<bool> renameGroup({
    required String groupId,
    required String name,
  }) async {
    debugPrint('✏️ renameGroup: groupId=$groupId, name=$name');
    try {
      await _service.renameGroup(groupId: groupId, name: name);
      debugPrint('✅ renameGroup success');
      await fetchGroups();
      return true;
    } catch (e) {
      debugPrint('❌ renameGroup error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Transfer group ownership to another member
  Future<bool> transferOwnership({
    required String groupId,
    required String newOwnerId,
  }) async {
    debugPrint(
      '🔄 transferOwnership: groupId=$groupId, newOwnerId=$newOwnerId',
    );
    try {
      await _service.transferOwnership(
        groupId: groupId,
        newOwnerId: newOwnerId,
      );
      debugPrint('✅ transferOwnership success');
      await fetchGroups();
      return true;
    } catch (e) {
      debugPrint('❌ transferOwnership error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Leave a group
  Future<bool> leaveGroup(String groupId) async {
    debugPrint('🚪 leaveGroup: groupId=$groupId');
    try {
      await _service.leaveGroup(groupId);
      debugPrint('✅ leaveGroup success');
      _groups.removeWhere((g) => g.groupId == groupId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ leaveGroup error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a group (owner only)
  Future<bool> deleteGroup(String groupId) async {
    debugPrint('💣 deleteGroup: groupId=$groupId');
    try {
      await _service.deleteGroup(groupId);
      debugPrint('✅ deleteGroup success');
      _groups.removeWhere((g) => g.groupId == groupId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ deleteGroup error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _setStatus(GroupStatus status) {
    _status = status;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _groups = [];
    _errorMessage = null;
    _status = GroupStatus.idle;
    notifyListeners();
  }
}

// import 'package:flutter/material.dart';
// import 'package:stream_chat_flutter/stream_chat_flutter.dart';
// import '../models/chat/group_model.dart';
// import '../services/group_chat_service.dart';

// enum GroupStatus { idle, loading, success, error }

// class GroupChatProvider extends ChangeNotifier {
//   final GroupChatService _service;
//   final StreamChatClient streamClient;

//   GroupStatus _status = GroupStatus.idle;
//   String? _errorMessage;
//   List<GroupModel> _groups = [];

//   GroupChatProvider({
//     required this.streamClient,
//     required GroupChatService service,
//   }) : _service = service;

//   GroupStatus get status => _status;
//   String? get errorMessage => _errorMessage;
//   List<GroupModel> get groups => _groups;

//   /// Fetch all groups the user belongs to
//   Future<void> fetchGroups() async {
//     _setStatus(GroupStatus.loading);
//     try {
//       _groups = await _service.getUserGroups();
//       _setStatus(GroupStatus.success);
//     } catch (e) {
//       _errorMessage = e.toString();
//       _setStatus(GroupStatus.error);
//     }
//   }

//   /// Create a new group and return the Stream channel
//   /// Backend handles: user upsert + Stream channel creation + adding members
//   /// Flutter just watches the already-created channel
//   Future<Channel?> createGroup({
//     required String name,
//     required List<String> memberIds,
//   }) async {
//     _setStatus(GroupStatus.loading);
//     try {
//       final result = await _service.createGroup(
//         name: name,
//         memberIds: memberIds,
//       );

//       // ✅ Backend already created the channel with all members
//       // Just watch it — do NOT call updateUsers or addMembers from client
//       final channel = streamClient.channel(
//         'messaging',
//         id: result['channelId'],
//       );
//       await channel.watch();

//       await fetchGroups();
//       _setStatus(GroupStatus.success);
//       return channel;
//     } catch (e) {
//       _errorMessage = e.toString();
//       _setStatus(GroupStatus.error);
//       return null;
//     }
//   }

//   /// Open an existing group channel
//   Future<Channel> openGroupChannel(String channelId) async {
//     final channel = streamClient.channel('messaging', id: channelId);
//     await channel.watch();
//     return channel;
//   }

//   /// Get full group details including members
//   Future<GroupModel?> getGroupDetails(String groupId) async {
//   try {
//     debugPrint('🔍 Fetching group details for: $groupId');
//     final result = await _service.getGroupDetails(groupId);
//     debugPrint('✅ Group details: ${result.name}, members: ${result.members.length}');
//     return result;
//   } catch (e) {
//     debugPrint('❌ getGroupDetails error: $e');
//     _errorMessage = e.toString();
//     notifyListeners();
//     return null;
//   }
// }

//   /// Add members to a group
//   Future<bool> addMembers({
//     required String groupId,
//     required List<String> userIds,
//   }) async {
//     try {
//       await _service.addMembers(groupId: groupId, userIds: userIds);
//       await fetchGroups();
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Remove members from a group
//   Future<bool> removeMembers({
//     required String groupId,
//     required List<String> userIds,
//   }) async {
//     try {
//       await _service.removeMembers(groupId: groupId, userIds: userIds);
//       await fetchGroups();
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Rename a group
//   Future<bool> renameGroup({
//     required String groupId,
//     required String name,
//   }) async {
//     try {
//       await _service.renameGroup(groupId: groupId, name: name);
//       await fetchGroups();
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Leave a group
//   Future<bool> leaveGroup(String groupId) async {
//     try {
//       await _service.leaveGroup(groupId);
//       _groups.removeWhere((g) => g.groupId == groupId);
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   /// Delete a group (owner only)
//   Future<bool> deleteGroup(String groupId) async {
//     try {
//       await _service.deleteGroup(groupId);
//       _groups.removeWhere((g) => g.groupId == groupId);
//       notifyListeners();
//       return true;
//     } catch (e) {
//       _errorMessage = e.toString();
//       notifyListeners();
//       return false;
//     }
//   }

//   void _setStatus(GroupStatus status) {
//     _status = status;
//     notifyListeners();
//   }

//   void clearError() {
//     _errorMessage = null;
//     notifyListeners();
//   }
// }
