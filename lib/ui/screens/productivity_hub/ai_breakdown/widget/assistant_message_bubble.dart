import 'package:flutter/material.dart';
import '../../../../../models/productivity_tools/task_breakdown/chat_message.dart';
import 'assistant_avatar_icon.dart';
import 'planned_response_card.dart';
import 'clarification_card.dart';
import 'unsupported_request_card.dart';

class AssistantMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const AssistantMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AssistantAvatarIcon(),
          const SizedBox(width: 10),
          Expanded(child: _buildCard()),
        ],
      ),
    );
  }

  Widget _buildCard() {
    if (message.status == 'clarification_required') {
      return ClarificationCard(question: message.clarificationQuestion);
    }
    if (message.status == 'unsupported_request') {
      return const UnsupportedRequestCard();
    }
    if (message.status == 'planned' && message.steps.isNotEmpty) {
      return PlannedResponseCard(steps: message.steps);
    }
    return const SizedBox.shrink();
  }
}