import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  final String avatarUrl;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 50,
  });

  void _viewFullScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _FullScreenAvatarView(avatarUrl: avatarUrl),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: avatarUrl.isNotEmpty ? () => _viewFullScreen(context) : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFF5E6D8),
        child: avatarUrl.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(),
                ),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Icon(Icons.person, size: radius, color: AppColors.primary);
  }
}

class _FullScreenAvatarView extends StatelessWidget {
  final String avatarUrl;

  const _FullScreenAvatarView({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const SizedBox.expand(
              child: ColoredBox(color: Colors.transparent),
            ),
          ),
          Center(
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  avatarUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
                    size: 120,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}


