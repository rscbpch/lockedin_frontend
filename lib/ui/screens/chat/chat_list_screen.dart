import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:lockedin_frontend/provider/chat_provider.dart';
import 'channel_screen.dart';
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

    debugPrint('📋 Connected: ${chatProvider.isConnected}');

    if (mounted && chatProvider.isConnected) {
      debugPrint('🔧 Creating mock channels...');
      await chatProvider.createMockChannels();
      debugPrint('✅ Mock channels done, building controller...');

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
    // Store channel info for the route or use a different approach
    // For now, we'll keep the existing approach but could be improved
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StreamChat(
          client: StreamChat.of(context).client,
          child: StreamChannel(
            channel: channel,
            child: const ChannelScreen(),
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
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: _buildAppBar(context),
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
      backgroundColor: const Color(0xFFF0F4FF),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: _handleBackNavigation,
      ),
      title: const Text(
        'Chats',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.group_add_outlined,
            color: Colors.black,
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search chats',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildChannelTile(BuildContext context, Channel channel) {
    final isMock = channel.extraData['mock'] == true;
    final name = _getChannelName(channel);

    final String? avatarUrl;
    final bool isOnline;
    if (isMock) {
      avatarUrl = channel.extraData['image'] as String?;
      isOnline = false;
    } else {
      final currentUserId =
          StreamChat.of(context).client.state.currentUser!.id;
      final members = channel.state?.members ?? [];
      final otherMember = members.isEmpty
          ? null
          : members.firstWhere(
              (m) => m.userId != currentUserId,
              orElse: () => members.first,
            );
      avatarUrl = otherMember?.user?.image;
      isOnline = otherMember?.user?.online ?? false;
    }

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
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
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
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMessage.isNotEmpty ? lastMessage : 'No messages yet',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                  color: Colors.blue,
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
    if (channel.extraData['mock'] == true) {
      return channel.extraData['name'] as String? ?? 'Unknown';
    }

    if (channel.name != null && channel.name!.isNotEmpty) {
      return channel.name!;
    }

    final currentUserId =
        StreamChat.of(context).client.state.currentUser?.id;
    final members = channel.state?.members ?? [];
    final otherMember = members.isEmpty
        ? null
        : members.firstWhere(
            (m) => m.userId != currentUserId,
            orElse: () => members.first,
          );
    return otherMember?.user?.name ?? 'Unknown';
  }

  void _showCreateGroupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create Group',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('Group chat coming soon!'),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
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
      backgroundColor: const Color(0xFFF0F4FF),
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
            ElevatedButton(
              onPressed: _initChat,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}