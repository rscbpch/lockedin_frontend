import 'dart:convert';
import 'breakdown_step.dart';

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final String? status; // 'planned' | 'clarification_required' | 'unsupported_request'
  final List<BreakdownStep> steps;
  final String? clarificationQuestion;

  ChatMessage({
    required this.role,
    required this.content,
    this.status,
    this.steps = const [],
    this.clarificationQuestion,
  });

  /// Parses a raw message object from GET /ai/chats/:chatId
  factory ChatMessage.fromBackendMessage(Map<String, dynamic> msg) {
    final role = msg['role'] as String;
    final rawContent = msg['content'] as String? ?? '';

    // User messages are plain text
    if (role == 'user') {
      return ChatMessage(role: role, content: rawContent);
    }

    // Assistant messages have JSON-encoded content
    try {
      final decoded = jsonDecode(rawContent) as Map<String, dynamic>;
      final status = decoded['status'] as String?;
      final rawSteps = decoded['steps'] as List<dynamic>? ?? [];
      final steps = rawSteps
          .map((s) => BreakdownStep.fromJson(s as Map<String, dynamic>))
          .toList();
      final clarification = decoded['clarification_question'] as String?;

      return ChatMessage(
        role: role,
        content: rawContent,
        status: status,
        steps: steps,
        clarificationQuestion: clarification,
      );
    } catch (_) {
      // Fallback if content is not valid JSON
      return ChatMessage(role: role, content: rawContent);
    }
  }
}