import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/pomodoro_service.dart';
import 'streak_provider.dart';

enum TimerMode { pomodoro, shortBreak, longBreak }

class PomodoroCompletionPrompt {
  const PomodoroCompletionPrompt({required this.id, required this.title, required this.message, required this.suggestedMode});

  final int id;
  final String title;
  final String message;
  final TimerMode suggestedMode;
}

class PomodoroTimerProvider extends ChangeNotifier with WidgetsBindingObserver {
  StreakProvider? _streakProvider;

  void setStreakProvider(StreakProvider sp) {
    _streakProvider = sp;
  }

  static const Map<TimerMode, int> _defaultMinutes = {TimerMode.pomodoro: 25, TimerMode.shortBreak: 5, TimerMode.longBreak: 10};

  TimerMode _mode = TimerMode.pomodoro;
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  int _pomodoroCount = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool get isPaused => _isPaused;

  Timer? _ticker;
  DateTime? _targetEndTime;

  bool _pausedByLifecycle = false;
  int _lifecyclePausedRemaining = 0;

  int _nextPromptId = 0;
  int _promptEventId = 0;
  PomodoroCompletionPrompt? _pendingPrompt;

  TimerMode get mode => _mode;
  int get totalSeconds => _totalSeconds;
  int get remainingSeconds => _remainingSeconds;
  int get pomodoroCount => _pomodoroCount;
  bool get isRunning => _isRunning;
  int get promptEventId => _promptEventId;
  PomodoroCompletionPrompt? get pendingPrompt => _pendingPrompt;

  void startTimer() {
    if (_isRunning) return;

    if (_remainingSeconds <= 0) {
      _initializeModeDuration();
    }

    _isRunning = true;
    _targetEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncTick();
    });

    WidgetsBinding.instance.addObserver(this);

    // Start streak tracking when pomodoro focus starts
    if (_mode == TimerMode.pomodoro) {
      _streakProvider?.startSession();
    }

    notifyListeners();
  }

  void pauseTimer() {
    if (!_isRunning) return;
    _ticker?.cancel();
    _ticker = null;
    _targetEndTime = null;
    _isRunning = false;
    _isPaused = true;
    WidgetsBinding.instance.removeObserver(this);

    if (_mode == TimerMode.pomodoro) {
      _streakProvider?.endSession();
    }

    notifyListeners();
  }

  void resumeTimer() {
    if (!_isPaused) return;
    _isPaused = false;
    _isRunning = true;
    _targetEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncTick();
    });

    WidgetsBinding.instance.addObserver(this);

    if (_mode == TimerMode.pomodoro) {
      _streakProvider?.startSession();
    }

    notifyListeners();
  }

  void cancelTimer() {
    _ticker?.cancel();
    _ticker = null;
    _targetEndTime = null;

    final wasActive = _isRunning && _mode == TimerMode.pomodoro;
    _isRunning = false;
    _isPaused = false;
    WidgetsBinding.instance.removeObserver(this);

    if (wasActive) {
      _streakProvider?.endSession();
    }

    _initializeModeDuration();
    notifyListeners();
  }

  void stopTimer() {
    final wasRunningPomodoro = _isRunning && _mode == TimerMode.pomodoro;
    _ticker?.cancel();
    _ticker = null;
    _targetEndTime = null;
    _isRunning = false;
    _isPaused = false;
    WidgetsBinding.instance.removeObserver(this);

    // End streak tracking when pomodoro focus is manually stopped
    if (wasRunningPomodoro) {
      _streakProvider?.endSession();
    }

    notifyListeners();
  }

  void switchMode(TimerMode mode) {
    if (_mode == mode) return;

    final wasRunningPomodoro = _isRunning && _mode == TimerMode.pomodoro;
    _ticker?.cancel();
    _ticker = null;
    _targetEndTime = null;
    _isRunning = false;
    _isPaused = false;
    WidgetsBinding.instance.removeObserver(this);

    if (wasRunningPomodoro) {
      _streakProvider?.endSession();
    }

    _mode = mode;
    _initializeModeDuration();
    notifyListeners();
  }

  void addMinutes(int minutes) {
    if (_isRunning) return;

    final newSeconds = _remainingSeconds + (minutes * 60);
    if (newSeconds <= 0) return;

    _remainingSeconds = newSeconds;
    _totalSeconds = newSeconds;
    notifyListeners();
  }

  void setDurationSeconds(int seconds) {
    if (_isRunning || seconds <= 0) return;

    _remainingSeconds = seconds;
    _totalSeconds = seconds;
    notifyListeners();
  }

  void dismissPendingPrompt() {
    if (_pendingPrompt == null) return;
    _pendingPrompt = null;
    notifyListeners();
  }

  void acceptPendingPromptAndStart() {
    final prompt = _pendingPrompt;
    if (prompt == null) return;

    _pendingPrompt = null;
    _mode = prompt.suggestedMode;
    _initializeModeDuration();
    notifyListeners();
    startTimer();
  }

  void _initializeModeDuration() {
    _totalSeconds = (_defaultMinutes[_mode] ?? 25) * 60;
    _remainingSeconds = _totalSeconds;
  }

  void _syncTick() {
    if (!_isRunning || _targetEndTime == null) return;

    final diff = _targetEndTime!.difference(DateTime.now()).inSeconds;
    _remainingSeconds = max(0, diff);

    if (_remainingSeconds <= 0) {
      _onTimerComplete();
      return;
    }

    notifyListeners();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
  //     // App resumed — restore timer if it was paused by lifecycle
  //     if (_isRunning) {
  //       _pausedByLifecycle = true;
  //       _lifecyclePausedRemaining = _remainingSeconds;
  //       _ticker?.cancel();
  //       _ticker = null;
  //       _targetEndTime = null;
  //       _isRunning = false;
  //       notifyListeners();
  //     }
  //   } else if (state == AppLifecycleState.resumed) {
  //     // App resumed — restore timer if it was paused by lifecycle
  //     if (_pausedByLifecycle) {
  //       _pausedByLifecycle = false;
  //       if (_lifecyclePausedRemaining > 0) {
  //         _remainingSeconds = _lifecyclePausedRemaining;
  //         _isRunning = true;
  //         _targetEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
  //         _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
  //           _syncTick();
  //         });
  //         notifyListeners();
  //       }
  //     }
  //   }
  // }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // App resumed — restore timer if it was paused by lifecycle
      if (_isRunning) {
        _pausedByLifecycle = true;
        _lifecyclePausedRemaining = _remainingSeconds;
        _ticker?.cancel();
        _ticker = null;
        _targetEndTime = null;
        _isRunning = false;
        notifyListeners();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App resumed — restore timer if it was paused by lifecycle
      if (_pausedByLifecycle) {
        _pausedByLifecycle = false;
        if (_lifecyclePausedRemaining > 0 && !_isPaused) {
          _remainingSeconds = _lifecyclePausedRemaining;
          _isRunning = true;
          _targetEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
          _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
            _syncTick();
          });
          notifyListeners();
        }
      }
    }
  }

  Future<void> _onTimerComplete() async {
    _ticker?.cancel();
    _ticker = null;
    _targetEndTime = null;
    _isRunning = false;
    _remainingSeconds = 0;
    WidgetsBinding.instance.removeObserver(this);

    if (_mode == TimerMode.pomodoro) {
      // End streak tracking when pomodoro completes
      _streakProvider?.endSession();
      unawaited(PomodoroService.createSession(durationSeconds: _totalSeconds, type: 'focus'));
      _pomodoroCount++;
      if (_pomodoroCount % 4 == 0) {
        _queuePrompt(title: 'Pomodoro Complete!', message: 'Great work! You\'ve completed 4 pomodoros. Time for a long break?', suggestedMode: TimerMode.longBreak);
      } else {
        _queuePrompt(title: 'Pomodoro Complete!', message: 'Great work! Time for a short break?', suggestedMode: TimerMode.shortBreak);
      }
    } else if (_mode == TimerMode.shortBreak) {
      _queuePrompt(title: 'Short Break Complete!', message: 'Break\'s over! Ready to start another pomodoro?', suggestedMode: TimerMode.pomodoro);
    } else {
      _pomodoroCount = 0;
      _queuePrompt(title: 'Long Break Complete!', message: 'You\'re refreshed! Ready to start a new pomodoro cycle?', suggestedMode: TimerMode.pomodoro);
    }

    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  void _queuePrompt({required String title, required String message, required TimerMode suggestedMode}) {
    _nextPromptId++;
    _pendingPrompt = PomodoroCompletionPrompt(id: _nextPromptId, title: title, message: message, suggestedMode: suggestedMode);
    _promptEventId = _nextPromptId;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
