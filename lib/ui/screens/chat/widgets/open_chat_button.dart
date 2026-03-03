import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../../provider/chat_provider.dart';
import '../channel_screen.dart';

class OpenChatButton extends StatelessWidget {
  final String targetUserId;
  final String label;

  const OpenChatButton({
    super.key,
    required this.targetUserId,
    this.label = 'Message',
  });

  Future<void> _handleTap(BuildContext context) async {
    final chatProvider = context.read<ChatProvider>();

    try {
      final channel = await chatProvider.openPrivateChannel(targetUserId);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StreamChannel(
              channel: channel,
              child: const ChannelScreen(),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleTap(context),
      icon: const Icon(Icons.chat_bubble_outline),
      label: Text(label),
    );
  }
}