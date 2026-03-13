import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lockedin_frontend/ui/screens/User/search_user_screen.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:lockedin_frontend/provider/chat_provider.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'channel_screen.dart';
import 'create_group_screen.dart';
import 'group_channel_screen.dart';
import 'widgets/stream_chat_theme.dart';
import 'package:go_router/go_router.dart';

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  StreamChannelListController? _controller;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initChat());
  }

  Future<void> _initChat() async {
    final chatProvider = context.read<ChatProvider>();

    if (!chatProvider.isConnected) {
      await chatProvider.connectUser();
    }

    if (mounted && chatProvider.isConnected) {
      setState(() {
        _controller = StreamChannelListController(
          client: StreamChat.of(context).client,
          filter: Filter.or([
            Filter.in_('members', [StreamChat.of(context).currentUser!.id]),
            Filter.equal(
              'created_by_id',
              StreamChat.of(context).currentUser!.id,
            ),
          ]),
          channelStateSort: const [SortOption('last_message_at')],
        );
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Navigate to channel using GoRouter
  void _navigateToChannel(Channel channel) {
    final isGroup = channel.id?.startsWith('group-') == true;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StreamChat(
          client: StreamChat.of(context).client,
          streamChatThemeData: StreamChatAppTheme.theme,
          child: StreamChannel(
            channel: channel,
            child: isGroup ? const GroupChannelScreen() : const ChannelScreen(),
          ),
        ),
      ),
    );
  }

  void _handleBackNavigation() {
    // Use GoRouter for consistent navigation
    context.go('/productivity-hub');
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    if (chatProvider.status == ChatStatus.error) {
      return _buildErrorState(chatProvider);
    }

    if (_controller == null || chatProvider.status == ChatStatus.loading) {
      return _buildLoadingState();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        tooltip: 'Find people',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SearchUserScreen()),
          );
        },
        child: const Icon(Icons.person_search, color: Colors.black),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamChannelListView(
              controller: _controller!,
              separatorBuilder: (_, __, ___) => const SizedBox.shrink(),
              emptyBuilder: (_) => const Center(
                child: Text(
                  'No conversations yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              itemBuilder: (context, channels, index, defaultWidget) {
                final channel = channels[index];
                final channelName = _getChannelName(channel);
                if (_searchQuery.isNotEmpty &&
                    !channelName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    )) {
                  return const SizedBox.shrink();
                }
                return _buildChannelTile(context, channel);
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: _handleBackNavigation,
      ),
      title: const Text(
        'Chats',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.group_add_outlined,
            color: AppColors.textPrimary,
            size: 28,
          ),
          onPressed: () => _showCreateGroupSheet(context),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundBox,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 3),
            )
          ]
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search chats',
            hintStyle: const TextStyle(color: AppColors.grey, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: AppColors.grey),
            filled: true,
            fillColor: AppColors.backgroundBox,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelTile(BuildContext context, Channel channel) {
    final name = _getChannelName(channel);

    final currentUserId = StreamChat.of(context).client.state.currentUser!.id;
    final members = channel.state?.members ?? [];
    final otherMember = members.isEmpty
        ? null
        : members.firstWhere(
            (m) => m.userId != currentUserId,
            orElse: () => members.first,
          );
    final String? avatarUrl = otherMember?.user?.image;
    final bool isOnline = otherMember?.user?.online ?? false;

    final lastMessage = channel.state?.messages.isNotEmpty == true
        ? channel.state!.messages.last.text ?? ''
        : '';
    final unreadCount = channel.state?.unreadCount ?? 0;

    return InkWell(
      onTap: () => _navigateToChannel(channel),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.grey,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getChannelName(Channel channel) {
    if (channel.name != null && channel.name!.isNotEmpty) {
      return channel.name!;
    }

    final currentUserId = StreamChat.of(context).client.state.currentUser?.id;
    final members = channel.state?.members ?? [];
    final otherMember = members.isEmpty
        ? null
        : members.firstWhere(
            (m) => m.userId != currentUserId,
            orElse: () => members.first,
          );
    return otherMember?.user?.name ?? 'Unknown';
  }

  /// [DEV ONLY] Dialog to open a direct channel with any user by Stream ID.
  /// Bypasses the backend follow check. Remove when follow feature ships.
  void _showDirectChatDialog(BuildContext context, ChatProvider chatProvider) {
    final myId = chatProvider.currentUserId ?? '(not connected)';
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('[DEV] Direct Chat Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Stream user ID:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: myId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User ID copied!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        myId,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const Icon(Icons.copy, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Other user's Stream ID",
                hintText: 'Paste the other user ID here',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final targetId = controller.text.trim();
              if (targetId.isEmpty || targetId == myId) return;
              Navigator.of(ctx).pop();
              try {
                final channel = await chatProvider.openPrivateChannel(targetId);
                if (context.mounted) _navigateToChannel(channel);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Open Chat'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupSheet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StreamChat(
          client: StreamChat.of(context).client,
          streamChatThemeData: StreamChatAppTheme.theme,
          child: const CreateGroupScreen(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4FF),
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(ChatProvider chatProvider) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4FF),
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(chatProvider.errorMessage ?? 'Failed to connect'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _initChat, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
