import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../services/chat_service.dart';
import '../models/chat/chat_token_model.dart';
import 'package:lockedin_frontend/services/notification_service.dart'; // ✅ add this

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

  Future<void> connectUser() async {
    if (_status == ChatStatus.loading) return;
    _setStatus(ChatStatus.loading);

    try {
      final ChatTokenModel tokenData = await _chatService.fetchChatToken();
      final currentStreamUserId = streamClient.state.currentUser?.id;

      if (currentStreamUserId != null &&
          currentStreamUserId != tokenData.userId) {
        await streamClient.disconnectUser();
      }

      if (streamClient.state.currentUser?.id == tokenData.userId) {
        _setStatus(ChatStatus.connected);
        return;
      }

      await streamClient.connectUser(
        User(
          id: tokenData.userId,
          name: tokenData.userName,
          image: tokenData.userImage,
        ),
        tokenData.token,
      );

      // ✅ Register FCM token with Stream after connecting
      await NotificationService.registerWithStream(streamClient);

      _setStatus(ChatStatus.connected);
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(ChatStatus.error);
    }
  }

  String? get currentUserId => streamClient.state.currentUser?.id;

  Future<Channel> openPrivateChannel(String targetUserId) async {
    final result = await _chatService.createPrivateChannel(targetUserId);
    final channel = streamClient.channel('messaging', id: result.channelId);
    await channel.watch();
    return channel;
  }

  Future<void> disconnectUser() async {
    if (streamClient.state.currentUser != null) {
      // ✅ Remove FCM token from Stream before disconnecting
      await NotificationService.removeFromStream(streamClient);
      await streamClient.disconnectUser();
    }
    _errorMessage = null;
    _setStatus(ChatStatus.idle);
  }

  void _setStatus(ChatStatus status) {
    _status = status;
    notifyListeners();
  }
}