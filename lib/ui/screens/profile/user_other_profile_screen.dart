import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/user/search_user_model.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/services/user_service.dart';
import 'package:lockedin_frontend/ui/screens/profile/widgets/avatar.dart';
import 'package:lockedin_frontend/ui/screens/profile/widgets/stat_row.dart';
import 'package:lockedin_frontend/ui/screens/profile/widgets/streak_badge.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/chat_provider.dart';
import 'package:lockedin_frontend/ui/screens/chat/channel_screen.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class UserOtherProfileScreen extends StatefulWidget {
  final SearchUserResult user;
  const UserOtherProfileScreen({required this.user, super.key});
  @override
  State<UserOtherProfileScreen> createState() => _UserOtherProfileScreenState();
}

class _UserOtherProfileScreenState extends State<UserOtherProfileScreen> {
  bool _isFollowing = false;

  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.user.isFollowing;
  }

  Future<void> _toggleFollow() async {
    setState(() => _isToggling = true);

    final auth = context.read<AuthProvider>();
    final service = UserService(getAuthToken: () async => auth.token);

    try {
      if (_isFollowing) {
        await service.unfollowUser(widget.user.id);
      } else {
        await service.followUser(widget.user.id);
      }
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  // void _openMessage() {
  //   // TODO: wire ChatProvider.openPrivateChannel(widget.user.id)
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('You need to mutually follow each other to message'),
  //       duration: Duration(seconds: 2),
  //     ),
  //   );
  // }

  Future<void> _openMessage() async {
    final chatProvider = context.read<ChatProvider>();

    // Make sure Stream is connected first
    if (!chatProvider.isConnected) {
      await chatProvider.connectUser();
    }

    try {
      final channel = await chatProvider.openPrivateChannel(widget.user.id);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StreamChannel(channel: channel, child: const ChannelScreen()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              floating: true,
              automaticallyImplyLeading: false,
              leading: IconButton(
                onPressed: () => Navigator.pop(context, _isFollowing),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.primary,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    ProfileAvatar(avatarUrl: user.avatar),
                    const SizedBox(height: 6),

                    // Display name
                    Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : user.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // @username
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Quicksand',
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Bio
                    if (user.bio.isNotEmpty)
                      Text(
                        user.bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Quicksand',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    const SizedBox(height: 10),
                    StreakBadge(streakDays: user.streak?.currentStreak),
                    const SizedBox(height: 10),
                    ProfileStatsRow(
                      followers: user.followers,
                      following: user.following,
                    ),
                    const SizedBox(height: 10),

                    // Follow + Message buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isToggling ? null : _toggleFollow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing
                                  ? AppColors.backgroundBox
                                  : AppColors.primary,
                              foregroundColor: _isFollowing
                                  ? AppColors.textPrimary
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: _isFollowing
                                    ? const BorderSide(color: AppColors.grey)
                                    : BorderSide.none,
                              ),
                              elevation: 0,
                            ),
                            child: _isToggling
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Text(
                                    _isFollowing ? 'Following' : 'Follow',
                                    style: const TextStyle(
                                      fontFamily: 'Quicksand',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            // onPressed: _openMessage,
                            onPressed: () => _openMessage(),
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                            ),
                            label: const Text(
                              'Message',
                              style: TextStyle(
                                fontFamily: 'Quicksand',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.grey, thickness: 0.5),
                  ],
                ),
              ),
            ),

            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.grid_on,
                      size: 48,
                      color: AppColors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No posts yet',
                      style: TextStyle(
                        color: AppColors.grey,
                        fontSize: 15,
                        fontFamily: 'Quicksand',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
