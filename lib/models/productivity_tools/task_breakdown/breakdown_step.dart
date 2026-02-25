class BreakdownStep {
  final int step;
  final String title;
  final String description;

  BreakdownStep({
    required this.step,
    required this.title,
    required this.description,
  });

  factory BreakdownStep.fromJson(Map<String, dynamic> json) {
    return BreakdownStep(
      step: json['step'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}