import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/follow_provider.dart';
import 'package:lockedin_frontend/ui/screens/profile/widgets/follow_list_tile.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

/// A draggable bottom sheet that shows a user's followers or following list.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.white,
///   shape: RoundedRectangleBorder(
///     borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
///   ),
///   builder: (_) => FollowListSheet(isFollowers: true),
/// );
/// ```
class FollowListSheet extends StatefulWidget {
  final bool isFollowers;

  const FollowListSheet({required this.isFollowers, super.key});

  @override
  State<FollowListSheet> createState() => _FollowListSheetState();
}

class _FollowListSheetState extends State<FollowListSheet> {
  @override
  void initState() {
    super.initState();
    // Use FollowProvider — already registered in main.dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FollowProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FollowProvider>();
    final users = widget.isFollowers ? provider.followers : provider.following;
    final isLoading = provider.status == FollowStatus.loading;
    final error = provider.status == FollowStatus.error
        ? (provider.errorMessage ?? 'Failed to load')
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isFollowers ? 'Followers' : 'Following',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Quicksand',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.accent),
          ..._buildBody(
            scrollController: scrollController,
            isLoading: isLoading,
            error: error,
            users: users,
            provider: provider,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody({
    required ScrollController scrollController,
    required bool isLoading,
    required String? error,
    required List users,
    required FollowProvider provider,
  }) {
    if (isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ];
    }

    if (error != null) {
      return [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Text(
                error,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontFamily: 'Quicksand',
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => provider.fetchAll(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ];
    }

    if (users.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'None yet',
            style: TextStyle(color: AppColors.grey, fontFamily: 'Quicksand'),
          ),
        ),
      ];
    }

    return [
      Expanded(
        child: ListView.builder(
          controller: scrollController,
          itemCount: users.length,
          itemBuilder: (_, i) => FollowListTile(user: users[i]),
        ),
      ),
    ];
  }
}