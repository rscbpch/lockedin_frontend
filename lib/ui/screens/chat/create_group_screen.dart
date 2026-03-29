import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/provider/group_chat_provider.dart';
import 'package:lockedin_frontend/models/user/follow_user_model.dart';
import 'package:lockedin_frontend/services/follow_service.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';
import 'package:lockedin_frontend/ui/screens/chat/widgets/stream_chat_theme.dart';
import 'group_channel_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false;

  // Mutual follows available to add
  List<FollowUser> _mutualFollows = [];
  bool _isLoadingFollows = true;
  String? _followsError;

  // Selected members (by user ID)
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadMutualFollows();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMutualFollows() async {
    setState(() {
      _isLoadingFollows = true;
      _followsError = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final service = FollowService(getAuthToken: () async => auth.token);

      // Fetch both lists and intersect to get mutuals
      final results = await Future.wait([
        service.getFollowers(),
        service.getFollowing(),
      ]);

      final followers = results[0];
      final following = results[1];

      // A mutual follow is someone who appears in both lists
      // FollowUser already has isMutual flag — use whichever has it set,
      // or fall back to intersecting the two lists by ID
      final followerIds = followers.map((u) => u.id).toSet();
      final mutuals = following.where((u) => followerIds.contains(u.id)).toList();

      if (mounted) {
        setState(() {
          _mutualFollows = mutuals;
          _isLoadingFollows = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _followsError = e.toString();
          _isLoadingFollows = false;
        });
      }
    }
  }

  void _toggleUser(String userId) {
    setState(() {
      if (_selectedIds.contains(userId)) {
        _selectedIds.remove(userId);
      } else {
        _selectedIds.add(userId);
      }
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final provider = context.read<GroupChatProvider>();
    final channel = await provider.createGroup(
      name: _nameController.text.trim(),
      memberIds: _selectedIds.toList(),
    );

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (channel != null) {
      Navigator.of(context).pop();
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => StreamChat(
            client: StreamChat.of(context).client,
            streamChatThemeData: StreamChatAppTheme.theme,
            child: StreamChannel(
              channel: channel,
              child: const GroupChannelScreen(),
            ),
          ),
        ),
      );
    } else {
      final msg = provider.errorMessage ?? 'Failed to create group';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
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
          'New Group',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Create',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Group name ──
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Group name',
                      hintStyle: const TextStyle(color: AppColors.grey),
                      filled: true,
                      fillColor: AppColors.backgroundBox,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          const Icon(Icons.group, color: AppColors.primary),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a group name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Section header ──
                  Row(
                    children: [
                      const Text(
                        'Add Members',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_selectedIds.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Select from people you mutually follow',
                    style: TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ── Mutual follows list ──
            Expanded(
              child: _buildFollowsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowsList() {
    if (_isLoadingFollows) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_followsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text(
              'Failed to load contacts',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadMutualFollows,
              child: const Text('Retry',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    if (_mutualFollows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No mutual connections yet.\nFollow people and wait for them to follow back.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _mutualFollows.length,
      itemBuilder: (context, index) {
        final user = _mutualFollows[index];
        final isSelected = _selectedIds.contains(user.id);

        return ListTile(
          onTap: () => _toggleUser(user.id),
          leading: CircleAvatar(
            backgroundColor: AppColors.accent,
            backgroundImage:
                user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
            child: user.avatar.isEmpty
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : user.username[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primary),
                  )
                : null,
          ),
          title: Text(
            user.displayName.isNotEmpty ? user.displayName : user.username,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '@${user.username}',
            style: const TextStyle(color: AppColors.grey, fontSize: 12),
          ),
          trailing: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.grey,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
        );
      },
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:stream_chat_flutter/stream_chat_flutter.dart';
// import 'package:lockedin_frontend/provider/chat_provider.dart';
// import 'package:lockedin_frontend/provider/group_chat_provider.dart';
// import 'package:lockedin_frontend/ui/theme/app_theme.dart';
// import 'package:lockedin_frontend/ui/screens/chat/widgets/stream_chat_theme.dart';
// import 'group_channel_screen.dart';

// class CreateGroupScreen extends StatefulWidget {
//   const CreateGroupScreen({super.key});

//   @override
//   State<CreateGroupScreen> createState() => _CreateGroupScreenState();
// }

// class _CreateGroupScreenState extends State<CreateGroupScreen> {
//   final _nameController = TextEditingController();
//   final _memberIdController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isCreating = false;

//   /// List of added member IDs (real backend/MongoDB user IDs)
//   final List<String> _memberIds = [];

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _memberIdController.dispose();
//     super.dispose();
//   }

//   void _addMember() {
//     final id = _memberIdController.text.trim();
//     if (id.isEmpty) return;
//     if (_memberIds.contains(id)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('User already added'), duration: Duration(seconds: 1)),
//       );
//       return;
//     }
//     setState(() => _memberIds.add(id));
//     _memberIdController.clear();
//   }

//   Future<void> _createGroup() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isCreating = true);

//     final provider = context.read<GroupChatProvider>();
//     final channel = await provider.createGroup(
//       name: _nameController.text.trim(),
//       memberIds: _memberIds,
//     );

//     if (!mounted) return;
//     setState(() => _isCreating = false);

//     if (channel != null) {
//       Navigator.of(context).pop(); // close create screen
//       Navigator.of(context, rootNavigator: true).push(
//         MaterialPageRoute(
//           builder: (_) => StreamChat(
//             client: StreamChat.of(context).client,
//             streamChatThemeData: StreamChatAppTheme.theme,
//             child: StreamChannel(
//               channel: channel,
//               child: const GroupChannelScreen(),
//             ),
//           ),
//         ),
//       );
//     } else {
//       final msg = provider.errorMessage ?? 'Failed to create group';
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(msg),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 5),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final myId = context.read<ChatProvider>().currentUserId ?? '(not connected)';

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
//           'New Group',
//           style: TextStyle(
//             color: AppColors.textPrimary,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         centerTitle: true,
//         actions: [
//           TextButton(
//             onPressed: _isCreating ? null : _createGroup,
//             child: _isCreating
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       color: AppColors.primary,
//                     ),
//                   )
//                 : const Text(
//                     'Create',
//                     style: TextStyle(
//                       color: AppColors.primary,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//           ),
//         ],
//       ),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             // ── Your user ID (for sharing with testers) ──
//             const Text(
//               '[DEV] Your user ID:',
//               style: TextStyle(fontSize: 12, color: AppColors.grey),
//             ),
//             const SizedBox(height: 4),
//             GestureDetector(
//               onTap: () {
//                 Clipboard.setData(ClipboardData(text: myId));
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('User ID copied!'),
//                     duration: Duration(seconds: 1),
//                   ),
//                 );
//               },
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: AppColors.backgroundBox,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: AppColors.grey.withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         myId,
//                         style: const TextStyle(
//                           fontSize: 12,
//                           fontFamily: 'monospace',
//                           color: AppColors.textPrimary,
//                         ),
//                       ),
//                     ),
//                     const Icon(Icons.copy, size: 16, color: AppColors.grey),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             // ── Group name ──
//             TextFormField(
//               controller: _nameController,
//               style: const TextStyle(color: AppColors.textPrimary),
//               decoration: InputDecoration(
//                 hintText: 'Group name',
//                 hintStyle: const TextStyle(color: AppColors.grey),
//                 filled: true,
//                 fillColor: AppColors.backgroundBox,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide.none,
//                 ),
//                 prefixIcon: const Icon(Icons.group, color: AppColors.primary),
//               ),
//               validator: (value) {
//                 if (value == null || value.trim().isEmpty) {
//                   return 'Please enter a group name';
//                 }
//                 return null;
//               },
//             ),

//             const SizedBox(height: 20),

//             // ── Add member by ID ──
//             const Text(
//               'Add Members by User ID',
//               style: TextStyle(
//                 color: AppColors.textPrimary,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 4),
//             const Text(
//               'Paste each member\'s user ID and tap Add',
//               style: TextStyle(fontSize: 12, color: AppColors.grey),
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _memberIdController,
//                     style: const TextStyle(color: AppColors.textPrimary),
//                     decoration: InputDecoration(
//                       hintText: 'Paste user ID here',
//                       hintStyle: const TextStyle(color: AppColors.grey),
//                       filled: true,
//                       fillColor: AppColors.backgroundBox,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 14,
//                         vertical: 12,
//                       ),
//                     ),
//                     onSubmitted: (_) => _addMember(),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: _addMember,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primary,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 14,
//                     ),
//                   ),
//                   child: const Text('Add', style: TextStyle(color: Colors.white)),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 16),

//             // ── Member count badge ──
//             Row(
//               children: [
//                 const Text(
//                   'Members',
//                   style: TextStyle(
//                     color: AppColors.textPrimary,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: AppColors.primary,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     '${_memberIds.length}',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),

//             // ── Added members list ──
//             if (_memberIds.isEmpty)
//               const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 24),
//                 child: Center(
//                   child: Text(
//                     'No members added yet',
//                     style: TextStyle(color: AppColors.grey),
//                   ),
//                 ),
//               )
//             else
//               ..._memberIds.asMap().entries.map((entry) {
//                 final index = entry.key;
//                 final id = entry.value;
//                 return Card(
//                   color: AppColors.backgroundBox,
//                   margin: const EdgeInsets.only(bottom: 8),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: AppColors.primary,
//                       child: Text(
//                         '${index + 1}',
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     title: Text(
//                       id,
//                       style: const TextStyle(
//                         color: AppColors.textPrimary,
//                         fontFamily: 'monospace',
//                         fontSize: 13,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     trailing: IconButton(
//                       icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
//                       onPressed: () => setState(() => _memberIds.remove(id)),
//                     ),
//                   ),
//                 );
//               }),
//           ],
//         ),
//       ),
//     );
//   }
// }