import 'package:flutter/material.dart';
import 'package:lockedin_frontend/provider/pomodoro_timer_provider.dart';
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
  PomodoroTimerProvider? _pomodoroRef;

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
    _pomodoroRef = context.read<PomodoroTimerProvider>();
    _streakRef!.startSession();
    debugPrint('[ActivityTracker] started for ${widget.runtimeType}');
  }

  void stopTracking() {
    if (!_tracking) return;
    _tracking = false;

    final keepTrackingForPomodoroFocus = _pomodoroRef?.isRunning == true && _pomodoroRef?.mode == TimerMode.pomodoro;
    if (!keepTrackingForPomodoroFocus) {
      _streakRef?.endSession();
      debugPrint('[ActivityTracker] stopped for ${widget.runtimeType}');
    } else {
      debugPrint('[ActivityTracker] skip stop for ${widget.runtimeType} (pomodoro focus still running)');
    }

    _pomodoroRef = null;
    _streakRef = null;
  }
}
