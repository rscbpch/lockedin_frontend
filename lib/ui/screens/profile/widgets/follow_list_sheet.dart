
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/models/user/follow_user_model.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/services/follow_service.dart';
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
  List<FollowUser> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final service = FollowService(getAuthToken: () async => auth.token);
    try {
      final result = widget.isFollowers
          ? await service.getFollowers()
          : await service.getFollowing();
      if (mounted) {
        setState(() {
          _users = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          ..._buildBody(scrollController),
        ],
      ),
    );
  }

  List<Widget> _buildBody(ScrollController scrollController) {
    if (_isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ];
    }

    if (_error != null) {
      return [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _error!,
            style: const TextStyle(
              color: AppColors.grey,
              fontFamily: 'Quicksand',
            ),
          ),
        ),
      ];
    }

    if (_users.isEmpty) {
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
          itemCount: _users.length,
          itemBuilder: (_, i) => FollowListTile(user: _users[i]),
        ),
      ),
    ];
  }
}
