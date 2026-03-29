class TestResult {
  final String flashcardId;
  bool correct;

  TestResult({
    required this.flashcardId,
    this.correct = false
  });
}

class FlashcardTestSession {
  final String deckId;
  final String userId;
  final List<TestResult> results;

  FlashcardTestSession({
    required this.deckId,
    required this.userId,
    required this.results,
  });

  int get totalCorrect => 
      results.where((r) => r.correct).length;

  int get totalWrong =>
      results.where((r) => !r.correct).length;
}
