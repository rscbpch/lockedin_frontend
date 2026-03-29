import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/widgets/display/navbar.dart';

/// Persistent shell that wraps all main tabs with a [Navbar].
class MainShell extends StatelessWidget {
  final GoRouterState state;
  final Widget child;

  const MainShell({super.key, required this.state, required this.child});

  static const _tabs = ['/productivity-hub', '/study-room', '/books', '/profile'];

  int _indexFromPath(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0; // default to productivity-hub
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _indexFromPath(state.matchedLocation);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Navbar(currentIndex: currentIndex, onTap: (index) => context.go(_tabs[index])),
    );
  }
}
