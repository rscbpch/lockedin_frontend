import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/display/navbar.dart';
import 'package:provider/provider.dart';

class UserOwnProfileScreen extends StatefulWidget {
  const UserOwnProfileScreen({super.key});

  @override
  State<UserOwnProfileScreen> createState() => _UserOwnProfileScreenState();
}

class _UserOwnProfileScreenState extends State<UserOwnProfileScreen> {
  int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    // Auto-fetch profile if authenticated but user data is missing
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && auth.currentUser == null) {
      auth.fetchMyProfile();
    }
  }

  void _onTap(int index) {
    if (index == 2) {
      context.go('/productivity-hub');
    } else if (index != 4) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text("No profile loaded")),
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
                  icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                  onPressed: () {},
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
                    _buildAvatar(user.avatar),
                    const SizedBox(height: 14),

                    // Display name
                    Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : user.username,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // @username
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        fontSize: 14,
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
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Streak badge (placeholder — streak data not yet in User model)
                    _buildStreakBadge(0),
                    const SizedBox(height: 20),

                    // Stats row
                    _buildStatsRow(),
                    const SizedBox(height: 20),

                    // Edit Profile button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: navigate to edit profile screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Edit profile',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Posts divider
                    const Divider(color: AppColors.grey, thickness: 0.5),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Posts area (blank) ────────────────────────────────────
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
                      style: TextStyle(color: AppColors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Navbar(currentIndex: _currentIndex, onTap: _onTap),
    );
  }

  Widget _buildAvatar(String avatarUrl) {
    return CircleAvatar(
      radius: 52,
      backgroundColor: const Color(0xFFF5E6D8),
      child: avatarUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                width: 104,
                height: 104,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(),
              ),
            )
          : _avatarFallback(),
    );
  }

  Widget _avatarFallback() {
    return const Icon(Icons.person, size: 52, color: AppColors.primary);
  }

  Widget _buildStreakBadge(int streakDays) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF2C0),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '🔥 $streakDays Days Streak',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
Widget _buildStatsRow() {
  final stats = [
    {'count': '0', 'label': 'Posts'},
    {'count': '0', 'label': 'Followers'},
    {'count': '0', 'label': 'Following'},
  ];

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(stats.length * 2 - 1, (index) {
      if (index.isOdd) {
        // Divider between stats
        return _dividerLine();
      } else {
        final stat = stats[index ~/ 2];
        return Expanded(child: _statItem(stat['count']!, stat['label']!));
      }
    }),
  );
}

  Widget _statItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.grey),
        ),
      ],
    );
  }

  Widget _dividerLine() {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.grey.withOpacity(0.4),
    );
  }
}
