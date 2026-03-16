import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/screens/User/search_user_screen.dart';
import 'package:lockedin_frontend/ui/widgets/actions/square_button.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/search_bar_widget.dart';
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
    _searchController.addListener(_onSearchChanged); // 👈 live search listener
    WidgetsBinding.instance.addPostFrameCallback((_) => _initChat());
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
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
          filter: Filter.in_(
            'members',
            [StreamChat.of(context).currentUser!.id],
          ),
          channelStateSort: const [SortOption('last_message_at')],
        );
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

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
    ).then((_) async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) _controller?.refresh();
    });
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 8),
        child: SquareButton(
          icon: Icons.person_search,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchUserScreen()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamChannelListView(
              controller: _controller!,
              separatorBuilder: (_, __, ___) => const SizedBox.shrink(),
              emptyBuilder: (_) => Center(
                child: Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: Responsive.text(context, size: 16),
                    color: Colors.grey
                  ),
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
        icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 32),
        onPressed: () => context.pop(),
        splashRadius: 20,
      ),
      title: Text(
        'Chats',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: Responsive.text(context, size: 20),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.group_add_outlined, color: AppColors.textPrimary, size: 26),
          onPressed: () => _showCreateGroupSheet(context),
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SearchBarWidget(
        controller: _searchController,
        hintText: 'Search chats',
        onSubmitted: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onClear: () {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
          });
        },
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
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
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