import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:provider/provider.dart';
import 'package:lockedin_frontend/provider/auth_provider.dart';
import 'package:lockedin_frontend/utils/activity_tracker.dart';
import '../../../models/study_room/study_room.dart';
import '../../../provider/study_room_provider.dart';
import '../../theme/app_theme.dart';

class MeetingScreen extends StatefulWidget {
  final StudyRoom room;
  final String displayName;

  const MeetingScreen({super.key, required this.room, this.displayName = 'Student'});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> with ActivityTracker {
  final _jitsi = JitsiMeet();
  bool _isConnected = false;
  bool _isJoining = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _join();
  }

  Future<void> _join() async {
    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      // Fetch JWT from your backend — sets user as moderator, bypasses lobby
      final auth = context.read<AuthProvider>();
      final provider = context.read<StudyRoomProvider>();
      final avatarUrl = auth.currentUser?.avatar ?? '';
      final token = await provider.getJitsiToken(roomId: widget.room.roomId, displayName: widget.displayName, email: '', avatar: avatarUrl);
      // JaaS room format: vpaas-magic-cookie-xxxxx/roomId
      final roomName = '${provider.jaasAppId}/${widget.room.roomId}';

      final options = JitsiMeetConferenceOptions(
        serverURL: 'https://8x8.vc',
        room: roomName,
        token: token,
        configOverrides: {
          'startWithAudioMuted': true,
          'startWithVideoMuted': false,
          'prejoinPageEnabled': false,
          'disableDeepLinking': true,
          'disableInviteFunctions': true,
          'doNotStoreRoom': true,
          'startSilent': true,
          'disableAudioLevels': true,
          'enableNoisyMicDetection': false,
          'audioQuality': {'stereo': false},
          'desktopSharingEnabled': false,
          'whiteboard.enabled': false,
          'disableDesktopSharing': true,
          'screensharingIcons': false,
          'subject': widget.room.name,
          'localSubject': widget.room.name,
        },
        featureFlags: {
          'unsaferoomwarning.enabled': false,
          'ios.recording.enabled': false,
          'live-streaming.enabled': false,
          'prejoinpage.enabled': false,
          'security-options.enabled': false,
          'invite.enabled': false,
          'add-people.enabled': false,
          'invite-people.enabled': false,
          'dial-out.enabled': false,
          'call-integration.enabled': false,
          'breakout-rooms.enabled': false,
          'recording.enabled': false,
          'audio-mute.enabled': false,
          'audio-focus-disabled': true,
          'android.screensharing.enabled': false,
          'ios.screensharing.enabled': false,
          'screen-sharing.enabled': false,
          'whiteboard.enabled': false,
          'filmstrip.enabled': false,
        },
        userInfo: JitsiMeetUserInfo(displayName: widget.displayName, email: ''),
      );

      final listener = JitsiMeetEventListener(
        conferenceJoined: (_) => setState(() {
          _isConnected = true;
          _isJoining = false;
        }),
        conferenceTerminated: (_, __) => _handleEnd(),
        conferenceWillJoin: (_) => setState(() => _isJoining = true),
        participantJoined: (_, __, ___, ____) {},
        participantLeft: (_) {},
      );

      await _jitsi.join(options, listener);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isJoining = false;
        });
      }
    }
  }

  void _handleEnd() {
    if (mounted) Navigator.pop(context);
  }

  Future<void> _hangup() async {
    await _jitsi.hangUp();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _MeetingBar(room: widget.room, isConnected: _isConnected, onLeave: _hangup),
            Expanded(
              child: _error != null
                  ? _ErrorView(message: _error!, onRetry: _join)
                  : _isJoining
                  ? const _ConnectingView()
                  : const _JitsiPlaceholder(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingBar extends StatelessWidget {
  final StudyRoom room;
  final bool isConnected;
  final VoidCallback onLeave;

  const _MeetingBar({required this.room, required this.isConnected, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundBox,
        border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Text('◈', style: TextStyle(color: AppColors.accent, fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              room.name,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isConnected) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onLeave,
            icon: const Icon(Icons.close, size: 14),
            label: const Text('Leave'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectingView extends StatelessWidget {
  const _ConnectingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
          const SizedBox(height: 16),
          Text('Connecting to room…', style: TextStyle(color: AppColors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}

class _JitsiPlaceholder extends StatelessWidget {
  const _JitsiPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam, size: 48, color: AppColors.accent),
          const SizedBox(height: 12),
          Text(
            'Meeting is active',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('Jitsi is running in its native view.', style: TextStyle(color: AppColors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.primary, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: AppColors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
