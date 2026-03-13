import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class ProfileStatsRow extends StatelessWidget {
  final int followers;
  final int following;
  final int? postNumber;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const ProfileStatsRow({
    super.key,
    required this.followers,
    required this.following,
    this.postNumber = 0,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      if (postNumber != null) _StatItem(count: '$postNumber', label: 'Posts'),
      _StatItem(count: '$followers', label: 'Followers', onTap: onFollowersTap),
      _StatItem(count: '$following', label: 'Following', onTap: onFollowingTap),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(stats.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Container(
            width: 1,
            height: 30,
            color: AppColors.grey.withOpacity(0.4),
          );
        }
        return Expanded(child: stats[index ~/ 2]);
      }),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({required this.count, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final labelWidget = Text(
      label,
      style: TextStyle(
        fontSize: 13,
        color: onTap != null ? AppColors.primary : AppColors.grey,
        decoration: onTap != null
            ? TextDecoration.underline
            : TextDecoration.none,
        decorationColor: AppColors.primary,
      ),
    );

    final content = Column(
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
        labelWidget,
      ],
    );

    if (onTap == null) return content;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}
