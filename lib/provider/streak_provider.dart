import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/user/streak.dart';
import 'package:lockedin_frontend/services/goal_service.dart';
import '../services/auth_service.dart';

class StreakProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  Streak? streak;

  String? _token;

  // Easy getters
  bool get hasSetGoal => (streak?.dailyGoalSeconds ?? 0) > 0;
  int get currentStreak => streak?.currentStreak ?? 0;
  int get longestStreak => streak?.longestStreak ?? 0;
  int get totalGoalDays => streak?.totalGoalDays ?? 0;
  int get dailyGoalSeconds => streak?.dailyGoalSeconds ?? 0;
  int get todayAccumulatedSeconds => streak?.todayAccumulatedSeconds ?? 0;

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
      debugPrint(
        '[StreakProvider] fetchStreak success: dailyGoalSeconds=${streak?.dailyGoalSeconds}',
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
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
      debugPrint(
        '[StreakProvider] setDailyGoal success: ${minutes * 60} seconds',
      );
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[StreakProvider] setDailyGoal error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------- RESET (on logout) ----------
  void reset() {
    streak = null;
    errorMessage = null;
    isLoading = false;
    _token = null;
    notifyListeners();
  }
}
