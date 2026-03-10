import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'group_detail_screen.dart';

class GroupChannelScreen extends StatelessWidget {
  const GroupChannelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final channel = StreamChannel.of(context).channel;
    final groupName = channel.extraData['name'] as String? ??
        channel.name ??
        'Group Chat';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: GestureDetector(
          onTap: () => _openGroupDetails(context, channel),
          child: Row(
            children: [
              // Group avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Text(
                  groupName.isNotEmpty ? groupName[0].toUpperCase() : 'G',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${channel.memberCount ?? 0} members',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textPrimary),
            onPressed: () => _openGroupDetails(context, channel),
          ),
        ],
      ),
      body: const Column(
        children: [
          Expanded(child: StreamMessageListView()),
          StreamMessageInput(),
        ],
      ),
    );
  }

  void _openGroupDetails(BuildContext context, Channel channel) {
    // Extract groupId from channelId (format: group-{groupId})
    final channelId = channel.id ?? '';
    final groupId = channelId.startsWith('group-')
        ? channelId.replaceFirst('group-', '')
        : channelId;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDetailsScreen(
          groupId: groupId,
          channel: channel,
        ),
      ),
    );
  }
}