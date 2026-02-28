import 'package:flutter/material.dart';
import '../../../../services/ai_breakdown_service.dart';

class HistoryScreen extends StatefulWidget {
  final AiBreakdownService service;
  final void Function(String chatId) onChatSelected;

  const HistoryScreen({
    super.key,
    required this.service,
    required this.onChatSelected,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _chatsFuture;

  @override
  void initState() {
    super.initState();
    // getChats() now returns List<Map<String, dynamic>> directly
    _chatsFuture = widget.service.getChats();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFFEFF6FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildHandle(),
          const SizedBox(height: 16),
          _buildTitle(),
          const SizedBox(height: 12),
          Expanded(child: _buildChatList()),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFCBD5E1),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'History',
      style: TextStyle(
        color: Color(0xFF1E293B),
        fontFamily: 'Nunito',
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildChatList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _chatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Failed to load history',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontFamily: 'Nunito',
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() {
                    _chatsFuture = widget.service.getChats();
                  }),
                  child: const Text(
                    'Try again',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final chats = snapshot.data ?? [];

        if (chats.isEmpty) {
          return const Center(
            child: Text(
              'No chat history yet',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontFamily: 'Nunito',
                fontSize: 15,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: chats.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = chats[index];


            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              title: Text(
                chat['title'] ?? 'Untitled',
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFFCBD5E1),
              ),
              onTap: () => widget.onChatSelected(chat['_id'] as String),
            );
          },
        );
      },
    );
  }
}