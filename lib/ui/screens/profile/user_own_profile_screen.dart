// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/provider/streak_provider.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/screens/profile/widgets/avatar.dart';
import 'package:lockedin_frontend/ui/screens/profile/widgets/follow_list_sheet.dart';
import 'package:lockedin_frontend/ui/screens/profile/widgets/stat_row.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/actions/long_button.dart';
import 'package:lockedin_frontend/ui/widgets/display/profile_settings_sheet.dart';
import 'package:lockedin_frontend/ui/widgets/inputs/update_profile.dart';
import 'package:provider/provider.dart';

class UserOwnProfileScreen extends StatefulWidget {
  const UserOwnProfileScreen({super.key});

  @override
  State<UserOwnProfileScreen> createState() => _UserOwnProfileScreenState();
}

class _UserOwnProfileScreenState extends State<UserOwnProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().fetchMyProfile();
      context.read<StreakProvider>().fetchStreak(forceRefresh: true);
    });
  }

  void _showFollowList({required bool isFollowers}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => FollowListSheet(isFollowers: isFollowers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    final width = MediaQuery.of(context).size.width;

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.backgroundBox, shape: BoxShape.circle),
                  child: const Icon(Icons.person_off_rounded, size: 48, color: AppColors.grey),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Profile unavailable',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Quicksand'),
                ),
                const SizedBox(height: 8),
                Text(
                  auth.errorMessage ?? 'Something went wrong loading your profile.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.grey, height: 1.5, fontFamily: 'Quicksand'),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Quicksand'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.read<AuthProvider>().fetchMyProfile(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Quicksand'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: AppColors.textPrimary,
                    size: width * 0.06
                  ),
                  onPressed: () => showProfileSettingsDrawer(context),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    ProfileAvatar(avatarUrl: user.avatar),
                    const SizedBox(height: 6),

                    // Display name
                    Text(
                      user.displayName.isNotEmpty ? user.displayName : user.username,
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

                    // Streak badge — reads from StreakProvider for live updates
                    _buildStreakBadge(context.watch<StreakProvider>().currentStreak),
                    const SizedBox(height: 16),

                    // Stats row
                    ProfileStatsRow(
                      followers: user.follower,
                      following: user.following,
                      onFollowersTap: () => _showFollowList(isFollowers: true),
                      onFollowingTap: () => _showFollowList(isFollowers: false),
                    ),
                    const SizedBox(height: 16),

                    LongButton(
                      text: 'Edit profile',
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          isDismissible: false,
                          enableDrag: false,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                          builder: (_) => ChangeNotifierProvider.value(
                            // Pass the SAME AuthProvider instance
                            value: context.read<AuthProvider>(),
                            child: UpdateProfilePage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    const SizedBox(height: 10),

                    // Posts divider
                    const Divider(color: AppColors.grey, thickness: 0.5),
                    const SizedBox(height: 16),
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
                    Icon(Icons.grid_on, size: 48, color: AppColors.grey.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    const Text('No posts yet', style: TextStyle(color: AppColors.grey, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBadge(int? streakDays) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFFBF2C0), borderRadius: BorderRadius.circular(30)),
      child: Text(
        '🔥 ${streakDays ?? 0} ${(streakDays ?? 0) == 1 ? 'Day' : 'Days'} streak',
        style: TextStyle(
          fontSize: Responsive.text(context, size: 14),
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary
        ),
      ),
    );
  }
}

class _FullScreenAvatarView extends StatelessWidget {
  final String avatarUrl;

  const _FullScreenAvatarView({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dismiss on tap outside
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox.expand(child: ColoredBox(color: Colors.transparent)),
          ),
          Center(
            child: Hero(
              tag: 'avatar_hero',
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.person, size: 120, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
