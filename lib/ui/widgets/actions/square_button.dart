import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final double iconSize;
  final double borderRadius;

  const SquareButton({super.key, required this.icon, this.onPressed, this.size = 56, this.backgroundColor, this.iconColor, this.iconSize = 28, this.borderRadius = 16});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(borderRadius)),
        child: Icon(icon, color: iconColor ?? AppColors.background, size: iconSize),
      ),
    );
  }
}
