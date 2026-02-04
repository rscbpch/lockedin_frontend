class PomodoroSession {
  final String id;
  final String userId;
  final int durationMinutes; // i think change to seconds is better for example 2mins 38seconds, then display as mm:ss
  final DateTime completedAt;
  final int shortBreak;
  final int longBreak;

  PomodoroSession({
    required this.id,
    required this.userId,
    required this.durationMinutes,
    required this.completedAt,
    required this.shortBreak,
    required this.longBreak
  });
}
