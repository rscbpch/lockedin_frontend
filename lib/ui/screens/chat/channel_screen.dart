import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:go_router/go_router.dart';
class ChannelScreen extends StatelessWidget {
  const ChannelScreen({super.key});

  void _handleBackNavigation(BuildContext context) {
    // Use Navigator.pop since the channel was pushed with Navigator.push
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final channel = StreamChannel.of(context).channel;
    final client = StreamChat.of(context).client;
    final currentUserId = client.state.currentUser!.id;

    final isMock = channel.extraData['mock'] == true;

    // Get name and avatar
    final String name;
    final String? avatarUrl;
    final bool isOnline;

    if (isMock) {
      name = channel.extraData['name'] as String? ?? 'Chat';
      avatarUrl = channel.extraData['image'] as String?;
      isOnline = false;
    } else {
      final members = channel.state?.members ?? [];
      final otherMember = members.isEmpty
          ? null
          : members.firstWhere(
              (m) => m.userId != currentUserId,
              orElse: () => members.first,
            );
      name = otherMember?.user?.name ?? channel.name ?? 'Chat';
      avatarUrl = otherMember?.user?.image;
      isOnline = otherMember?.user?.online ?? false;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4FF),
        elevation: 0,
        // ✅ Safe navigation back with proper checks
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => _handleBackNavigation(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Text(
              name,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: const Column(
        children: [
          Expanded(child: StreamMessageListView()),
          StreamMessageInput(),
        ],
      ),
    );
  }
}