import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/provider/book_provider.dart';
import 'package:lockedin_frontend/provider/streak_provider.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/screens/onboarding/goal_selection_screen.dart';
import 'package:lockedin_frontend/ui/screens/profile/favorite_books_screen.dart';

/// Opens a full-screen settings panel that slides in from the right,
/// overlaying the bottom nav bar.
void showProfileSettingsDrawer(BuildContext context) {
  final auth = context.read<AuthProvider>();
  final bookProvider = context.read<BookProvider>();
  final streak = context.read<StreakProvider>();

  showGeneralDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Settings',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: bookProvider),
        ChangeNotifierProvider.value(value: streak),
      ],
      child: const _ProfileSettingsPanel(),
    ),
    transitionBuilder: (_, animation, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}

class _ProfileSettingsPanel extends StatelessWidget {
  const _ProfileSettingsPanel();

  Future<bool> _showDeleteVerificationDialog(BuildContext context) async {
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This action is permanent. Your profile, progress, and account data cannot be recovered.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (firstConfirm != true) return false;

    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final confirmation'),
        content: const Text('Are you sure you want to permanently delete your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    return finalConfirm == true;
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final shouldDelete = await _showDeleteVerificationDialog(context);
    if (!shouldDelete || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<AuthProvider>().deleteAccount();
    if (!context.mounted) return;

    if (ok) {
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Account deleted successfully')),
      );
      context.go('/');
      return;
    }

    final message =
        context.read<AuthProvider>().errorMessage ?? 'Failed to delete account';
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: AppColors.background,
        child: SizedBox(
          width: width * 0.78,
          height: double.infinity,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: Responsive.text(context, size: 20),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Nunito',
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.grey,
                          size: width * 0.06,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  const Divider(color: Color(0xFFF0EDE8)),
                  const SizedBox(height: 4),

                  // ── Set Daily Goal ──────────────────────────────────────
                  _SettingTile(
                    icon: Icons.flag_rounded,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.accent,
                    title: 'Set Daily Goal',
                    subtitle: 'Set your study target',
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      Navigator.of(context, rootNavigator: true).push(
                        PageRouteBuilder(
                          pageBuilder: (_, animation, __) =>
                              ChangeNotifierProvider.value(
                                value: context.read<StreakProvider>(),
                                child: const GoalSelectionScreen(),
                              ),
                          transitionsBuilder: (_, animation, __, child) =>
                              SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(0, 1),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                child: child,
                              ),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 4, color: Color(0xFFF0EDE8)),

                  // ── Favorites ───────────────────────────────────────────
                  _SettingTile(
                    icon: Icons.favorite_rounded,
                    iconColor: Colors.red,
                    iconBg: const Color(0xFFFFEEEE),
                    title: 'Favorites',
                    subtitle: 'Your saved books',
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: context.read<BookProvider>(),
                            child: const FavoriteBooksScreen(),
                          ),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 4, color: Color(0xFFF0EDE8)),

                  // ── Log out ─────────────────────────────────────────────
                  _SettingTile(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.red,
                    iconBg: const Color(0xFFFFEEEE),
                    title: 'Log out',
                    titleColor: Colors.red,
                    onTap: () async {
                      Navigator.of(context, rootNavigator: true).pop();
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/');
                    },
                  ),

                  const Divider(height: 4, color: Color(0xFFF0EDE8)),

                  // ── Delete account ─────────────────────────────────────
                  _SettingTile(
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.red,
                    iconBg: const Color(0xFFFFEEEE),
                    title: 'Delete Account',
                    subtitle: 'Permanently remove your account',
                    titleColor: Colors.red,
                    onTap: () => _handleDeleteAccount(context),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single tappable row inside the settings panel.
/// Add new rows here as the settings grow.
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),

              // Title + optional subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: Responsive.text(context, size: 16),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Quicksand',
                        color: titleColor ?? AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: Responsive.text(context, size: 14),
                          fontFamily: 'Quicksand',
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
