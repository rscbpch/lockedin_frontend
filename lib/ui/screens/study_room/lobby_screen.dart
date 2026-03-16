import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/widgets/actions/square_button.dart';
import 'package:provider/provider.dart';
import '../../../provider/study_room_provider.dart';
import '../../../models/study_room/study_room.dart';
import 'widgets/create_room_sheet.dart';
import 'widgets/error_banner.dart';
import 'meeting_screen.dart';
import '../../theme/app_theme.dart';
import '../../../provider/auth_provider.dart';
import '../../widgets/display/lockedin_appbar.dart';
import '../../widgets/inputs/search_bar_widget.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StudyRoomProvider? _studyRoomProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyRoomProvider>().startPolling();
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save reference here — safe to use context
    _studyRoomProvider = context.read<StudyRoomProvider>();
  }

  @override
  void dispose() {
    // Use saved reference — context.read is NOT safe in dispose()
    _studyRoomProvider?.stopPolling();
    _searchController.dispose();
    super.dispose();
  }

  String get _displayName {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    return user?.displayName ?? user?.username ?? 'Student';
  }

  Future<void> _onJoin(StudyRoom room) async {
    final provider = context.read<StudyRoomProvider>();
    try {
      final joined = await provider.joinRoom(room.roomId);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true)
          .push(
            MaterialPageRoute(
              builder: (_) => MeetingScreen(
                room: joined,
                displayName: _displayName,
              ),
            ),
          )
          .then((_) => provider.leaveRoom(room.roomId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateRoomSheet(
        onSubmit: (name) async {
          final provider = context.read<StudyRoomProvider>();
          final room = await provider.createRoom(name);
          if (!mounted) return;
          Navigator.pop(context);
          Navigator.of(context, rootNavigator: true)
              .push(
                MaterialPageRoute(
                  builder: (_) => MeetingScreen(
                    room: room,
                    displayName: _displayName,
                  ),
                ),
              )
              .then((_) => provider.leaveRoom(room.roomId));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LockedInAppBar(),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchBarWidget(
              controller: _searchController,
              hintText: 'Search rooms',
            ),
          ),
          // Old search bar code:
          // Padding(
          //   padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          //   child: Container(
          //     decoration: BoxDecoration(
          //       color: AppColors.backgroundBox,
          //       borderRadius: BorderRadius.circular(12),
          //       border: Border.all(color: Colors.grey.withOpacity(0.15)),
          //     ),
          //     child: TextField(
          //       controller: _searchController,
          //       style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          //       decoration: InputDecoration(
          //         hintText: 'Search rooms',
          //         hintStyle: TextStyle(color: AppColors.grey, fontSize: 14),
          //         prefixIcon:
          //             Icon(Icons.search, color: AppColors.grey, size: 20),
          //         border: InputBorder.none,
          //         contentPadding: const EdgeInsets.symmetric(vertical: 12),
          //       ),
          //     ),
          //   ),
          // ),

          // Room list
          Expanded(
            child: _RoomListView(
              searchQuery: _searchQuery,
              onJoin: _onJoin,
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 8),
        child: SquareButton(
          icon: Icons.add,
          onPressed: () => _showCreateSheet(),
        ),
      ),
    );
  }
}

// ── Room List ──────────────────────────────────────────────────────────────

class _RoomListView extends StatelessWidget {
  final String searchQuery;
  final Future<void> Function(StudyRoom) onJoin;

  const _RoomListView({required this.searchQuery, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyRoomProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.rooms.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
                color: AppColors.accent, strokeWidth: 2),
          );
        }
        if (provider.status == RoomStatus.error && provider.rooms.isEmpty) {
          return Center(
            child:
                ErrorBanner(message: provider.error ?? 'Failed to load rooms'),
          );
        }

        final filtered = provider.rooms
            .where((r) => r.name.toLowerCase().contains(searchQuery))
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 40, color: AppColors.grey),
                const SizedBox(height: 12),
                Text(
                  searchQuery.isEmpty
                      ? 'No active rooms yet.'
                      : 'No rooms match "$searchQuery"',
                  style: TextStyle(color: AppColors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final room = filtered[i];
            return _RoomListCard(room: room, onJoin: () => onJoin(room));
          },
        );
      },
    );
  }
}

