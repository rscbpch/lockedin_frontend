import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class Navbar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const Navbar({super.key, required this.currentIndex, required this.onTap});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
      color: AppColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(FeatherIcons.home, 0),
          _navItem(FeatherIcons.users, 1),
          _navItem(FeatherIcons.layers, 2),
          _navItem(FeatherIcons.bookOpen, 3),
          _navItem(FeatherIcons.user, 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final isActive = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textPrimary,
              size: 25,
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isActive ? 24 : 0, 
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}