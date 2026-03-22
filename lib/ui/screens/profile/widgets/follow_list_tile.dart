import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/models/user/follow_user_model.dart';
import 'package:lockedin_frontend/models/user/search_user_model.dart';
import 'package:lockedin_frontend/provider/follow_provider.dart';
import 'package:lockedin_frontend/ui/screens/profile/user_other_profile_screen.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class FollowListTile extends StatelessWidget {
  final FollowUser user;

  const FollowListTile({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final name = user.displayName.isNotEmpty ? user.displayName : user.username;
    final provider = context.watch<FollowProvider>();
    final isFollowing = provider.isFollowing(user.id);
    final isPending = provider.isPending(user.id);
    final isMutual = isFollowing && user.isMutual;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: GestureDetector(
        onTap: () => _openUserProfile(context, provider, isFollowing),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFF5E6D8),
          backgroundImage: user.avatar.isNotEmpty
              ? NetworkImage(user.avatar)
              : null,
          child: user.avatar.isEmpty
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Quicksand',
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
      ),
      title: GestureDetector(
        onTap: () => _openUserProfile(context, provider, isFollowing),
        child: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Quicksand',
            color: AppColors.textPrimary,
          ),
        ),
      ),
      subtitle: GestureDetector(
        onTap: () => _openUserProfile(context, provider, isFollowing),
        child: Text(
          '@${user.username}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey,
            fontFamily: 'Quicksand',
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mutual badge
          if (isMutual) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Mutual',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontFamily: 'Quicksand',
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Follow / Unfollow button
          isPending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : GestureDetector(
                  onTap: () => _handleFollowTap(context, provider, isFollowing),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isFollowing
                          ? Colors.transparent
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      border: isFollowing
                          ? Border.all(color: AppColors.grey)
                          : null,
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Quicksand',
                        color: isFollowing
                            ? AppColors.textPrimary
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _openUserProfile(
    BuildContext context,
    FollowProvider provider,
    bool isFollowing,
  ) async {
    final mappedUser = SearchUserResult(
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      bio: '',
      avatar: user.avatar,
      isFollowing: isFollowing,
      followers: 0,
      following: 0,
      streak: null,
    );

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => UserOtherProfileScreen(user: mappedUser),
      ),
    );

    if (context.mounted) {
      await provider.fetchAll();
    }
  }

  Future<void> _handleFollowTap(
    BuildContext context,
    FollowProvider provider,
    bool isFollowing,
  ) async {
    if (isFollowing) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unfollow?'),
          content: Text(
            'Stop following ${user.displayName.isNotEmpty ? user.displayName : user.username}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Unfollow',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await provider.unfollowUser(user.id);
      }
    } else {
      final success = await provider.followUser(user.id);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to follow'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
