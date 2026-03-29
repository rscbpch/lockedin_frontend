import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/user/search_user_model.dart';
import 'package:lockedin_frontend/provider/user_search_provider.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/screens/profile/user_other_profile_screen.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:provider/provider.dart';

class UserSearchTile extends StatelessWidget {
  final SearchUserResult user;

  const UserSearchTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.displayName.isNotEmpty ? user.displayName : user.username;

    return InkWell(
      onTap: () async {
        final newFollowState = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => UserOtherProfileScreen(user: user)),
        );
        if (newFollowState != null && context.mounted) {
          context.read<UserSearchProvider>().updateFollowState(
            user.id,
            newFollowState,
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFF5E6D8),
              backgroundImage: user.avatar.isNotEmpty
                  ? NetworkImage(user.avatar)
                  : null,
              child: user.avatar.isEmpty
                  ? Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: Responsive.text(context, size: 16),
                          color: AppColors.textPrimary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      if (user.isFollowing) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Following',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontFamily: 'Quicksand',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.bio,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontFamily: 'Quicksand',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
