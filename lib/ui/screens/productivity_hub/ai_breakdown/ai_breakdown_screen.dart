import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/ai_breakdown/widget/assistant_message_bubble.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/ai_breakdown/widget/chat_empty_state.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/ai_breakdown/widget/chat_input_bar.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/ai_breakdown/widget/error_banner.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/ai_breakdown/widget/typing_indicator.dart';
import 'package:lockedin_frontend/ui/screens/productivity_hub/ai_breakdown/widget/user_message_bubble.dart';
import '../../../../models/productivity_tools/task_breakdown/breakdown_step.dart';
import './../../../../models/productivity_tools/task_breakdown/chat_message.dart';
import '../../../../services/ai_breakdown_service.dart';
import '../../../../utils/activity_tracker.dart';
import 'history_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/display/simple_back_sliver_app_bar.dart';

class AiBreakdownScreen extends StatefulWidget {
  final String? initialChatId;

  const AiBreakdownScreen({super.key, this.initialChatId});

  @override
  State<AiBreakdownScreen> createState() => _AiBreakdownScreenState();
}

class _AiBreakdownScreenState extends State<AiBreakdownScreen> with ActivityTracker {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  String? _currentChatId;
  bool _isLoading = false;
  String? _errorMessage;

  late final AiBreakdownService _service;

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.initialChatId;

    _service = AiBreakdownService(context);

    if (_currentChatId != null) {
      _loadExistingChat();
    }
  }

  Future<void> _loadExistingChat() async {
    if (_currentChatId == null) return;

    setState(() {
      _isLoading = true;
      _messages.clear();
      _errorMessage = null;
    });

    try {
      final chat = await _service.getChatById(_currentChatId!);
      final rawMessages = chat['messages'] as List<dynamic>? ?? [];

      final loadedMessages = rawMessages.map((m) {
        final role = m['role'] as String;
        final rawContent = m['content'] as String? ?? '';

        // User messages are plain text
        if (role == 'user') {
          return ChatMessage(role: role, content: rawContent);
        }

        // Assistant messages: content is a JSON-encoded string
        // e.g. "{\"status\":\"planned\",\"steps\":[...]}"
        try {
          final decoded = jsonDecode(rawContent) as Map<String, dynamic>;
          final status = decoded['status'] as String?;
          final rawSteps = decoded['steps'] as List<dynamic>? ?? [];
          final steps = rawSteps.map((s) => BreakdownStep.fromJson(s as Map<String, dynamic>)).toList();
          final clarification = decoded['clarification_question'] as String?;

          return ChatMessage(role: role, content: rawContent, status: status, steps: steps, clarificationQuestion: clarification);
        } catch (_) {
          // If content is not valid JSON, render as plain text fallback
          return ChatMessage(role: role, content: rawContent);
        }
      }).toList();

      setState(() {
        _messages.addAll(loadedMessages);
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load chat history';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _isLoading = true;
      _errorMessage = null;
    });

    _scrollToBottom();

    try {
      final result = await _service.sendMessage(message: text, chatId: _currentChatId);

      final chatId = result['chatId'] as String?;
      final response = result['response'] as Map<String, dynamic>? ?? {};
      final status = response['status'] as String? ?? '';
      final rawSteps = response['steps'] as List<dynamic>? ?? [];
      final steps = rawSteps.map((s) => BreakdownStep.fromJson(s as Map<String, dynamic>)).toList();
      final clarification = response['clarification_question'] as String?;

      setState(() {
        _currentChatId = chatId;
        _messages.add(ChatMessage(role: 'assistant', content: '', status: status, steps: steps, clarificationQuestion: clarification));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _openHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HistoryScreen(
        service: _service,
        onChatSelected: (id) {
          setState(() {
            _currentChatId = id;
            _messages.clear();
          });
          Navigator.pop(context);
          _loadExistingChat();
        },
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SimpleBackSliverAppBar(
            title: 'Task Breakdown',
            onBack: () => context.go('/productivity-hub'),
            action: IconButton(
              onPressed: _openHistory,
              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1E293B)),
            ),
          ),
          _buildMessageListSliver(),
        ],
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null) ErrorBanner(message: _errorMessage!, onDismiss: () => setState(() => _errorMessage = null)),
              ChatInputBar(controller: _inputController, onSend: _sendMessage, isLoading: _isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageListSliver() {
    if (_messages.isEmpty && !_isLoading) {
      return const SliverFillRemaining(hasScrollBody: false, child: ChatEmptyState());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == _messages.length) {
            return const TypingIndicator();
          }
          final msg = _messages[index];
          return msg.role == 'user' ? UserMessageBubble(content: msg.content) : AssistantMessageBubble(message: msg);
        }, childCount: _messages.length + (_isLoading ? 1 : 0)),
      ),
    );
  }
}
