import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lockedin_frontend/models/user/streak.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/services/streak_service.dart';
import '../services/auth_service.dart';

enum StreakSessionSource { activity, pomodoro }

class StreakProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _sessionStartKey = 'streak_session_start';

  bool isLoading = false;
  String? errorMessage;

  Streak? streak;

  String? _token;
  Timer? _liveSessionTicker;
  bool _isSyncingGoalCompletion = false;
  bool _isFetchingForSync = false;
  DateTime? _goalCompletionSyncedDate;
  Future<void> _sessionQueue = Future<void>.value();
  bool _backendSessionActive = false;

  /// Tracks whether a backend session is currently active
  bool _sessionActive = false;
  bool get sessionActive => _sessionActive;
  final Map<StreakSessionSource, int> _activeSourceCounts = <StreakSessionSource, int>{};

  // Once-per-day goal completion notification
  bool _pendingGoalCompletion = false;
  DateTime? _goalCompletionDate;
  bool get hasPendingGoalCompletion => _pendingGoalCompletion;

  void acknowledgeGoalCompletion() {
    _pendingGoalCompletion = false;
    notifyListeners();
  }

  /// Local timestamp when the current session started (for live UI timer)
  DateTime? _sessionStartTime;
  DateTime? get sessionStartTime => _sessionStartTime;

  /// Returns the current session elapsed seconds (for live display)
  int get currentSessionSeconds {
    if (_sessionStartTime == null || !_sessionActive) return 0;

    final now = DateTime.now();
    final start = _sessionStartTime!;
    final todayStart = DateTime(now.year, now.month, now.day);

    // Only count the portion that belongs to today.
    final effectiveStart = start.isBefore(todayStart) ? todayStart : start;
    return now.difference(effectiveStart).inSeconds;
  }

  // Easy getters
  bool get hasSetGoal => (streak?.dailyGoalSeconds ?? 0) > 0;
  bool get canUpdateGoal => streak?.canUpdateGoal ?? true;
  int get goalUpdateDaysRemaining => streak?.goalUpdateDaysRemaining ?? 0;
  int get currentStreak => streak?.currentStreak ?? 0;
  int get longestStreak => streak?.longestStreak ?? 0;
  int get totalGoalDays => streak?.totalGoalDays ?? 0;

  int get dailyGoalSeconds => streak?.dailyGoalSeconds ?? 0;
  int get todayAccumulatedSeconds => streak?.todayAccumulatedSeconds ?? 0;
  int get todayTrackedSeconds => todayAccumulatedSeconds + currentSessionSeconds;

  bool get hasCompletedTodayGoal {
    if (streak == null || dailyGoalSeconds <= 0) return false;

    final lastMet = streak?.lastGoalMetDate;
    if (lastMet == null) return false;

    final now = DateTime.now();
    final lastMetLocal = lastMet.toLocal();

    return lastMetLocal.year == now.year &&
        lastMetLocal.month == now.month &&
        lastMetLocal.day == now.day;
  }

  Future<void> restoreSession() async {
    final stored = await _storage.read(key: _sessionStartKey);
    if (stored != null) {
      final ts = DateTime.tryParse(stored);
      if (ts != null) {
        final now = DateTime.now();
        if (_isSameDay(ts, now)) {
          // Restore the session start time so currentSessionSeconds is correct
          _sessionActive = true;
          _backendSessionActive = true;
          _sessionStartTime = ts;
          notifyListeners();
          debugPrint('[StreakProvider] restored session from $ts');

          // Immediately end and flush it to the backend
          await endSession();
          debugPrint('[StreakProvider] flushed restored session to backend');
        } else {
          await _storage.delete(key: _sessionStartKey);
          _sessionActive = false;
          _sessionStartTime = null;
          debugPrint('[StreakProvider] discarded stale session from $ts');
        }
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int get _totalActiveSourceCount => _activeSourceCounts.values.fold<int>(0, (sum, count) => sum + count);

  void _incrementSource(StreakSessionSource source) {
    _activeSourceCounts[source] = (_activeSourceCounts[source] ?? 0) + 1;
  }

  void _decrementSource(StreakSessionSource source) {
    final count = _activeSourceCounts[source];
    if (count == null) return;
    if (count <= 1) {
      _activeSourceCounts.remove(source);
      return;
    }
    _activeSourceCounts[source] = count - 1;
  }

  Future<void> _enqueueSessionOp(Future<void> Function() op) {
    _sessionQueue = _sessionQueue.then((_) => op());
    return _sessionQueue;
  }

  void _startLiveSessionTicker() {
    _liveSessionTicker?.cancel();
    _liveSessionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _handleLiveSessionTick();
    });
  }

  void _stopLiveSessionTicker() {
    _liveSessionTicker?.cancel();
    _liveSessionTicker = null;
  }

  void _markGoalCompletedToday() {
    final todayDate = _todayDate();
    if (_goalCompletionDate == null || !_isSameDay(_goalCompletionDate!, todayDate)) {
      _goalCompletionDate = todayDate;
      _pendingGoalCompletion = true;
    }
  }

  void _handleLiveSessionTick() {
    if (!_sessionActive) return;

    final todayDate = _todayDate();
    if (_goalCompletionSyncedDate != null && !_isSameDay(_goalCompletionSyncedDate!, todayDate)) {
      _goalCompletionSyncedDate = null;
    }

    final alreadySyncedToday = _goalCompletionSyncedDate != null && _isSameDay(_goalCompletionSyncedDate!, todayDate);
    if (hasCompletedTodayGoal && !alreadySyncedToday && !_isSyncingGoalCompletion) {
      unawaited(_syncCompletionToBackendAndRefresh());
    }
  }

  // Future<void> _syncCompletionToBackendAndRefresh() async {
  //   if (_isSyncingGoalCompletion) return;
  //   _isSyncingGoalCompletion = true;

  //   try {
  //     _token ??= await AuthService.getToken();
  //     if (_token == null) return;

  //     // Flush current active session so backend streak is updated immediately
  //     await StreakService.endSession(token: _token!);
  //     _backendSessionActive = false;

  //     // Pull fresh streak from backend and notify all listening screens
  //     await fetchStreak(forceRefresh: true);

  //     _goalCompletionSyncedDate = _todayDate();
  //     if (hasCompletedTodayGoal) {
  //       _markGoalCompletedToday();
  //     }

  //     // Continue tracking seamlessly if user is still in an active tracked flow
  //     if (_sessionActive) {
  //       _sessionStartTime = DateTime.now();
  //       await _storage.write(key: _sessionStartKey, value: _sessionStartTime!.toIso8601String());
  //       await StreakService.startSession(token: _token!);
  //       _backendSessionActive = true;
  //     }

  //     notifyListeners();
  //   } catch (e) {
  //     final msg = e.toString();
  //     if (msg.contains('UNAUTHORIZED')) {
  //       _handleUnauthorized();
  //       return;
  //     }
  //     debugPrint('[StreakProvider] sync completion error: $e');
  //   } finally {
  //     _isSyncingGoalCompletion = false;
  //   }
  // }

  Future<void> _syncCompletionToBackendAndRefresh() async {
    if (_isSyncingGoalCompletion) return;
    _isSyncingGoalCompletion = true;

    try {
      _token ??= await AuthService.getToken();
      if (_token == null) return;

      await StreakService.endSession(token: _token!);
      _backendSessionActive = false;

      // ✅ Use the flag so fetchStreak won't re-trigger this method
      _isFetchingForSync = true;
      await fetchStreak(forceRefresh: true);
      _isFetchingForSync = false;

      _goalCompletionSyncedDate = _todayDate();
      if (hasCompletedTodayGoal) {
        _markGoalCompletedToday();
      }

      if (_sessionActive) {
        _sessionStartTime = DateTime.now();
        await _storage.write(key: _sessionStartKey, value: _sessionStartTime!.toIso8601String());
        await StreakService.startSession(token: _token!);
        _backendSessionActive = true;
      }

      notifyListeners();
    } catch (e) {
      _isFetchingForSync = false;
      final msg = e.toString();
      if (msg.contains('UNAUTHORIZED')) {
        _handleUnauthorized();
        return;
      }
      debugPrint('[StreakProvider] sync completion error: $e');
    } finally {
      _isSyncingGoalCompletion = false;
    }
  }

  // ---------- FETCH STREAK ----------
  Future<void> fetchStreak({bool forceRefresh = false}) async {
    // Return cached data immediately if available and no forced refresh
    if (streak != null && !forceRefresh) return;

    _token ??= await AuthService.getToken();
    if (_token == null) {
      errorMessage = 'Not authenticated';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final data = await StreakService.getStreak(token: _token!);
      streak = Streak.fromJson(data);
      debugPrint('[StreakProvider] fetchStreak success: dailyGoalSeconds=${streak?.dailyGoalSeconds}');

      // Check if goal was met but not yet marked in lastGoalMetDate
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final lastMet = streak?.lastGoalMetDate;
      final lastMetDate = lastMet != null ? DateTime(lastMet.year, lastMet.month, lastMet.day) : null;

      final goalMet = (streak?.todayAccumulatedSeconds ?? 0) >= (streak?.dailyGoalSeconds ?? 0);
      final notMarkedToday = lastMetDate == null || lastMetDate.isBefore(todayDate);

      // ✅ Don't re-trigger sync if we're already being called FROM a sync
      if (goalMet && notMarkedToday && !_isSyncingGoalCompletion && !_isFetchingForSync) {
        debugPrint('[StreakProvider] Goal met but not marked. Syncing...');
        _goalCompletionSyncedDate = null;
        unawaited(_syncCompletionToBackendAndRefresh());
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('UNAUTHORIZED')) {
        _handleUnauthorized();
        return;
      }
      errorMessage = msg.replaceFirst('Exception: ', '');
      debugPrint('[StreakProvider] fetchStreak error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------- SET DAILY GOAL ----------
  Future<bool> setDailyGoal({required int minutes}) async {
    _token ??= await AuthService.getToken();
    if (_token == null) {
      errorMessage = 'Not authenticated';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await StreakService.setDailyGoal(token: _token!, minutes: minutes);
      // Update local streak model
      if (streak != null) {
        streak = Streak(
          id: streak!.id,
          userId: streak!.userId,
          currentStreak: streak!.currentStreak,
          longestStreak: streak!.longestStreak,
          totalGoalDays: streak!.totalGoalDays,
          dailyGoalSeconds: minutes * 60,
          todayAccumulatedSeconds: streak!.todayAccumulatedSeconds,
          canUpdateGoal: false,
          goalUpdateDaysRemaining: 7,
          lastGoalMetDate: streak!.lastGoalMetDate,
        );
      }
      debugPrint('[StreakProvider] setDailyGoal success: ${minutes * 60} seconds');
      return true;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('UNAUTHORIZED')) {
        _handleUnauthorized();
        return false;
      }
      errorMessage = msg.replaceFirst('Exception: ', '');
      debugPrint('[StreakProvider] setDailyGoal error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------- UNAUTHORIZED (force logout) ----------
  void _handleUnauthorized() {
    debugPrint('[StreakProvider] 401 received — forcing logout');
    streak = null;
    _token = null;
    _sessionActive = false;
    _backendSessionActive = false;
    _activeSourceCounts.clear();
    _sessionStartTime = null;
    _storage.delete(key: _sessionStartKey);
    isLoading = false;
    errorMessage = null;
    AuthService.clearToken();
    AuthProvider.onForceLogout?.call();
    notifyListeners();
  }

  // ---------- START SESSION (call when user enters a tracked screen) ----------
  Future<void> startSession() async {
    return startSessionFrom(StreakSessionSource.activity);
  }

  Future<void> startSessionFrom(StreakSessionSource source) async {
    _incrementSource(source);
    if (_sessionActive) return; // already running

    _token ??= await AuthService.getToken();
    if (_token == null) {
      _decrementSource(source);
      return;
    }

    // Set active immediately so endSession() won't skip if called before API returns
    _sessionActive = true;
    _sessionStartTime = DateTime.now();
    await _storage.write(key: _sessionStartKey, value: _sessionStartTime!.toIso8601String());
    _startLiveSessionTicker();
    notifyListeners();

    await _enqueueSessionOp(() async {
      if (!_sessionActive || _backendSessionActive) return;
      try {
        await StreakService.startSession(token: _token!);
        _backendSessionActive = true;
        debugPrint('[StreakProvider] session started');
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('UNAUTHORIZED')) {
          _handleUnauthorized();
          return;
        }
        // Revert if the API call failed
        _sessionActive = false;
        _activeSourceCounts.clear();
        _sessionStartTime = null;
        _stopLiveSessionTicker();
        await _storage.delete(key: _sessionStartKey);
        notifyListeners();
        debugPrint('[StreakProvider] startSession error: $e');
      }
    });
  }

  // ---------- END SESSION (call when user leaves a tracked screen) ----------
  Future<void> endSession() async {
    return endSessionFrom(StreakSessionSource.activity);
  }

  Future<void> endSessionFrom(StreakSessionSource source) async {
    _decrementSource(source);
    if (_totalActiveSourceCount > 0) return;
    if (!_sessionActive) return;

    _sessionActive = false;
    _sessionStartTime = null;
    _stopLiveSessionTicker();
    await _storage.delete(key: _sessionStartKey);
    notifyListeners();

    _token ??= await AuthService.getToken();
    if (_token == null) return;

    await _enqueueSessionOp(() async {
      if (!_backendSessionActive) return;
      try {
        final result = await StreakService.endSession(token: _token!);
        _backendSessionActive = false;
        debugPrint('[StreakProvider] session ended: $result');

        await fetchStreak(forceRefresh: true);
        if (hasCompletedTodayGoal) {
          _goalCompletionSyncedDate = _todayDate();
          _markGoalCompletedToday();
        }
        notifyListeners();
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('UNAUTHORIZED')) {
          _handleUnauthorized();
          return;
        }
        debugPrint('[StreakProvider] endSession error: $e');
      }
    });
  }

  // ---------- RESET (on logout) ----------
  void reset() {
    streak = null;
    errorMessage = null;
    isLoading = false;
    _token = null;
    _sessionActive = false;
    _backendSessionActive = false;
    _activeSourceCounts.clear();
    _sessionStartTime = null;
    _stopLiveSessionTicker();
    _pendingGoalCompletion = false;
    _goalCompletionDate = null;
    _goalCompletionSyncedDate = null;
    _storage.delete(key: _sessionStartKey);
    notifyListeners();
  }
}
