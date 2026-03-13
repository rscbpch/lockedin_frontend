import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lockedin_frontend/models/user/streak.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/services/goal_service.dart';
import '../services/auth_service.dart';

class StreakProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _sessionStartKey = 'streak_session_start';

  bool isLoading = false;
  String? errorMessage;

  Streak? streak;

  String? _token;

  /// Tracks whether a backend session is currently active
  bool _sessionActive = false;
  bool get sessionActive => _sessionActive;

  /// Local timestamp when the current session started (for live UI timer)
  DateTime? _sessionStartTime;
  DateTime? get sessionStartTime => _sessionStartTime;

  /// Returns the current session elapsed seconds (for live display)
  int get currentSessionSeconds {
    if (_sessionStartTime == null || !_sessionActive) return 0;
    return DateTime.now().difference(_sessionStartTime!).inSeconds;
  }

  // Easy getters
  bool get hasSetGoal => (streak?.dailyGoalSeconds ?? 0) > 0;
  int get currentStreak => streak?.currentStreak ?? 0;
  int get longestStreak => streak?.longestStreak ?? 0;
  int get totalGoalDays => streak?.totalGoalDays ?? 0;
  int get dailyGoalSeconds => streak?.dailyGoalSeconds ?? 0;
  int get todayAccumulatedSeconds => streak?.todayAccumulatedSeconds ?? 0;

  /// Restore a persisted session start time (call once on app startup).
  Future<void> restoreSession() async {
    final stored = await _storage.read(key: _sessionStartKey);
    if (stored != null) {
      final ts = DateTime.tryParse(stored);
      if (ts != null) {
        _sessionActive = true;
        _sessionStartTime = ts;
        notifyListeners();
        debugPrint('[StreakProvider] restored session from $ts');
      }
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
      final data = await GoalService.getStreak(token: _token!);
      streak = Streak.fromJson(data);
      debugPrint('[StreakProvider] fetchStreak success: dailyGoalSeconds=${streak?.dailyGoalSeconds}');
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
      await GoalService.setDailyGoal(token: _token!, minutes: minutes);
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
    if (_sessionActive) return; // already running

    _token ??= await AuthService.getToken();
    if (_token == null) return;

    // Set active immediately so endSession() won't skip if called before API returns
    _sessionActive = true;
    _sessionStartTime = DateTime.now();
    await _storage.write(key: _sessionStartKey, value: _sessionStartTime!.toIso8601String());
    notifyListeners();

    try {
      await GoalService.startSession(token: _token!);
      debugPrint('[StreakProvider] session started');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('UNAUTHORIZED')) {
        _handleUnauthorized();
        return;
      }
      // Revert if the API call failed
      _sessionActive = false;
      _sessionStartTime = null;
      await _storage.delete(key: _sessionStartKey);
      notifyListeners();
      debugPrint('[StreakProvider] startSession error: $e');
    }
  }

  // ---------- END SESSION (call when user leaves a tracked screen) ----------
  Future<void> endSession() async {
    if (!_sessionActive) return;

    // Immediately stop the UI timer
    _sessionActive = false;
    _sessionStartTime = null;
    _storage.delete(key: _sessionStartKey);
    notifyListeners();

    _token ??= await AuthService.getToken();
    if (_token == null) return;

    try {
      final result = await GoalService.endSession(token: _token!);
      debugPrint('[StreakProvider] session ended: $result');

      // Refresh streak data to get updated accumulated seconds
      await fetchStreak(forceRefresh: true);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('UNAUTHORIZED')) {
        _handleUnauthorized();
        return;
      }
      debugPrint('[StreakProvider] endSession error: $e');
    }
  }

  // ---------- RESET (on logout) ----------
  void reset() {
    streak = null;
    errorMessage = null;
    isLoading = false;
    _token = null;
    _sessionActive = false;
    _sessionStartTime = null;
    _storage.delete(key: _sessionStartKey);
    notifyListeners();
  }
}
