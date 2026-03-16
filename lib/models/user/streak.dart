class Streak {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final int totalGoalDays;
  final int dailyGoalSeconds;
  final int todayAccumulatedSeconds;
  final bool canUpdateGoal;
  final int goalUpdateDaysRemaining;

  Streak({
    required this.id,
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalGoalDays,
    required this.dailyGoalSeconds,
    required this.todayAccumulatedSeconds,
    required this.canUpdateGoal,
    required this.goalUpdateDaysRemaining,
  });

  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalGoalDays: json['totalGoalDays'] ?? 0,
      dailyGoalSeconds: json['dailyGoalSeconds'] ?? 0,
      todayAccumulatedSeconds: json['todayAccumulatedSeconds'] ?? 0,
      canUpdateGoal: json['canUpdateGoal'] ?? true,
      goalUpdateDaysRemaining: json['goalUpdateDaysRemaining'] ?? 0,
    );
  }
}
