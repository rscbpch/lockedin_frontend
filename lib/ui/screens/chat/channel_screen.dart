import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:lockedin_frontend/models/user/search_user_model.dart';
import 'package:lockedin_frontend/ui/screens/profile/user_other_profile_screen.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/utils/activity_tracker.dart';

class ChannelScreen extends StatefulWidget {
  const ChannelScreen({super.key});

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> with ActivityTracker {
  void _handleBackNavigation(BuildContext context) {
    // Use Navigator.pop since the channel was pushed with Navigator.push
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _openUserProfile(String userId, String userName, String? userImage) {
    if (userId.isEmpty || userName.isEmpty) return;
    
    final searchUserResult = SearchUserResult(
      id: userId,
      username: userName,
      displayName: userName,
      bio: '',
      avatar: userImage ?? '',
      isFollowing: false,
      followers: 0,
      following: 0,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserOtherProfileScreen(user: searchUserResult),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channel = StreamChannel.of(context).channel;
    final client = StreamChat.of(context).client;
    final currentUserId = client.state.currentUser!.id;

    final isMock = channel.extraData['mock'] == true;

    // Get other member info
    final members = channel.state?.members ?? [];
    final otherMember = isMock ? null : members.isEmpty ? null : members.firstWhere((m) => m.userId != currentUserId, orElse: () => members.first);

    // Get name and avatar
    final String name;
    final String? avatarUrl;
    final bool isOnline;

    if (isMock) {
      name = channel.extraData['name'] as String? ?? 'Chat';
      avatarUrl = channel.extraData['image'] as String?;
      isOnline = false;
    } else {
      name = otherMember?.user?.name ?? channel.name ?? 'Chat';
      avatarUrl = otherMember?.user?.image;
      isOnline = otherMember?.user?.online ?? false;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => _handleBackNavigation(context),
        ),
        title: GestureDetector(
          onTap: !isMock && otherMember != null && otherMember.user != null && (otherMember.userId?.isNotEmpty ?? false) && (otherMember.user!.name).isNotEmpty
              ? () => _openUserProfile(
                    otherMember.userId ?? '',
                    otherMember.user!.name,
                    otherMember.user!.image,
                  )
              : null,
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.grey,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)) : null,
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
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
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
