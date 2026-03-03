import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../services/chat_service.dart';
import '../models/chat/chat_token_model.dart';

enum ChatStatus { idle, loading, connected, error }

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;
  final StreamChatClient streamClient;

  ChatStatus _status = ChatStatus.idle;
  String? _errorMessage;

  ChatProvider({required this.streamClient, required ChatService chatService})
    : _chatService = chatService;

  ChatStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == ChatStatus.connected;

  /// Call once after the user logs in
  Future<void> connectUser() async {
    if (_status == ChatStatus.connected) return;
    _setStatus(ChatStatus.loading);

    try {
      final ChatTokenModel tokenData = await _chatService.fetchChatToken();

      await streamClient.connectUser(
        User(
          id: tokenData.userId,
          name: tokenData.userName,
          image: tokenData.userImage,
        ),
        tokenData.token,
      );

      _setStatus(ChatStatus.connected);
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(ChatStatus.error);
    }
  }

  /// Creates mock channels for testing purposes only
  /// Remove this when backend follow feature is implemented
  Future<void> createMockChannels() async {
  if (!isConnected) return;

  final currentUserId = streamClient.state.currentUser!.id;

  final mockUsers = [
    {'id': 'mock_user_1', 'name': 'Oun Mav',  'image': 'https://i.pravatar.cc/150?img=1'},
    {'id': 'mock_user_2', 'name': 'userbjkd', 'image': 'https://i.pravatar.cc/150?img=2'},
    {'id': 'mock_user_3', 'name': 'Plooch',   'image': 'https://i.pravatar.cc/150?img=3'},
    {'id': 'mock_user_4', 'name': 'riku',     'image': 'https://i.pravatar.cc/150?img=4'},
    {'id': 'mock_user_5', 'name': 'Zrong',    'image': 'https://i.pravatar.cc/150?img=5'},
  ];

  for (final mockUser in mockUsers) {
    try {
      final mockUserId = mockUser['id']!;
      final ids = [currentUserId, mockUserId]..sort();
      final channelId = 'mock-${ids[0]}-${ids[1]}';

      // ✅ Store mock user info in channel extraData instead of as real members
      final channel = streamClient.channel(
        'messaging',
        id: channelId,
        extraData: {
          'name': mockUser['name'],
          'image': mockUser['image'],
          'mock': true,
        },
      );

      await channel.watch();

      if (channel.state?.messages.isEmpty ?? true) {
        await channel.sendMessage(
          Message(text: 'Hey! 👋 This is ${mockUser['name']}'),
        );
      }

      debugPrint('✅ Mock channel ready: $channelId');
    } catch (e) {
      debugPrint('❌ Error: $e');
    }
  }
}
  /// Creates or retrieves the private channel, returns it ready to use
  Future<Channel> openPrivateChannel(String targetUserId) async {
    final result = await _chatService.createPrivateChannel(targetUserId);

    final channel = streamClient.channel('messaging', id: result.channelId);

    await channel.watch();
    return channel;
  }

  /// Call on logout
  Future<void> disconnectUser() async {
    await streamClient.disconnectUser();
    _setStatus(ChatStatus.idle);
  }

  void _setStatus(ChatStatus status) {
    _status = status;
    notifyListeners();
  }
}
