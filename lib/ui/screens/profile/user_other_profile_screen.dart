import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/user/search_user_model.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/services/user_service.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/screens/profile/widgets/avatar.dart';
import 'package:lockedin_frontend/ui/screens/profile/widgets/stat_row.dart';
import 'package:lockedin_frontend/ui/screens/profile/widgets/streak_badge.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/display/simple_back_sliver_app_bar.dart';
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
            SimpleBackSliverAppBar(title: ''),
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
                      style: TextStyle(
                        fontSize: Responsive.text(context, size: 18),
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary
                      ),
                    ),
                    const SizedBox(height: 4),

                    // @username
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        fontSize: Responsive.text(context, size: 14),
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Bio
                    if (user.bio.isNotEmpty)
                      Text(
                        user.bio,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: Responsive.text(context, size: 14),
                          fontFamily: 'Quicksand',
                          color: AppColors.textPrimary
                        ),
                      ),
                    const SizedBox(height: 12),

                    StreakBadge(streakDays: user.streak?.currentStreak),

                    const SizedBox(height: 16),
                    
                    ProfileStatsRow(
                      followers: user.followers,
                      following: user.following,
                    ),
                    const SizedBox(height: 10),

                    // Follow + Message buttons
                    Row(
                      children: [
                        Expanded(
                          child: LongButton(
                            text: _isFollowing ? 'Following' : 'Follow',
                            onPressed: _isToggling ? null : _toggleFollow,
                            isOutlined: _isFollowing,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LongButton(
                            text: 'Message',
                            isOutlined: true,
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                            ),
                            onPressed: _openMessage,
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
