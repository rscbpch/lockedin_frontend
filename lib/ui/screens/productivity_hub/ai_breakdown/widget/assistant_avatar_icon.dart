import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class AssistantAvatarIcon extends StatelessWidget {
  const AssistantAvatarIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.auto_awesome, color: AppColors.backgroundBox, size: 16),
    );
  }
}