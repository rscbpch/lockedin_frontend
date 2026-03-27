import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:lockedin_frontend/models/chat/group_model.dart';
import 'package:lockedin_frontend/models/user/follow_user_model.dart';
import 'package:lockedin_frontend/models/user/search_user_model.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/provider/group_chat_provider.dart';
import 'package:lockedin_frontend/services/follow_service.dart';
import 'package:lockedin_frontend/ui/screens/profile/user_other_profile_screen.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class GroupDetailsScreen extends StatefulWidget {
  final String groupId;
  final Channel channel;

  const GroupDetailsScreen({
    super.key,
    required this.groupId,
    required this.channel,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  GroupModel? _group;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    setState(() => _isLoading = true);
    final provider = context.read<GroupChatProvider>();
    final group = await provider.getGroupDetails(widget.groupId);
    if (mounted) {
      setState(() {
        _group = group;
        _isLoading = false;
      });
    }
  }

  bool get _isOwner {
    final currentUserId =
        context.read<GroupChatProvider>().streamClient.state.currentUser?.id;
    if (currentUserId == null || _group == null) return false;
    return _group!.ownerId.toString() == currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Group Info',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _group == null
              ? const Center(child: Text('Failed to load group'))
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      children: [
        _buildGroupHeader(),
        const SizedBox(height: 8),

        if (_isOwner) ...[
          _buildRenameButton(),
          const Divider(),
        ],

        _buildMembersSection(),
        const Divider(),

        if (_isOwner) ...[
          _buildAddMembersButton(),
          const Divider(),
          _buildTransferOwnershipButton(),
          const Divider(),
        ],

        _buildLeaveButton(),
        if (_isOwner) _buildDeleteButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildGroupHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Text(
              _group!.name.isNotEmpty ? _group!.name[0].toUpperCase() : 'G',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _group!.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_group!.memberCount} members',
            style: const TextStyle(color: AppColors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRenameButton() {
    return ListTile(
      leading: const Icon(Icons.edit, color: AppColors.primary),
      title: const Text('Rename Group',
          style: TextStyle(color: AppColors.textPrimary)),
      onTap: () => _showRenameDialog(),
    );
  }

  Widget _buildMembersSection() {
    final currentUserId =
        context.read<GroupChatProvider>().streamClient.state.currentUser?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Members (${_group!.members.length})',
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ..._group!.members.map((member) {
          final isOwner = member.id == _group!.ownerId.toString();
          final isMe = member.id == currentUserId;

          return GestureDetector(
            onTap: !isMe
                ? () => _openUserProfile(member)
                : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.accent,
                backgroundImage: member.avatar != null
                    ? NetworkImage(member.avatar!)
                    : null,
                child: member.avatar == null
                    ? Text(member.name[0].toUpperCase(),
                        style: const TextStyle(color: AppColors.primary))
                    : null,
              ),
              title: Text(
                '${member.name}${isMe ? ' (You)' : ''}',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
              subtitle: isOwner
                  ? const Text('Owner',
                      style:
                          TextStyle(color: AppColors.primary, fontSize: 12))
                  : null,
              trailing: _isOwner && !isMe
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: () => _confirmRemoveMember(member),
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAddMembersButton() {
    return ListTile(
      leading: const Icon(Icons.person_add, color: AppColors.primary),
      title: const Text('Add Members',
          style: TextStyle(color: AppColors.textPrimary)),
      onTap: () => _showAddMembersSheet(),
    );
  }

  Widget _buildTransferOwnershipButton() {
    return ListTile(
      leading: const Icon(Icons.swap_horiz, color: Colors.orange),
      title: const Text('Transfer Ownership',
          style: TextStyle(color: Colors.orange)),
      onTap: () => _showTransferOwnershipSheet(),
    );
  }

  Widget _buildLeaveButton() {
    return ListTile(
      leading: const Icon(Icons.exit_to_app, color: Colors.orange),
      title: const Text('Leave Group',
          style: TextStyle(color: Colors.orange)),
      onTap: () => _confirmLeave(),
    );
  }

  Widget _buildDeleteButton() {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: const Text('Delete Group', style: TextStyle(color: Colors.red)),
      onTap: () => _confirmDelete(),
    );
  }

  void _openUserProfile(GroupMemberModel member) {
    final searchUserResult = SearchUserResult(
      id: member.id,
      username: member.username,
      displayName: member.displayName ?? member.username,
      bio: '',
      avatar: member.avatar ?? '',
      isFollowing: false,
      followers: 0,
      following: 0,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserOtherProfileScreen(user: searchUserResult),
      ),
    );
  }

  // ── Dialogs & Sheets ─────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _group!.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Rename Group',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Group name',
            filled: true,
            fillColor: AppColors.backgroundBox,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final success =
                  await context.read<GroupChatProvider>().renameGroup(
                        groupId: widget.groupId,
                        name: name,
                      );
              if (success && mounted) _loadGroupDetails();
            },
            child: const Text('Rename',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showAddMembersSheet() {
    final existingIds = _group!.members.map((m) => m.id).toSet();
    final Set<String> selected = {};

    Future<List<FollowUser>> loadAvailable() async {
      final auth = context.read<AuthProvider>();
      final service = FollowService(getAuthToken: () async => auth.token);
      final results = await Future.wait([
        service.getFollowers(),
        service.getFollowing(),
      ]);
      final followerIds = results[0].map((u) => u.id).toSet();
      final mutuals =
          results[1].where((u) => followerIds.contains(u.id)).toList();
      return mutuals.where((u) => !existingIds.contains(u.id)).toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Add Members',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.textPrimary)),
                    TextButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await context
                                  .read<GroupChatProvider>()
                                  .addMembers(
                                    groupId: widget.groupId,
                                    userIds: selected.toList(),
                                  );
                              _loadGroupDetails();
                            },
                      child: Text(
                        'Add (${selected.length})',
                        style: TextStyle(
                          color: selected.isEmpty
                              ? AppColors.grey
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<FollowUser>>(
                  future: loadAvailable(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('Failed to load contacts',
                              style: TextStyle(color: AppColors.grey)));
                    }
                    final available = snapshot.data ?? [];
                    if (available.isEmpty) {
                      return const Center(
                          child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No mutual connections to add',
                            style: TextStyle(color: AppColors.grey)),
                      ));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: available.length,
                      itemBuilder: (_, i) {
                        final user = available[i];
                        final isSelected = selected.contains(user.id);
                        final displayName = user.displayName.isNotEmpty
                            ? user.displayName
                            : user.username;
                        return ListTile(
                          onTap: () => setSheetState(() {
                            isSelected
                                ? selected.remove(user.id)
                                : selected.add(user.id);
                          }),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.accent,
                            backgroundImage: user.avatar.isNotEmpty
                                ? NetworkImage(user.avatar)
                                : null,
                            child: user.avatar.isEmpty
                                ? Text(displayName[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: AppColors.primary))
                                : null,
                          ),
                          title: Text(displayName,
                              style: const TextStyle(
                                  color: AppColors.textPrimary)),
                          subtitle: Text('@${user.username}',
                              style: const TextStyle(
                                  color: AppColors.grey, fontSize: 12)),
                          trailing: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.grey),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransferOwnershipSheet() {
    final currentUserId =
        context.read<GroupChatProvider>().streamClient.state.currentUser?.id;
    final candidates =
        _group!.members.where((m) => m.id != currentUserId).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Transfer Ownership',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.textPrimary),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Select a member to become the new owner. You will become a regular member.',
                style: TextStyle(color: AppColors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            if (candidates.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No other members to transfer to',
                      style: TextStyle(color: AppColors.grey)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: candidates.length,
                  itemBuilder: (_, i) {
                    final member = candidates[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accent,
                        backgroundImage: member.avatar != null
                            ? NetworkImage(member.avatar!)
                            : null,
                        child: member.avatar == null
                            ? Text(member.name[0].toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.primary))
                            : null,
                      ),
                      title: Text(member.name,
                          style:
                              const TextStyle(color: AppColors.textPrimary)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 14, color: AppColors.grey),
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmTransfer(member);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmTransfer(GroupMemberModel member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Transfer Ownership',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Make ${member.name} the new owner of "${_group!.name}"?',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<GroupChatProvider>()
                  .transferOwnership(
                    groupId: widget.groupId,
                    newOwnerId: member.id,
                  );
              if (mounted) {
                if (success) {
                  _loadGroupDetails();
                } else {
                  final err = context.read<GroupChatProvider>().errorMessage;
                  _showError(err ?? 'Failed to transfer ownership');
                }
              }
            },
            child: const Text('Transfer',
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(GroupMemberModel member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Remove Member',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Remove ${member.name} from the group?',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<GroupChatProvider>().removeMembers(
                    groupId: widget.groupId,
                    userIds: [member.id],
                  );
              if (mounted) {
                if (success) {
                  _loadGroupDetails();
                } else {
                  final err = context.read<GroupChatProvider>().errorMessage;
                  _showError(err ?? 'Failed to remove member');
                }
              }
            },
            child:
                const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Leave Group',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          _isOwner
              ? 'You are the owner. Please transfer ownership before leaving.'
              : 'Are you sure you want to leave "${_group!.name}"?',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.grey)),
          ),
          if (_isOwner)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showTransferOwnershipSheet();
              },
              child: const Text('Transfer Ownership',
                  style: TextStyle(color: Colors.orange)),
            )
          else
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await context
                    .read<GroupChatProvider>()
                    .leaveGroup(widget.groupId);
                if (mounted) {
                  if (success) {
                    // Delay to let Stream SDK widgets fully clean up
                    // before popping to avoid GlobalKey / lifecycle errors
                    Future.microtask(() {
                      if (mounted) {
                        Navigator.of(context, rootNavigator: true)
                            .popUntil((route) => route.isFirst || 
                                route.settings.name == '/chat' ||
                                !route.settings.name.toString().contains('group'));
                      }
                    });
                  } else {
                    final err = context.read<GroupChatProvider>().errorMessage;
                    _showError(err ?? 'Failed to leave group');
                  }
                }
              },
              child: const Text('Leave',
                  style: TextStyle(color: Colors.orange)),
            ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Delete Group',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Permanently delete "${_group!.name}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<GroupChatProvider>()
                  .deleteGroup(widget.groupId);
              if (mounted) {
                if (success) {
                  Future.microtask(() {
                    if (mounted) {
                      Navigator.of(context, rootNavigator: true)
                          .popUntil((route) => route.isFirst ||
                              route.settings.name == '/chat' ||
                              !route.settings.name.toString().contains('group'));
                    }
                  });
                } else {
                  final err = context.read<GroupChatProvider>().errorMessage;
                  _showError(err ?? 'Failed to delete group');
                }
              }
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:stream_chat_flutter/stream_chat_flutter.dart';
// import 'package:lockedin_frontend/models/chat/group_model.dart';
// import 'package:lockedin_frontend/models/user/follow_user_model.dart';
// import 'package:lockedin_frontend/provider/auth_provider.dart';
// import 'package:lockedin_frontend/provider/group_chat_provider.dart';
// import 'package:lockedin_frontend/services/follow_service.dart';
// import 'package:lockedin_frontend/ui/theme/app_theme.dart';

// class GroupDetailsScreen extends StatefulWidget {
//   final String groupId;
//   final Channel channel;

//   const GroupDetailsScreen({
//     super.key,
//     required this.groupId,
//     required this.channel,
//   });

//   @override
//   State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
// }

// class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
//   GroupModel? _group;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadGroupDetails();
//   }

//   Future<void> _loadGroupDetails() async {
//     setState(() => _isLoading = true);
//     final provider = context.read<GroupChatProvider>();
//     final group = await provider.getGroupDetails(widget.groupId);
//     if (mounted) {
//       setState(() {
//         _group = group;
//         _isLoading = false;
//       });
//     }
//   }

//   bool get _isOwner {
//     final currentUserId =
//         context.read<GroupChatProvider>().streamClient.state.currentUser?.id;
//     if (currentUserId == null || _group == null) return false;
//     return _group!.ownerId.toString() == currentUserId;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.background,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: const Text(
//           'Group Info',
//           style: TextStyle(
//             color: AppColors.textPrimary,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _group == null
//               ? const Center(child: Text('Failed to load group'))
//               : _buildBody(context),
//     );
//   }

//   Widget _buildBody(BuildContext context) {
//     return ListView(
//       children: [
//         _buildGroupHeader(),
//         const SizedBox(height: 8),

//         if (_isOwner) ...[
//           _buildRenameButton(),
//           const Divider(),
//         ],

//         _buildMembersSection(),
//         const Divider(),

//         if (_isOwner) ...[
//           _buildAddMembersButton(),
//           const Divider(),
//           _buildTransferOwnershipButton(),
//           const Divider(),
//         ],

//         _buildLeaveButton(),
//         if (_isOwner) _buildDeleteButton(),
//         const SizedBox(height: 32),
//       ],
//     );
//   }

//   Widget _buildGroupHeader() {
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           CircleAvatar(
//             radius: 40,
//             backgroundColor: AppColors.primary,
//             child: Text(
//               _group!.name.isNotEmpty ? _group!.name[0].toUpperCase() : 'G',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             _group!.name,
//             style: const TextStyle(
//               color: AppColors.textPrimary,
//               fontWeight: FontWeight.bold,
//               fontSize: 20,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             '${_group!.memberCount} members',
//             style: const TextStyle(color: AppColors.grey, fontSize: 14),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRenameButton() {
//     return ListTile(
//       leading: const Icon(Icons.edit, color: AppColors.primary),
//       title: const Text('Rename Group',
//           style: TextStyle(color: AppColors.textPrimary)),
//       onTap: () => _showRenameDialog(),
//     );
//   }

//   Widget _buildMembersSection() {
//     final currentUserId =
//         context.read<GroupChatProvider>().streamClient.state.currentUser?.id;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
//           child: Text(
//             'Members (${_group!.members.length})',
//             style: const TextStyle(
//               color: AppColors.grey,
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//         ..._group!.members.map((member) {
//           final isOwner = member.id == _group!.ownerId.toString();
//           final isMe = member.id == currentUserId;

//           return ListTile(
//             leading: CircleAvatar(
//               backgroundColor: AppColors.accent,
//               backgroundImage: member.avatar != null
//                   ? NetworkImage(member.avatar!)
//                   : null,
//               child: member.avatar == null
//                   ? Text(member.name[0].toUpperCase(),
//                       style: const TextStyle(color: AppColors.primary))
//                   : null,
//             ),
//             title: Text(
//               '${member.name}${isMe ? ' (You)' : ''}',
//               style: const TextStyle(
//                   color: AppColors.textPrimary, fontWeight: FontWeight.w500),
//             ),
//             subtitle: isOwner
//                 ? const Text('Owner',
//                     style:
//                         TextStyle(color: AppColors.primary, fontSize: 12))
//                 : null,
//             trailing: _isOwner && !isMe
//                 ? IconButton(
//                     icon: const Icon(Icons.remove_circle_outline,
//                         color: Colors.red),
//                     onPressed: () => _confirmRemoveMember(member),
//                   )
//                 : null,
//           );
//         }),
//       ],
//     );
//   }

//   Widget _buildAddMembersButton() {
//     return ListTile(
//       leading: const Icon(Icons.person_add, color: AppColors.primary),
//       title: const Text('Add Members',
//           style: TextStyle(color: AppColors.textPrimary)),
//       onTap: () => _showAddMembersSheet(),
//     );
//   }

//   Widget _buildTransferOwnershipButton() {
//     return ListTile(
//       leading: const Icon(Icons.swap_horiz, color: Colors.orange),
//       title: const Text('Transfer Ownership',
//           style: TextStyle(color: Colors.orange)),
//       onTap: () => _showTransferOwnershipSheet(),
//     );
//   }

//   Widget _buildLeaveButton() {
//     return ListTile(
//       leading: const Icon(Icons.exit_to_app, color: Colors.orange),
//       title: const Text('Leave Group',
//           style: TextStyle(color: Colors.orange)),
//       onTap: () => _confirmLeave(),
//     );
//   }

//   Widget _buildDeleteButton() {
//     return ListTile(
//       leading: const Icon(Icons.delete_forever, color: Colors.red),
//       title: const Text('Delete Group', style: TextStyle(color: Colors.red)),
//       onTap: () => _confirmDelete(),
//     );
//   }

//   // ── Dialogs & Sheets ─────────────────────────────────────

//   void _showError(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 5),
//       ),
//     );
//   }

//   void _showRenameDialog() {
//     final controller = TextEditingController(text: _group!.name);
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: AppColors.background,
//         title: const Text('Rename Group',
//             style: TextStyle(color: AppColors.textPrimary)),
//         content: TextField(
//           controller: controller,
//           autofocus: true,
//           style: const TextStyle(color: AppColors.textPrimary),
//           decoration: InputDecoration(
//             hintText: 'Group name',
//             filled: true,
//             fillColor: AppColors.backgroundBox,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel',
//                 style: TextStyle(color: AppColors.grey)),
//           ),
//           TextButton(
//             onPressed: () async {
//               final name = controller.text.trim();
//               if (name.isEmpty) return;
//               Navigator.pop(ctx);
//               final success =
//                   await context.read<GroupChatProvider>().renameGroup(
//                         groupId: widget.groupId,
//                         name: name,
//                       );
//               if (success && mounted) _loadGroupDetails();
//             },
//             child: const Text('Rename',
//                 style: TextStyle(color: AppColors.primary)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showAddMembersSheet() {
//     final existingIds = _group!.members.map((m) => m.id).toSet();
//     final Set<String> selected = {};

//     Future<List<FollowUser>> loadAvailable() async {
//       final auth = context.read<AuthProvider>();
//       final service = FollowService(getAuthToken: () async => auth.token);
//       final results = await Future.wait([
//         service.getFollowers(),
//         service.getFollowing(),
//       ]);
//       final followerIds = results[0].map((u) => u.id).toSet();
//       final mutuals =
//           results[1].where((u) => followerIds.contains(u.id)).toList();
//       return mutuals.where((u) => !existingIds.contains(u.id)).toList();
//     }

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: AppColors.background,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) => StatefulBuilder(
//         builder: (ctx, setSheetState) => DraggableScrollableSheet(
//           initialChildSize: 0.6,
//           maxChildSize: 0.9,
//           minChildSize: 0.4,
//           expand: false,
//           builder: (_, scrollController) => Column(
//             children: [
//               const SizedBox(height: 12),
//               Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: AppColors.grey,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text('Add Members',
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                             color: AppColors.textPrimary)),
//                     TextButton(
//                       onPressed: selected.isEmpty
//                           ? null
//                           : () async {
//                               Navigator.pop(ctx);
//                               await context
//                                   .read<GroupChatProvider>()
//                                   .addMembers(
//                                     groupId: widget.groupId,
//                                     userIds: selected.toList(),
//                                   );
//                               _loadGroupDetails();
//                             },
//                       child: Text(
//                         'Add (${selected.length})',
//                         style: TextStyle(
//                           color: selected.isEmpty
//                               ? AppColors.grey
//                               : AppColors.primary,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: FutureBuilder<List<FollowUser>>(
//                   future: loadAvailable(),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }
//                     if (snapshot.hasError) {
//                       return const Center(
//                           child: Text('Failed to load contacts',
//                               style: TextStyle(color: AppColors.grey)));
//                     }
//                     final available = snapshot.data ?? [];
//                     if (available.isEmpty) {
//                       return const Center(
//                           child: Padding(
//                         padding: EdgeInsets.all(24),
//                         child: Text('No mutual connections to add',
//                             style: TextStyle(color: AppColors.grey)),
//                       ));
//                     }
//                     return ListView.builder(
//                       controller: scrollController,
//                       itemCount: available.length,
//                       itemBuilder: (_, i) {
//                         final user = available[i];
//                         final isSelected = selected.contains(user.id);
//                         final displayName = user.displayName.isNotEmpty
//                             ? user.displayName
//                             : user.username;
//                         return ListTile(
//                           onTap: () => setSheetState(() {
//                             isSelected
//                                 ? selected.remove(user.id)
//                                 : selected.add(user.id);
//                           }),
//                           leading: CircleAvatar(
//                             backgroundColor: AppColors.accent,
//                             backgroundImage: user.avatar.isNotEmpty
//                                 ? NetworkImage(user.avatar)
//                                 : null,
//                             child: user.avatar.isEmpty
//                                 ? Text(displayName[0].toUpperCase(),
//                                     style: const TextStyle(
//                                         color: AppColors.primary))
//                                 : null,
//                           ),
//                           title: Text(displayName,
//                               style: const TextStyle(
//                                   color: AppColors.textPrimary)),
//                           subtitle: Text('@${user.username}',
//                               style: const TextStyle(
//                                   color: AppColors.grey, fontSize: 12)),
//                           trailing: AnimatedContainer(
//                             duration: const Duration(milliseconds: 150),
//                             width: 26,
//                             height: 26,
//                             decoration: BoxDecoration(
//                               color: isSelected
//                                   ? AppColors.primary
//                                   : Colors.transparent,
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                   color: isSelected
//                                       ? AppColors.primary
//                                       : AppColors.grey),
//                             ),
//                             child: isSelected
//                                 ? const Icon(Icons.check,
//                                     color: Colors.white, size: 16)
//                                 : null,
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showTransferOwnershipSheet() {
//     final currentUserId =
//         context.read<GroupChatProvider>().streamClient.state.currentUser?.id;
//     final candidates =
//         _group!.members.where((m) => m.id != currentUserId).toList();

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: AppColors.background,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) => DraggableScrollableSheet(
//         initialChildSize: 0.5,
//         maxChildSize: 0.85,
//         minChildSize: 0.3,
//         expand: false,
//         builder: (_, scrollController) => Column(
//           children: [
//             const SizedBox(height: 12),
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: AppColors.grey,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const Padding(
//               padding: EdgeInsets.all(16),
//               child: Text(
//                 'Transfer Ownership',
//                 style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                     color: AppColors.textPrimary),
//               ),
//             ),
//             const Padding(
//               padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
//               child: Text(
//                 'Select a member to become the new owner. You will become a regular member.',
//                 style: TextStyle(color: AppColors.grey, fontSize: 13),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             if (candidates.isEmpty)
//               const Expanded(
//                 child: Center(
//                   child: Text('No other members to transfer to',
//                       style: TextStyle(color: AppColors.grey)),
//                 ),
//               )
//             else
//               Expanded(
//                 child: ListView.builder(
//                   controller: scrollController,
//                   itemCount: candidates.length,
//                   itemBuilder: (_, i) {
//                     final member = candidates[i];
//                     return ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: AppColors.accent,
//                         backgroundImage: member.avatar != null
//                             ? NetworkImage(member.avatar!)
//                             : null,
//                         child: member.avatar == null
//                             ? Text(member.name[0].toUpperCase(),
//                                 style: const TextStyle(
//                                     color: AppColors.primary))
//                             : null,
//                       ),
//                       title: Text(member.name,
//                           style:
//                               const TextStyle(color: AppColors.textPrimary)),
//                       trailing: const Icon(Icons.arrow_forward_ios,
//                           size: 14, color: AppColors.grey),
//                       onTap: () {
//                         Navigator.pop(ctx);
//                         _confirmTransfer(member);
//                       },
//                     );
//                   },
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _confirmTransfer(GroupMemberModel member) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: AppColors.background,
//         title: const Text('Transfer Ownership',
//             style: TextStyle(color: AppColors.textPrimary)),
//         content: Text(
//           'Make ${member.name} the new owner of "${_group!.name}"?',
//           style: const TextStyle(color: AppColors.textPrimary),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel',
//                 style: TextStyle(color: AppColors.grey)),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(ctx);
//               final success = await context
//                   .read<GroupChatProvider>()
//                   .transferOwnership(
//                     groupId: widget.groupId,
//                     newOwnerId: member.id,
//                   );
//               if (mounted) {
//                 if (success) {
//                   _loadGroupDetails();
//                 } else {
//                   final err = context.read<GroupChatProvider>().errorMessage;
//                   _showError(err ?? 'Failed to transfer ownership');
//                 }
//               }
//             },
//             child: const Text('Transfer',
//                 style: TextStyle(color: Colors.orange)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _confirmRemoveMember(GroupMemberModel member) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: AppColors.background,
//         title: const Text('Remove Member',
//             style: TextStyle(color: AppColors.textPrimary)),
//         content: Text(
//           'Remove ${member.name} from the group?',
//           style: const TextStyle(color: AppColors.textPrimary),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel',
//                 style: TextStyle(color: AppColors.grey)),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(ctx);
//               final success = await context.read<GroupChatProvider>().removeMembers(
//                     groupId: widget.groupId,
//                     userIds: [member.id],
//                   );
//               if (mounted) {
//                 if (success) {
//                   _loadGroupDetails();
//                 } else {
//                   final err = context.read<GroupChatProvider>().errorMessage;
//                   _showError(err ?? 'Failed to remove member');
//                 }
//               }
//             },
//             child:
//                 const Text('Remove', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _confirmLeave() {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: AppColors.background,
//         title: const Text('Leave Group',
//             style: TextStyle(color: AppColors.textPrimary)),
//         content: Text(
//           _isOwner
//               ? 'You are the owner. Please transfer ownership before leaving.'
//               : 'Are you sure you want to leave "${_group!.name}"?',
//           style: const TextStyle(color: AppColors.textPrimary),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel',
//                 style: TextStyle(color: AppColors.grey)),
//           ),
//           if (_isOwner)
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(ctx);
//                 _showTransferOwnershipSheet();
//               },
//               child: const Text('Transfer Ownership',
//                   style: TextStyle(color: Colors.orange)),
//             )
//           else
//             TextButton(
//               onPressed: () async {
//                 Navigator.pop(ctx);
//                 final success = await context
//                     .read<GroupChatProvider>()
//                     .leaveGroup(widget.groupId);
//                 if (mounted) {
//                   if (success) {
//                     Navigator.of(context)
//                       ..pop()
//                       ..pop();
//                   } else {
//                     final err = context.read<GroupChatProvider>().errorMessage;
//                     _showError(err ?? 'Failed to leave group');
//                   }
//                 }
//               },
//               child: const Text('Leave',
//                   style: TextStyle(color: Colors.orange)),
//             ),
//         ],
//       ),
//     );
//   }

//   void _confirmDelete() {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: AppColors.background,
//         title: const Text('Delete Group',
//             style: TextStyle(color: AppColors.textPrimary)),
//         content: Text(
//           'Permanently delete "${_group!.name}"? This cannot be undone.',
//           style: const TextStyle(color: AppColors.textPrimary),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text('Cancel',
//                 style: TextStyle(color: AppColors.grey)),
//           ),
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(ctx);
//               final success = await context
//                   .read<GroupChatProvider>()
//                   .deleteGroup(widget.groupId);
//               if (mounted) {
//                 if (success) {
//                   Navigator.of(context)
//                     ..pop()
//                     ..pop();
//                 } else {
//                   final err = context.read<GroupChatProvider>().errorMessage;
//                   _showError(err ?? 'Failed to delete group');
//                 }
//               }
//             },
//             child:
//                 const Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
// }



// // import 'package:flutter/material.dart';
// // import 'package:provider/provider.dart';
// // import 'package:stream_chat_flutter/stream_chat_flutter.dart';
// // import 'package:lockedin_frontend/models/chat/group_model.dart';
// // import 'package:lockedin_frontend/models/user/follow_user_model.dart';
// // import 'package:lockedin_frontend/provider/auth_provider.dart';
// // import 'package:lockedin_frontend/provider/group_chat_provider.dart';
// // import 'package:lockedin_frontend/services/follow_service.dart';
// // import 'package:lockedin_frontend/ui/theme/app_theme.dart';

// // class GroupDetailsScreen extends StatefulWidget {
// //   final String groupId;
// //   final Channel channel;

// //   const GroupDetailsScreen({
// //     super.key,
// //     required this.groupId,
// //     required this.channel,
// //   });

// //   @override
// //   State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
// // }

// // class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
// //   GroupModel? _group;
// //   bool _isLoading = true;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadGroupDetails();
// //   }

// //   Future<void> _loadGroupDetails() async {
// //     setState(() => _isLoading = true);
// //     final provider = context.read<GroupChatProvider>();
// //     final group = await provider.getGroupDetails(widget.groupId);
// //     if (mounted) {
// //       setState(() {
// //         _group = group;
// //         _isLoading = false;
// //       });
// //     }
// //   }

// //   bool get _isOwner {
// //     final currentUserId =
// //         context.read<GroupChatProvider>().streamClient.state.currentUser?.id;
// //     return _group?.ownerId == currentUserId;
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: AppColors.background,
// //       appBar: AppBar(
// //         backgroundColor: AppColors.background,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
// //           onPressed: () => Navigator.of(context).pop(),
// //         ),
// //         title: const Text(
// //           'Group Info',
// //           style: TextStyle(
// //             color: AppColors.textPrimary,
// //             fontWeight: FontWeight.bold,
// //             fontSize: 20,
// //           ),
// //         ),
// //         centerTitle: true,
// //       ),
// //       body: _isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : _group == null
// //               ? const Center(child: Text('Failed to load group'))
// //               : _buildBody(context),
// //     );
// //   }

// //   Widget _buildBody(BuildContext context) {
// //     return ListView(
// //       children: [
// //         // Group avatar + name
// //         _buildGroupHeader(),
// //         const SizedBox(height: 8),

// //         // Rename (owner only)
// //         if (_isOwner) _buildRenameButton(),

// //         const Divider(),

// //         // Members section
// //         _buildMembersSection(),

// //         const Divider(),

// //         // Add members (owner only)
// //         if (_isOwner) _buildAddMembersButton(),

// //         const Divider(),

// //         // Leave group
// //         _buildLeaveButton(),

// //         // Delete group (owner only)
// //         if (_isOwner) _buildDeleteButton(),

// //         const SizedBox(height: 32),
// //       ],
// //     );
// //   }

// //   Widget _buildGroupHeader() {
// //     return Padding(
// //       padding: const EdgeInsets.all(24),
// //       child: Column(
// //         children: [
// //           CircleAvatar(
// //             radius: 40,
// //             backgroundColor: AppColors.primary,
// //             child: Text(
// //               _group!.name.isNotEmpty ? _group!.name[0].toUpperCase() : 'G',
// //               style: const TextStyle(
// //                 color: Colors.white,
// //                 fontSize: 32,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //           ),
// //           const SizedBox(height: 12),
// //           Text(
// //             _group!.name,
// //             style: const TextStyle(
// //               color: AppColors.textPrimary,
// //               fontWeight: FontWeight.bold,
// //               fontSize: 20,
// //             ),
// //           ),
// //           const SizedBox(height: 4),
// //           Text(
// //             '${_group!.memberCount} members',
// //             style: const TextStyle(color: AppColors.grey, fontSize: 14),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildRenameButton() {
// //     return ListTile(
// //       leading: const Icon(Icons.edit, color: AppColors.primary),
// //       title: const Text(
// //         'Rename Group',
// //         style: TextStyle(color: AppColors.textPrimary),
// //       ),
// //       onTap: () => _showRenameDialog(),
// //     );
// //   }

// //   Widget _buildMembersSection() {
// //     final currentUserId =
// //         context.read<GroupChatProvider>().streamClient.state.currentUser?.id;

// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
// //           child: Text(
// //             'Members (${_group!.members.length})',
// //             style: const TextStyle(
// //               color: AppColors.grey,
// //               fontSize: 13,
// //               fontWeight: FontWeight.w600,
// //             ),
// //           ),
// //         ),
// //         ..._group!.members.map((member) {
// //           final isOwner = member.id == _group!.ownerId;
// //           final isMe = member.id == currentUserId;

// //           return ListTile(
// //             leading: CircleAvatar(
// //               backgroundColor: AppColors.accent,
// //               backgroundImage: member.avatar != null
// //                   ? NetworkImage(member.avatar!)
// //                   : null,
// //               child: member.avatar == null
// //                   ? Text(
// //                       member.name[0].toUpperCase(),
// //                       style: const TextStyle(color: AppColors.primary),
// //                     )
// //                   : null,
// //             ),
// //             title: Text(
// //               '${member.name}${isMe ? ' (You)' : ''}',
// //               style: const TextStyle(
// //                 color: AppColors.textPrimary,
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //             subtitle: isOwner
// //                 ? const Text(
// //                     'Owner',
// //                     style: TextStyle(
// //                       color: AppColors.primary,
// //                       fontSize: 12,
// //                     ),
// //                   )
// //                 : null,
// //             trailing: _isOwner && !isMe
// //                 ? IconButton(
// //                     icon: const Icon(Icons.remove_circle_outline,
// //                         color: Colors.red),
// //                     onPressed: () => _confirmRemoveMember(member),
// //                   )
// //                 : null,
// //           );
// //         }),
// //       ],
// //     );
// //   }

// //   Widget _buildAddMembersButton() {
// //     return ListTile(
// //       leading: const Icon(Icons.person_add, color: AppColors.primary),
// //       title: const Text(
// //         'Add Members',
// //         style: TextStyle(color: AppColors.textPrimary),
// //       ),
// //       onTap: () => _showAddMembersSheet(),
// //     );
// //   }

// //   Widget _buildLeaveButton() {
// //     return ListTile(
// //       leading: const Icon(Icons.exit_to_app, color: Colors.orange),
// //       title: const Text(
// //         'Leave Group',
// //         style: TextStyle(color: Colors.orange),
// //       ),
// //       onTap: () => _confirmLeave(),
// //     );
// //   }

// //   Widget _buildDeleteButton() {
// //     return ListTile(
// //       leading: const Icon(Icons.delete_forever, color: Colors.red),
// //       title: const Text(
// //         'Delete Group',
// //         style: TextStyle(color: Colors.red),
// //       ),
// //       onTap: () => _confirmDelete(),
// //     );
// //   }

// //   // ── Dialogs ──────────────────────────────────────────────

// //   void _showRenameDialog() {
// //     final controller = TextEditingController(text: _group!.name);
// //     showDialog(
// //       context: context,
// //       builder: (ctx) => AlertDialog(
// //         backgroundColor: AppColors.background,
// //         title: const Text('Rename Group',
// //             style: TextStyle(color: AppColors.textPrimary)),
// //         content: TextField(
// //           controller: controller,
// //           style: const TextStyle(color: AppColors.textPrimary),
// //           decoration: InputDecoration(
// //             hintText: 'Group name',
// //             filled: true,
// //             fillColor: AppColors.backgroundBox,
// //             border: OutlineInputBorder(
// //               borderRadius: BorderRadius.circular(12),
// //               borderSide: BorderSide.none,
// //             ),
// //           ),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(ctx),
// //             child: const Text('Cancel',
// //                 style: TextStyle(color: AppColors.grey)),
// //           ),
// //           TextButton(
// //             onPressed: () async {
// //               Navigator.pop(ctx);
// //               final name = controller.text.trim();
// //               if (name.isEmpty) return;
// //               final success = await context.read<GroupChatProvider>().renameGroup(
// //                     groupId: widget.groupId,
// //                     name: name,
// //                   );
// //               if (success) _loadGroupDetails();
// //             },
// //             child: const Text('Rename',
// //                 style: TextStyle(color: AppColors.primary)),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _showAddMembersSheet() {
// //     final existingIds = _group!.members.map((m) => m.id).toSet();
// //     final Set<String> selected = {};

// //     // Load mutual follows inside the sheet
// //     Future<List<FollowUser>> loadAvailable() async {
// //       final auth = context.read<AuthProvider>();
// //       final service = FollowService(getAuthToken: () async => auth.token);
// //       final results = await Future.wait([
// //         service.getFollowers(),
// //         service.getFollowing(),
// //       ]);
// //       final followerIds = results[0].map((u) => u.id).toSet();
// //       final mutuals =
// //           results[1].where((u) => followerIds.contains(u.id)).toList();
// //       // Filter out people already in the group
// //       return mutuals.where((u) => !existingIds.contains(u.id)).toList();
// //     }

// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: AppColors.background,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder: (ctx) => StatefulBuilder(
// //         builder: (ctx, setSheetState) => DraggableScrollableSheet(
// //           initialChildSize: 0.6,
// //           maxChildSize: 0.9,
// //           minChildSize: 0.4,
// //           expand: false,
// //           builder: (_, scrollController) => Column(
// //             children: [
// //               const SizedBox(height: 12),
// //               Container(
// //                 width: 40,
// //                 height: 4,
// //                 decoration: BoxDecoration(
// //                   color: AppColors.grey,
// //                   borderRadius: BorderRadius.circular(2),
// //                 ),
// //               ),
// //               Padding(
// //                 padding: const EdgeInsets.all(16),
// //                 child: Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     const Text(
// //                       'Add Members',
// //                       style: TextStyle(
// //                         fontWeight: FontWeight.bold,
// //                         fontSize: 18,
// //                         color: AppColors.textPrimary,
// //                       ),
// //                     ),
// //                     TextButton(
// //                       onPressed: selected.isEmpty
// //                           ? null
// //                           : () async {
// //                               Navigator.pop(ctx);
// //                               await context
// //                                   .read<GroupChatProvider>()
// //                                   .addMembers(
// //                                     groupId: widget.groupId,
// //                                     userIds: selected.toList(),
// //                                   );
// //                               _loadGroupDetails();
// //                             },
// //                       child: Text(
// //                         'Add (${selected.length})',
// //                         style: TextStyle(
// //                           color: selected.isEmpty
// //                               ? AppColors.grey
// //                               : AppColors.primary,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //               Expanded(
// //                 child: FutureBuilder<List<FollowUser>>(
// //                   future: loadAvailable(),
// //                   builder: (context, snapshot) {
// //                     if (snapshot.connectionState == ConnectionState.waiting) {
// //                       return const Center(child: CircularProgressIndicator());
// //                     }
// //                     if (snapshot.hasError) {
// //                       return Center(
// //                         child: Text(
// //                           'Failed to load contacts',
// //                           style: const TextStyle(color: AppColors.grey),
// //                         ),
// //                       );
// //                     }
// //                     final available = snapshot.data ?? [];
// //                     if (available.isEmpty) {
// //                       return const Center(
// //                         child: Padding(
// //                           padding: EdgeInsets.all(24),
// //                           child: Text(
// //                             'No mutual connections to add',
// //                             style: TextStyle(color: AppColors.grey),
// //                           ),
// //                         ),
// //                       );
// //                     }
// //                     return ListView.builder(
// //                       controller: scrollController,
// //                       itemCount: available.length,
// //                       itemBuilder: (_, i) {
// //                         final user = available[i];
// //                         final isSelected = selected.contains(user.id);
// //                         final displayName = user.displayName.isNotEmpty
// //                             ? user.displayName
// //                             : user.username;
// //                         return ListTile(
// //                           onTap: () {
// //                             setSheetState(() {
// //                               if (isSelected) {
// //                                 selected.remove(user.id);
// //                               } else {
// //                                 selected.add(user.id);
// //                               }
// //                             });
// //                           },
// //                           leading: CircleAvatar(
// //                             backgroundColor: AppColors.accent,
// //                             backgroundImage: user.avatar.isNotEmpty
// //                                 ? NetworkImage(user.avatar)
// //                                 : null,
// //                             child: user.avatar.isEmpty
// //                                 ? Text(
// //                                     displayName[0].toUpperCase(),
// //                                     style: const TextStyle(
// //                                         color: AppColors.primary),
// //                                   )
// //                                 : null,
// //                           ),
// //                           title: Text(
// //                             displayName,
// //                             style:
// //                                 const TextStyle(color: AppColors.textPrimary),
// //                           ),
// //                           subtitle: Text(
// //                             '@${user.username}',
// //                             style: const TextStyle(
// //                                 color: AppColors.grey, fontSize: 12),
// //                           ),
// //                           trailing: AnimatedContainer(
// //                             duration: const Duration(milliseconds: 150),
// //                             width: 26,
// //                             height: 26,
// //                             decoration: BoxDecoration(
// //                               color: isSelected
// //                                   ? AppColors.primary
// //                                   : Colors.transparent,
// //                               shape: BoxShape.circle,
// //                               border: Border.all(
// //                                 color: isSelected
// //                                     ? AppColors.primary
// //                                     : AppColors.grey,
// //                               ),
// //                             ),
// //                             child: isSelected
// //                                 ? const Icon(Icons.check,
// //                                     color: Colors.white, size: 16)
// //                                 : null,
// //                           ),
// //                         );
// //                       },
// //                     );
// //                   },
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   void _confirmRemoveMember(GroupMemberModel member) {
// //     showDialog(
// //       context: context,
// //       builder: (ctx) => AlertDialog(
// //         backgroundColor: AppColors.background,
// //         title: const Text('Remove Member',
// //             style: TextStyle(color: AppColors.textPrimary)),
// //         content: Text(
// //           'Remove ${member.name} from the group?',
// //           style: const TextStyle(color: AppColors.textPrimary),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(ctx),
// //             child: const Text('Cancel',
// //                 style: TextStyle(color: AppColors.grey)),
// //           ),
// //           TextButton(
// //             onPressed: () async {
// //               Navigator.pop(ctx);
// //               await context.read<GroupChatProvider>().removeMembers(
// //                     groupId: widget.groupId,
// //                     userIds: [member.id],
// //                   );
// //               _loadGroupDetails();
// //             },
// //             child: const Text('Remove',
// //                 style: TextStyle(color: Colors.red)),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _confirmLeave() {
// //     showDialog(
// //       context: context,
// //       builder: (ctx) => AlertDialog(
// //         backgroundColor: AppColors.background,
// //         title: const Text('Leave Group',
// //             style: TextStyle(color: AppColors.textPrimary)),
// //         content: Text(
// //           _isOwner
// //               ? 'You are the owner. Transfer ownership before leaving.'
// //               : 'Are you sure you want to leave "${_group!.name}"?',
// //           style: const TextStyle(color: AppColors.textPrimary),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(ctx),
// //             child: const Text('Cancel',
// //                 style: TextStyle(color: AppColors.grey)),
// //           ),
// //           if (!_isOwner)
// //             TextButton(
// //               onPressed: () async {
// //                 Navigator.pop(ctx);
// //                 final success = await context
// //                     .read<GroupChatProvider>()
// //                     .leaveGroup(widget.groupId);
// //                 if (success && mounted) {
// //                   // Pop back to channel list
// //                   Navigator.of(context)
// //                     ..pop() // group details
// //                     ..pop(); // group channel
// //                 }
// //               },
// //               child: const Text('Leave',
// //                   style: TextStyle(color: Colors.orange)),
// //             ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _confirmDelete() {
// //     showDialog(
// //       context: context,
// //       builder: (ctx) => AlertDialog(
// //         backgroundColor: AppColors.background,
// //         title: const Text('Delete Group',
// //             style: TextStyle(color: AppColors.textPrimary)),
// //         content: Text(
// //           'Permanently delete "${_group!.name}"? This cannot be undone.',
// //           style: const TextStyle(color: AppColors.textPrimary),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(ctx),
// //             child: const Text('Cancel',
// //                 style: TextStyle(color: AppColors.grey)),
// //           ),
// //           TextButton(
// //             onPressed: () async {
// //               Navigator.pop(ctx);
// //               final success = await context
// //                   .read<GroupChatProvider>()
// //                   .deleteGroup(widget.groupId);
// //               if (success && mounted) {
// //                 Navigator.of(context)
// //                   ..pop() // group details
// //                   ..pop(); // group channel
// //               }
// //             },
// //             child: const Text('Delete',
// //                 style: TextStyle(color: Colors.red)),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // import 'package:flutter/material.dart';
// // // import 'package:provider/provider.dart';
// // // import 'package:stream_chat_flutter/stream_chat_flutter.dart';
// // // import 'package:lockedin_frontend/models/chat/group_model.dart';
// // // import 'package:lockedin_frontend/provider/group_chat_provider.dart';
// // // import 'package:lockedin_frontend/ui/theme/app_theme.dart';

// // // class GroupDetailsScreen extends StatefulWidget {
// // //   final String groupId;
// // //   final Channel channel;

// // //   const GroupDetailsScreen({
// // //     super.key,
// // //     required this.groupId,
// // //     required this.channel,
// // //   });

// // //   @override
// // //   State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
// // // }

// // // class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
// // //   GroupModel? _group;
// // //   bool _isLoading = true;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _loadGroupDetails();
// // //   }

// // //   Future<void> _loadGroupDetails() async {
// // //     setState(() => _isLoading = true);
// // //     final provider = context.read<GroupChatProvider>();
// // //     final group = await provider.getGroupDetails(widget.groupId);
// // //     if (mounted) {
// // //       setState(() {
// // //         _group = group;
// // //         _isLoading = false;
// // //       });
// // //     }
// // //   }

// // //   bool get _isOwner {
// // //     final currentUserId =
// // //         context.read<GroupChatProvider>().streamClient.state.currentUser?.id;
// // //     return _group?.ownerId == currentUserId;
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: AppColors.background,
// // //       appBar: AppBar(
// // //         backgroundColor: AppColors.background,
// // //         elevation: 0,
// // //         leading: IconButton(
// // //           icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
// // //           onPressed: () => Navigator.of(context).pop(),
// // //         ),
// // //         title: const Text(
// // //           'Group Info',
// // //           style: TextStyle(
// // //             color: AppColors.textPrimary,
// // //             fontWeight: FontWeight.bold,
// // //             fontSize: 20,
// // //           ),
// // //         ),
// // //         centerTitle: true,
// // //       ),
// // //       body: _isLoading
// // //           ? const Center(child: CircularProgressIndicator())
// // //           : _group == null
// // //               ? const Center(child: Text('Failed to load group'))
// // //               : _buildBody(context),
// // //     );
// // //   }

// // //   Widget _buildBody(BuildContext context) {
// // //     return ListView(
// // //       children: [
// // //         // Group avatar + name
// // //         _buildGroupHeader(),
// // //         const SizedBox(height: 8),

// // //         // Rename (owner only)
// // //         if (_isOwner) _buildRenameButton(),

// // //         const Divider(),

// // //         // Members section
// // //         _buildMembersSection(),

// // //         const Divider(),

// // //         // Add members (owner only)
// // //         if (_isOwner) _buildAddMembersButton(),

// // //         const Divider(),

// // //         // Leave group
// // //         _buildLeaveButton(),

// // //         // Delete group (owner only)
// // //         if (_isOwner) _buildDeleteButton(),

// // //         const SizedBox(height: 32),
// // //       ],
// // //     );
// // //   }

// // //   Widget _buildGroupHeader() {
// // //     return Padding(
// // //       padding: const EdgeInsets.all(24),
// // //       child: Column(
// // //         children: [
// // //           CircleAvatar(
// // //             radius: 40,
// // //             backgroundColor: AppColors.primary,
// // //             child: Text(
// // //               _group!.name.isNotEmpty ? _group!.name[0].toUpperCase() : 'G',
// // //               style: const TextStyle(
// // //                 color: Colors.white,
// // //                 fontSize: 32,
// // //                 fontWeight: FontWeight.bold,
// // //               ),
// // //             ),
// // //           ),
// // //           const SizedBox(height: 12),
// // //           Text(
// // //             _group!.name,
// // //             style: const TextStyle(
// // //               color: AppColors.textPrimary,
// // //               fontWeight: FontWeight.bold,
// // //               fontSize: 20,
// // //             ),
// // //           ),
// // //           const SizedBox(height: 4),
// // //           Text(
// // //             '${_group!.memberCount} members',
// // //             style: const TextStyle(color: AppColors.grey, fontSize: 14),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildRenameButton() {
// // //     return ListTile(
// // //       leading: const Icon(Icons.edit, color: AppColors.primary),
// // //       title: const Text(
// // //         'Rename Group',
// // //         style: TextStyle(color: AppColors.textPrimary),
// // //       ),
// // //       onTap: () => _showRenameDialog(),
// // //     );
// // //   }

// // //   Widget _buildMembersSection() {
// // //     final currentUserId =
// // //         context.read<GroupChatProvider>().streamClient.state.currentUser?.id;

// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Padding(
// // //           padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
// // //           child: Text(
// // //             'Members (${_group!.members.length})',
// // //             style: const TextStyle(
// // //               color: AppColors.grey,
// // //               fontSize: 13,
// // //               fontWeight: FontWeight.w600,
// // //             ),
// // //           ),
// // //         ),
// // //         ..._group!.members.map((member) {
// // //           final isOwner = member.id == _group!.ownerId;
// // //           final isMe = member.id == currentUserId;

// // //           return ListTile(
// // //             leading: CircleAvatar(
// // //               backgroundColor: AppColors.accent,
// // //               backgroundImage: member.avatar != null
// // //                   ? NetworkImage(member.avatar!)
// // //                   : null,
// // //               child: member.avatar == null
// // //                   ? Text(
// // //                       member.name[0].toUpperCase(),
// // //                       style: const TextStyle(color: AppColors.primary),
// // //                     )
// // //                   : null,
// // //             ),
// // //             title: Text(
// // //               '${member.name}${isMe ? ' (You)' : ''}',
// // //               style: const TextStyle(
// // //                 color: AppColors.textPrimary,
// // //                 fontWeight: FontWeight.w500,
// // //               ),
// // //             ),
// // //             subtitle: isOwner
// // //                 ? const Text(
// // //                     'Owner',
// // //                     style: TextStyle(
// // //                       color: AppColors.primary,
// // //                       fontSize: 12,
// // //                     ),
// // //                   )
// // //                 : null,
// // //             trailing: _isOwner && !isMe
// // //                 ? IconButton(
// // //                     icon: const Icon(Icons.remove_circle_outline,
// // //                         color: Colors.red),
// // //                     onPressed: () => _confirmRemoveMember(member),
// // //                   )
// // //                 : null,
// // //           );
// // //         }),
// // //       ],
// // //     );
// // //   }

// // //   Widget _buildAddMembersButton() {
// // //     return ListTile(
// // //       leading: const Icon(Icons.person_add, color: AppColors.primary),
// // //       title: const Text(
// // //         'Add Members',
// // //         style: TextStyle(color: AppColors.textPrimary),
// // //       ),
// // //       onTap: () => _showAddMembersSheet(),
// // //     );
// // //   }

// // //   Widget _buildLeaveButton() {
// // //     return ListTile(
// // //       leading: const Icon(Icons.exit_to_app, color: Colors.orange),
// // //       title: const Text(
// // //         'Leave Group',
// // //         style: TextStyle(color: Colors.orange),
// // //       ),
// // //       onTap: () => _confirmLeave(),
// // //     );
// // //   }

// // //   Widget _buildDeleteButton() {
// // //     return ListTile(
// // //       leading: const Icon(Icons.delete_forever, color: Colors.red),
// // //       title: const Text(
// // //         'Delete Group',
// // //         style: TextStyle(color: Colors.red),
// // //       ),
// // //       onTap: () => _confirmDelete(),
// // //     );
// // //   }

// // //   // ── Dialogs ──────────────────────────────────────────────

// // //   void _showRenameDialog() {
// // //     final controller = TextEditingController(text: _group!.name);
// // //     showDialog(
// // //       context: context,
// // //       builder: (ctx) => AlertDialog(
// // //         backgroundColor: AppColors.background,
// // //         title: const Text('Rename Group',
// // //             style: TextStyle(color: AppColors.textPrimary)),
// // //         content: TextField(
// // //           controller: controller,
// // //           style: const TextStyle(color: AppColors.textPrimary),
// // //           decoration: InputDecoration(
// // //             hintText: 'Group name',
// // //             filled: true,
// // //             fillColor: AppColors.backgroundBox,
// // //             border: OutlineInputBorder(
// // //               borderRadius: BorderRadius.circular(12),
// // //               borderSide: BorderSide.none,
// // //             ),
// // //           ),
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(ctx),
// // //             child: const Text('Cancel',
// // //                 style: TextStyle(color: AppColors.grey)),
// // //           ),
// // //           TextButton(
// // //             onPressed: () async {
// // //               Navigator.pop(ctx);
// // //               final name = controller.text.trim();
// // //               if (name.isEmpty) return;
// // //               final success = await context.read<GroupChatProvider>().renameGroup(
// // //                     groupId: widget.groupId,
// // //                     name: name,
// // //                   );
// // //               if (success) _loadGroupDetails();
// // //             },
// // //             child: const Text('Rename',
// // //                 style: TextStyle(color: AppColors.primary)),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   void _showAddMembersSheet() {
// // //     // TODO: Replace with real user search from follow API
// // //     final mockUsers = [
// // //       {'id': 'mock_user_1', 'name': 'Oun Mav',  'avatar': 'https://i.pravatar.cc/150?img=1'},
// // //       {'id': 'mock_user_2', 'name': 'userbjkd', 'avatar': 'https://i.pravatar.cc/150?img=2'},
// // //       {'id': 'mock_user_3', 'name': 'Plooch',   'avatar': 'https://i.pravatar.cc/150?img=3'},
// // //       {'id': 'mock_user_4', 'name': 'riku',     'avatar': 'https://i.pravatar.cc/150?img=4'},
// // //       {'id': 'mock_user_5', 'name': 'Zrong',    'avatar': 'https://i.pravatar.cc/150?img=5'},
// // //     ];

// // //     // Filter out existing members
// // //     final existingIds = _group!.members.map((m) => m.id).toSet();
// // //     final available = mockUsers.where((u) => !existingIds.contains(u['id'])).toList();

// // //     final Set<String> selected = {};

// // //     showModalBottomSheet(
// // //       context: context,
// // //       isScrollControlled: true,
// // //       backgroundColor: AppColors.background,
// // //       shape: const RoundedRectangleBorder(
// // //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// // //       ),
// // //       builder: (ctx) => StatefulBuilder(
// // //         builder: (ctx, setSheetState) => DraggableScrollableSheet(
// // //           initialChildSize: 0.6,
// // //           maxChildSize: 0.9,
// // //           minChildSize: 0.4,
// // //           expand: false,
// // //           builder: (_, scrollController) => Column(
// // //             children: [
// // //               const SizedBox(height: 12),
// // //               Container(
// // //                 width: 40,
// // //                 height: 4,
// // //                 decoration: BoxDecoration(
// // //                   color: AppColors.grey,
// // //                   borderRadius: BorderRadius.circular(2),
// // //                 ),
// // //               ),
// // //               Padding(
// // //                 padding: const EdgeInsets.all(16),
// // //                 child: Row(
// // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                   children: [
// // //                     const Text('Add Members',
// // //                         style: TextStyle(
// // //                             fontWeight: FontWeight.bold,
// // //                             fontSize: 18,
// // //                             color: AppColors.textPrimary)),
// // //                     TextButton(
// // //                       onPressed: selected.isEmpty
// // //                           ? null
// // //                           : () async {
// // //                               Navigator.pop(ctx);
// // //                               await context
// // //                                   .read<GroupChatProvider>()
// // //                                   .addMembers(
// // //                                     groupId: widget.groupId,
// // //                                     userIds: selected.toList(),
// // //                                   );
// // //                               _loadGroupDetails();
// // //                             },
// // //                       child: Text(
// // //                         'Add (${selected.length})',
// // //                         style: TextStyle(
// // //                           color: selected.isEmpty
// // //                               ? AppColors.grey
// // //                               : AppColors.primary,
// // //                           fontWeight: FontWeight.bold,
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //               Expanded(
// // //                 child: available.isEmpty
// // //                     ? const Center(
// // //                         child: Text('No users to add',
// // //                             style: TextStyle(color: AppColors.grey)))
// // //                     : ListView.builder(
// // //                         controller: scrollController,
// // //                         itemCount: available.length,
// // //                         itemBuilder: (_, i) {
// // //                           final user = available[i];
// // //                           final isSelected = selected.contains(user['id']);
// // //                           return ListTile(
// // //                             leading: CircleAvatar(
// // //                               backgroundImage:
// // //                                   NetworkImage(user['avatar']!),
// // //                             ),
// // //                             title: Text(user['name']!,
// // //                                 style: const TextStyle(
// // //                                     color: AppColors.textPrimary)),
// // //                             trailing: isSelected
// // //                                 ? Container(
// // //                                     width: 26,
// // //                                     height: 26,
// // //                                     decoration: const BoxDecoration(
// // //                                       color: AppColors.primary,
// // //                                       shape: BoxShape.circle,
// // //                                     ),
// // //                                     child: const Icon(Icons.check,
// // //                                         color: Colors.white, size: 16),
// // //                                   )
// // //                                 : Container(
// // //                                     width: 26,
// // //                                     height: 26,
// // //                                     decoration: BoxDecoration(
// // //                                       border: Border.all(
// // //                                           color: AppColors.grey),
// // //                                       shape: BoxShape.circle,
// // //                                     ),
// // //                                   ),
// // //                             onTap: () {
// // //                               setSheetState(() {
// // //                                 if (isSelected) {
// // //                                   selected.remove(user['id']);
// // //                                 } else {
// // //                                   selected.add(user['id']!);
// // //                                 }
// // //                               });
// // //                             },
// // //                           );
// // //                         },
// // //                       ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   void _confirmRemoveMember(GroupMemberModel member) {
// // //     showDialog(
// // //       context: context,
// // //       builder: (ctx) => AlertDialog(
// // //         backgroundColor: AppColors.background,
// // //         title: const Text('Remove Member',
// // //             style: TextStyle(color: AppColors.textPrimary)),
// // //         content: Text(
// // //           'Remove ${member.name} from the group?',
// // //           style: const TextStyle(color: AppColors.textPrimary),
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(ctx),
// // //             child: const Text('Cancel',
// // //                 style: TextStyle(color: AppColors.grey)),
// // //           ),
// // //           TextButton(
// // //             onPressed: () async {
// // //               Navigator.pop(ctx);
// // //               await context.read<GroupChatProvider>().removeMembers(
// // //                     groupId: widget.groupId,
// // //                     userIds: [member.id],
// // //                   );
// // //               _loadGroupDetails();
// // //             },
// // //             child: const Text('Remove',
// // //                 style: TextStyle(color: Colors.red)),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   void _confirmLeave() {
// // //     showDialog(
// // //       context: context,
// // //       builder: (ctx) => AlertDialog(
// // //         backgroundColor: AppColors.background,
// // //         title: const Text('Leave Group',
// // //             style: TextStyle(color: AppColors.textPrimary)),
// // //         content: Text(
// // //           _isOwner
// // //               ? 'You are the owner. Transfer ownership before leaving.'
// // //               : 'Are you sure you want to leave "${_group!.name}"?',
// // //           style: const TextStyle(color: AppColors.textPrimary),
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(ctx),
// // //             child: const Text('Cancel',
// // //                 style: TextStyle(color: AppColors.grey)),
// // //           ),
// // //           if (!_isOwner)
// // //             TextButton(
// // //               onPressed: () async {
// // //                 Navigator.pop(ctx);
// // //                 final success = await context
// // //                     .read<GroupChatProvider>()
// // //                     .leaveGroup(widget.groupId);
// // //                 if (success && mounted) {
// // //                   // Pop back to channel list
// // //                   Navigator.of(context)
// // //                     ..pop() // group details
// // //                     ..pop(); // group channel
// // //                 }
// // //               },
// // //               child: const Text('Leave',
// // //                   style: TextStyle(color: Colors.orange)),
// // //             ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   void _confirmDelete() {
// // //     showDialog(
// // //       context: context,
// // //       builder: (ctx) => AlertDialog(
// // //         backgroundColor: AppColors.background,
// // //         title: const Text('Delete Group',
// // //             style: TextStyle(color: AppColors.textPrimary)),
// // //         content: Text(
// // //           'Permanently delete "${_group!.name}"? This cannot be undone.',
// // //           style: const TextStyle(color: AppColors.textPrimary),
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(ctx),
// // //             child: const Text('Cancel',
// // //                 style: TextStyle(color: AppColors.grey)),
// // //           ),
// // //           TextButton(
// // //             onPressed: () async {
// // //               Navigator.pop(ctx);
// // //               final success = await context
// // //                   .read<GroupChatProvider>()
// // //                   .deleteGroup(widget.groupId);
// // //               if (success && mounted) {
// // //                 Navigator.of(context)
// // //                   ..pop() // group details
// // //                   ..pop(); // group channel
// // //               }
// // //             },
// // //             child: const Text('Delete',
// // //                 style: TextStyle(color: Colors.red)),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // // }