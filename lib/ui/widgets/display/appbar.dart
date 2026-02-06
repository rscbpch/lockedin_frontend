import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LockedInAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBellPressed;
  final VoidCallback? onChatPressed;

  const LockedInAppBar({super.key, this.onBellPressed, this.onChatPressed});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return AppBar(
      title: Text(
        'LockedIn',
        style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Nunito', fontSize: Responsive.text(context, size: 24), fontWeight: FontWeight.bold),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(PhosphorIconsBold.bell, size: width * 0.06, color: AppColors.textPrimary),
          onPressed: onBellPressed ?? () {},
        ),
        IconButton(
          icon: Icon(PhosphorIconsBold.chatsCircle, size: width * 0.06, color: AppColors.textPrimary),
          onPressed: onChatPressed ?? () {},
        ),
      ],
      backgroundColor: AppColors.background,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
