import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/streak_provider.dart';

/// Mixin for StatefulWidget states that should track user activity time.
///
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ActivityTracker {
///   // ActivityTracker automatically starts a session on initState
///   // and ends it on dispose.
/// }
/// ```
mixin ActivityTracker<T extends StatefulWidget> on State<T> {
  bool _tracking = false;
  StreakProvider? _streakRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startTracking();
    });
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }

  void startTracking() {
    if (_tracking) return;
    _tracking = true;
    _streakRef = context.read<StreakProvider>();
    _streakRef!.startSession();
    debugPrint('[ActivityTracker] started for ${widget.runtimeType}');
  }

  void stopTracking() {
    if (!_tracking) return;
    _tracking = false;
    _streakRef?.endSession();
    debugPrint('[ActivityTracker] stopped for ${widget.runtimeType}');
    _streakRef = null;
  }
}
