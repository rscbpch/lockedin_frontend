class Streak {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final int targetDurationInSeconds;  // store as second in backend

  Streak({
    required this.id,
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.targetDurationInSeconds
  });
}
