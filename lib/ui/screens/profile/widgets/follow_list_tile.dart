import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/user/follow_user_model.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class FollowListTile extends StatelessWidget {
  final FollowUser user;

  const FollowListTile({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final name = user.displayName.isNotEmpty ? user.displayName : user.username;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
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
      title: Text(
        name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Quicksand',
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '@${user.username}',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.grey,
          fontFamily: 'Quicksand',
        ),
      ),
      trailing: user.isMutual
          ? Container(
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
            )
          : null,
    );
  }
}
