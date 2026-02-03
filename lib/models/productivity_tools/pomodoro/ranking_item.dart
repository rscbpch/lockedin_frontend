// for pomodoro ranking purpose

class RankingItem {
  final String userId;
  final String userName;
  final int totalFocusSeconds;

  RankingItem({
    required this.userId,
    required this.userName,
    required this.totalFocusSeconds
  });

  String get focusHours {
    final hours = totalFocusSeconds ~/ 3600;
    final minutes = (totalFocusSeconds % 3600) ~/ 60;
    return '$hours:$minutes';
  }
}