// ── Room Card ──────────────────────────────────────────────────────────────

class _RoomListCard extends StatelessWidget {
  final StudyRoom room;
  final VoidCallback onJoin;

  const _RoomListCard({required this.room, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final count = room.participantCount;
    final isFull = count >= 10;

    return GestureDetector(
      onTap: isFull ? null : onJoin,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundBox,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            // Name + online count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isFull
                              ? Colors.orange
                              : const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isFull ? 'Full' : '$count Online',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Join button
            if (!isFull)
              TextButton(
                onPressed: onJoin,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Join',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              )
            else
              Text(
                'Full',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:lockedin_frontend/ui/widgets/actions/square_button.dart';
// import 'package:provider/provider.dart';
// import '../../../provider/study_room_provider.dart';
// import '../../../models/study_room/study_room.dart';
// import 'widgets/create_room_sheet.dart';
// import 'widgets/error_banner.dart';
// import 'meeting_screen.dart';
// import '../../theme/app_theme.dart';
// import '../../../provider/auth_provider.dart';
// import '../../widgets/display/lockedin_appbar.dart';
// import '../../widgets/inputs/search_bar_widget.dart';

// class LobbyScreen extends StatefulWidget {
//   const LobbyScreen({super.key});

//   @override
//   State<LobbyScreen> createState() => _LobbyScreenState();
// }

// class _LobbyScreenState extends State<LobbyScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<StudyRoomProvider>().startPolling();
//     });
//     _searchController.addListener(() {
//       setState(() => _searchQuery = _searchController.text.toLowerCase());
//     });
//   }

//   @override
//   void dispose() {
//     context.read<StudyRoomProvider>().stopPolling();
//     _searchController.dispose();
//     super.dispose();
//   }

//   String get _displayName {
//     final auth = context.read<AuthProvider>();
//     final user = auth.currentUser;
//     return user?.displayName ?? user?.username ?? 'Student';
//   }

//   Future<void> _onJoin(StudyRoom room) async {
//     final provider = context.read<StudyRoomProvider>();
//     try {
//       final joined = await provider.joinRoom(room.roomId);
//       if (!mounted) return;
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) =>
//               MeetingScreen(room: joined, displayName: _displayName),
//         ),
//       ).then((_) => provider.leaveRoom(room.roomId));
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(e.toString()),
//           backgroundColor: AppColors.primary,
//         ),
//       );
//     }
//   }

//   void _showCreateSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => CreateRoomSheet(
//         onSubmit: (name) async {
//           final provider = context.read<StudyRoomProvider>();
//           final room = await provider.createRoom(name);
//           if (!mounted) return;
//           Navigator.pop(context);
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) =>
//                   MeetingScreen(room: room, displayName: _displayName),
//             ),
//           ).then((_) => provider.leaveRoom(room.roomId));
//         },
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const LockedInAppBar(),
//       backgroundColor: AppColors.background,
//       body: Column(
//         children: [
//           // Search bar
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
//             child: SearchBarWidget(
//               controller: _searchController,
//               hintText: 'Search rooms',
//             ),
//           ),
//           // Old search bar code:
//           // Padding(
//           //   padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
//           //   child: Container(
//           //     decoration: BoxDecoration(
//           //       color: AppColors.backgroundBox,
//           //       borderRadius: BorderRadius.circular(12),
//           //       border: Border.all(color: Colors.grey.withOpacity(0.15)),
//           //     ),
//           //     child: TextField(
//           //       controller: _searchController,
//           //       style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
//           //       decoration: InputDecoration(
//           //         hintText: 'Search rooms',
//           //         hintStyle: TextStyle(color: AppColors.grey, fontSize: 14),
//           //         prefixIcon:
//           //             Icon(Icons.search, color: AppColors.grey, size: 20),
//           //         border: InputBorder.none,
//           //         contentPadding: const EdgeInsets.symmetric(vertical: 12),
//           //       ),
//           //     ),
//           //   ),
//           // ),

//           // Room list
//           Expanded(
//             child: _RoomListView(
//               searchQuery: _searchQuery,
//               onJoin: _onJoin,
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: Padding(
//         padding: const EdgeInsets.only(bottom: 16, right: 8),
//         child: SquareButton(
//           icon: Icons.add,
//           onPressed: () => _showCreateSheet(),
//         ),
//       ),
//     );
//   }
// }

// // ── Room List ──────────────────────────────────────────────────────────────

// class _RoomListView extends StatelessWidget {
//   final String searchQuery;
//   final Future<void> Function(StudyRoom) onJoin;

//   const _RoomListView({required this.searchQuery, required this.onJoin});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<StudyRoomProvider>(
//       builder: (context, provider, _) {
//         if (provider.isLoading && provider.rooms.isEmpty) {
//           return Center(
//             child: CircularProgressIndicator(
//                 color: AppColors.accent, strokeWidth: 2),
//           );
//         }
//         if (provider.status == RoomStatus.error && provider.rooms.isEmpty) {
//           return Center(
//             child:
//                 ErrorBanner(message: provider.error ?? 'Failed to load rooms'),
//           );
//         }

//         final filtered = provider.rooms
//             .where((r) => r.name.toLowerCase().contains(searchQuery))
//             .toList();

//         if (filtered.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.search_off, size: 40, color: AppColors.grey),
//                 const SizedBox(height: 12),
//                 Text(
//                   searchQuery.isEmpty
//                       ? 'No active rooms yet.'
//                       : 'No rooms match "$searchQuery"',
//                   style: TextStyle(color: AppColors.grey, fontSize: 14),
//                 ),
//               ],
//             ),
//           );
//         }

//         return ListView.separated(
//           padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
//           itemCount: filtered.length,
//           separatorBuilder: (_, __) => const SizedBox(height: 10),
//           itemBuilder: (context, i) {
//             final room = filtered[i];
//             return _RoomListCard(room: room, onJoin: () => onJoin(room));
//           },
//         );
//       },
//     );
//   }
// }

// // ── Room Card ──────────────────────────────────────────────────────────────

// class _RoomListCard extends StatelessWidget {
//   final StudyRoom room;
//   final VoidCallback onJoin;

//   const _RoomListCard({required this.room, required this.onJoin});

//   @override
//   Widget build(BuildContext context) {
//     final count = room.participantCount;
//     final isFull = count >= 10;

//     return GestureDetector(
//       onTap: isFull ? null : onJoin,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         decoration: BoxDecoration(
//           color: AppColors.backgroundBox,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: Colors.grey.withOpacity(0.15)),
//         ),
//         child: Row(
//           children: [
//             // Name + online count
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     room.name,
//                     style: TextStyle(
//                       color: AppColors.textPrimary,
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Container(
//                         width: 7,
//                         height: 7,
//                         decoration: BoxDecoration(
//                           color: isFull
//                               ? Colors.orange
//                               : const Color(0xFF4CAF50),
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                       const SizedBox(width: 5),
//                       Text(
//                         isFull ? 'Full' : '$count Online',
//                         style: TextStyle(
//                           color: AppColors.grey,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // Join button
//             if (!isFull)
//               TextButton(
//                 onPressed: onJoin,
//                 style: TextButton.styleFrom(
//                   foregroundColor: AppColors.primary,
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   minimumSize: Size.zero,
//                   tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                 ),
//                 child: const Text(
//                   'Join',
//                   style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
//                 ),
//               )
//             else
//               Text(
//                 'Full',
//                 style: TextStyle(
//                   color: AppColors.grey,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }