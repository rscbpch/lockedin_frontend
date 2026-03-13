import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../provider/pomodoro_timer_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../../services/pomodoro_service.dart';

class _TimerTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '00:00',
        selection: TextSelection.collapsed(offset: 5),
      );
    }

    final boundedDigits = digitsOnly.length > 4
      ? digitsOnly.substring(digitsOnly.length - 4)
      : digitsOnly;

    String minutePart;
    String secondPart;

    if (boundedDigits.length <= 2) {
      minutePart = boundedDigits.padLeft(2, '0');
      secondPart = '00';
    } else {
      final rawMinutes = boundedDigits.substring(0, boundedDigits.length - 2);
      final rawSeconds = boundedDigits.substring(boundedDigits.length - 2);
      minutePart = rawMinutes.padLeft(2, '0');
      secondPart = rawSeconds;
    }

    final minutes = int.tryParse(minutePart) ?? 0;
    final seconds = int.tryParse(secondPart) ?? 0;

    final clampedMinutes = minutes.clamp(0, 99);
    final clampedSeconds = seconds.clamp(0, 59);
    final formatted =
        '${clampedMinutes.toString().padLeft(2, '0')}:${clampedSeconds.toString().padLeft(2, '0')}';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// ================= TIMER PAINTER =================
class TimerPainter extends CustomPainter {
  final double progress;
  TimerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = Colors.brown.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    final progressPaint = Paint()
      ..color = Colors.brown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TimerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// ================= SCREEN =================
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  VideoPlayerController? _videoController;
  bool _videoHasError = false;
  String _videoErrorMessage = '';
  int? _lastSyncedTotalSeconds;
  bool? _lastSyncedRunning;
  final TextEditingController _timeInputController = TextEditingController();
  final FocusNode _timeInputFocusNode = FocusNode();
  int? _lastSyncedTimeInputSeconds;
  final TextInputFormatter _timerFormatter = _TimerTextInputFormatter();

  /// ===== TRACKING PANEL STATE =====
  bool _showTracking = false;
  int _trackingTab = 0;
  Map<String, dynamic>? _stats;
  List<dynamic> _ranking = [];
  bool _loadingTracking = false;

  @override
  void initState() {
    super.initState();
    _timeInputFocusNode.addListener(() {
      if (!_timeInputFocusNode.hasFocus && mounted) {
        _applyTypedTime(context.read<PomodoroTimerProvider>());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideo();
      _syncTimeInputWithProvider(context.read<PomodoroTimerProvider>());
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _timeInputController.dispose();
    _timeInputFocusNode.dispose();
    super.dispose();
  }

  /// ================= VIDEO =================
  void _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset(
        'assets/images/coffee.mp4',
      );

      _videoController!.addListener(() {
        if (_videoController!.value.hasError) {
          setState(() {
            _videoHasError = true;
            _videoErrorMessage =
                _videoController!.value.errorDescription ??
                'Unknown video error';
          });
        }
      });

      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.setVolume(0);

      if (mounted) {
        _updateVideoPlaybackSpeed(
          context.read<PomodoroTimerProvider>().totalSeconds,
        );
        setState(() {});
      }
    } catch (e) {
      setState(() {
        _videoHasError = true;
        _videoErrorMessage = e.toString();
      });
    }
  }

  /// ================= TIMER =================
  void _updateVideoPlaybackSpeed(int totalSeconds) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    final videoDuration = _videoController!.value.duration.inSeconds;
    if (videoDuration == 0) return;

    final safeTotalSeconds = totalSeconds <= 0 ? 1 : totalSeconds;
    final speed = (videoDuration / safeTotalSeconds).clamp(0.1, 4.0);
    _videoController!.setPlaybackSpeed(speed);
  }

  void _startTimer(PomodoroTimerProvider provider) {
    provider.startTimer();
    _videoController?.seekTo(Duration.zero);
    _videoController?.play();
  }

  void _stopTimer(PomodoroTimerProvider provider) {
    provider.stopTimer();
    _videoController?.pause();
  }

  void _syncVideoWithProvider(PomodoroTimerProvider provider) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    if (_lastSyncedTotalSeconds != provider.totalSeconds) {
      _lastSyncedTotalSeconds = provider.totalSeconds;
      _updateVideoPlaybackSpeed(provider.totalSeconds);
    }

    if (_lastSyncedRunning == provider.isRunning) {
      return;
    }

    _lastSyncedRunning = provider.isRunning;
    if (provider.isRunning) {
      _videoController!.play();
    } else {
      _videoController!.pause();
    }
  }

  /// ================= TRACKING =================
  Future<void> _openTracking() async {
    setState(() {
      _showTracking = true;
      _loadingTracking = true;
    });

    final stats = await PomodoroService.getMyStats();
    final ranking = await PomodoroService.getRanking();

    if (!mounted) return;

    setState(() {
      _stats = stats;
      _ranking = ranking;
      _loadingTracking = false;
    });
  }

  // ===== TRACKING PANEL =====
  Widget _trackingPanel() {
    return Stack(
      children: [
        // ── Scrim: tapping the background closes the panel ──
        if (_showTracking)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _showTracking = false),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),

        // ── The sliding panel itself ──
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          bottom: _showTracking ? 0 : -560,
          left: 0,
          right: 0,
          height: 560,
          child: GestureDetector(
            onTap: () {}, // absorb taps so they don't fall through to scrim
            onVerticalDragEnd: (details) {
              // If user swipes down (positive velocity), close the panel
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 300) {
                setState(() => _showTracking = false);
              }
            },
            child: Material(
              elevation: 24,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              color: const Color(0xFFFDF8EE),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Drag handle
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Close icon: top-right only ──
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => setState(() => _showTracking = false),
                        child: const Icon(
                          Icons.close,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Tab toggle: full-width row, below the close icon ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _tabBtn(Icons.trending_up_rounded, 0),
                        _tabBtn(Icons.group_rounded, 1),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: _loadingTracking
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6B3F1A),
                            ),
                          )
                        : _trackingTab == 0
                        ? _personalTab()
                        : _friendsTab(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ], // end Stack.children
    ); // end Stack
  }

  // ===== TAB BUTTON (icon style) =====
  Widget _tabBtn(IconData icon, int index) {
    final selected = _trackingTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _trackingTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6B3F1A) : Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: index == 1 ? Radius.zero : const Radius.circular(10),
              bottomLeft: index == 1 ? Radius.zero : const Radius.circular(10),
              topRight: index == 0 ? Radius.zero : const Radius.circular(10),
              bottomRight: index == 0 ? Radius.zero : const Radius.circular(10),
            ),
            border: selected
                ? Border.all(color: Colors.transparent, width: 1)
                : Border.all(color: AppColors.primary, width: 1),
          ),
          child: Icon(
            icon,
            size: 22,
            color: selected ? Colors.white : Colors.black45,
          ),
        ),
      ),
    );
  }

  // ===== PERSONAL TAB =====
  Widget _personalTab() {
  if (_stats == null) {
    return const Center(
      child: Text(
        'No stats available',
        style: TextStyle(color: Colors.black38),
      ),
    );
  }

  final daily = _stats!["daily"] ?? {};
  final weekly = _stats!["weekly"] ?? {};
  final monthly = _stats!["monthly"] ?? {};
  final allTime = _stats!["allTime"] ?? {};

  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Focus Stats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C1A0E),
          ),
        ),
        const SizedBox(height: 20),

        // Row 1: Today + This Week
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Today',
                daily["totalSeconds"] as int? ?? 0,
                daily["sessions"] as int? ?? 0,
                Icons.today_rounded,
                const Color(0xFF6B3F1A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                'This Week',
                weekly["totalSeconds"] as int? ?? 0,
                weekly["sessions"] as int? ?? 0,
                Icons.date_range_rounded,
                const Color(0xFF8B5A2B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: This Month + All Time
        Row(
          children: [
            Expanded(
              child: _statCard(
                'This Month',
                monthly["totalSeconds"] as int? ?? 0,
                monthly["sessions"] as int? ?? 0,
                Icons.calendar_month_rounded,
                const Color(0xFFA67C52),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                'All Time',
                allTime["totalSeconds"] as int? ?? 0,
                allTime["sessions"] as int? ?? 0,
                Icons.all_inclusive_rounded,
                const Color(0xFFC69C6D),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Helper: Individual stat card (compact for 2-column grid)
Widget _statCard(
  String label,
  int totalSeconds,
  int sessions,
  IconData icon,
  Color color,
) {
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  
  // Format based on duration
  String displayTime;
  if (totalSeconds >= 3600) {
    // 1 hour or more: show hours and minutes
    displayTime = '${hours}h ${minutes}m';
  } else if (totalSeconds >= 60) {
    // 1 minute or more (but less than 1 hour): show minutes and seconds
    displayTime = '${minutes}m ${seconds}s';
  } else {
    // Less than 1 minute: show only seconds
    displayTime = '${seconds}s';
  }

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + Label row
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Time display
        Text(
          displayTime,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C1A0E),
          ),
        ),
        const SizedBox(height: 4),

        // Sessions badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$sessions ${sessions == 1 ? 'session' : 'sessions'}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}


  // ===== FRIENDS / LEADERBOARD TAB =====
  Widget _friendsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            'Focus time this week',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C1A0E),
            ),
          ),
        ),

        // Column headers
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Row(
            children: const [
              SizedBox(width: 28),
              Expanded(
                child: Text(
                  'Users',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Hours Focused',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        Divider(color: Colors.grey.shade200, height: 1),

        Expanded(
          child: _ranking.isEmpty
              ? const Center(
                  child: Text(
                    'No data yet',
                    style: TextStyle(color: Colors.black38),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _ranking.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: Colors.grey.shade100, height: 1),
                  itemBuilder: (_, i) {
                    final u = _ranking[i];
                    final sec = (u["totalSeconds"] as num?)?.toInt() ?? 0;
                    final displayTime = _formatFocusTime(sec);
                    final isTop3 = i < 3;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          // Rank number
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isTop3
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isTop3
                                    ? const Color(0xFF6B3F1A)
                                    : Colors.black45,
                              ),
                            ),
                          ),

                          // Username
                          Expanded(
                            child: Text(
                              u["_id"]?.toString() ?? '—',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isTop3
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: const Color(0xFF2C1A0E),
                              ),
                            ),
                          ),

                          // Time
                          Text(
                            displayTime,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _label(TimerMode mode) {
    switch (mode) {
      case TimerMode.pomodoro:
        return 'Pomodoro';
      case TimerMode.shortBreak:
        return 'Short break';
      case TimerMode.longBreak:
        return 'Long break';
    }
  }

  void _switchMode(PomodoroTimerProvider provider, TimerMode mode) {
    if (provider.mode == mode) return;

    provider.switchMode(mode);

    // Reset video and update speed for new timer duration
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.seekTo(Duration.zero);
      _videoController!.pause();
      _updateVideoPlaybackSpeed(provider.totalSeconds);
    }
  }

  void _addMinutes(PomodoroTimerProvider provider, int minutes) {
    provider.addMinutes(minutes);
    _updateVideoPlaybackSpeed(provider.totalSeconds);
  }

  void _syncTimeInputWithProvider(
    PomodoroTimerProvider provider, {
    bool force = false,
  }) {
    if (!force && _timeInputFocusNode.hasFocus) return;
    if (!force && _lastSyncedTimeInputSeconds == provider.remainingSeconds) {
      return;
    }

    _lastSyncedTimeInputSeconds = provider.remainingSeconds;
    final formatted = _formatEditableTime(provider.remainingSeconds);
    _timeInputController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatEditableTime(int remainingSeconds) {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int? _parseTypedTimeToSeconds(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    if (value.contains(':')) {
      final parts = value.split(':');
      if (parts.length != 2) return null;

      final minutes = int.tryParse(parts[0]);
      final seconds = int.tryParse(parts[1]);
      if (minutes == null || seconds == null) return null;
      if (minutes < 0 || seconds < 0 || seconds >= 60) return null;

      final total = (minutes * 60) + seconds;
      return total > 0 ? total : null;
    }

    final minutes = int.tryParse(value);
    if (minutes == null || minutes <= 0) return null;
    return minutes * 60;
  }

  void _applyTypedTime(PomodoroTimerProvider provider) {
    if (provider.isRunning) return;

    final parsedSeconds = _parseTypedTimeToSeconds(_timeInputController.text);
    if (parsedSeconds == null) {
      _syncTimeInputWithProvider(provider, force: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter time as minutes (e.g. 25) or mm:ss (e.g. 25:00).'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    provider.setDurationSeconds(parsedSeconds);
    _updateVideoPlaybackSpeed(provider.totalSeconds);
    _syncTimeInputWithProvider(provider, force: true);
  }

  String _formatFocusTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double _progress(int totalSeconds, int remainingSeconds) {
    if (totalSeconds == 0) return 0;
    return (totalSeconds - remainingSeconds) / totalSeconds;
  }

  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final timerProvider = context.watch<PomodoroTimerProvider>();
    final width = MediaQuery.of(context).size.width;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncVideoWithProvider(timerProvider);
      _syncTimeInputWithProvider(timerProvider);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pomodoro'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.go("/productivity-hub"),
          icon: Icon(Icons.arrow_back_ios, size: width * 0.06),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: _openTracking,
          ),
        ],
        backgroundColor: AppColors.background,
        elevation: 0,
      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                /// ===== ORIGINAL UI (UNCHANGED) =====
                const SizedBox(height: 20),

                
                /// ✅ Tabs (no overflow, no crash)
                Wrap(
                  spacing: 8,
                  children: TimerMode.values.map((mode) {
                    final isSelected = timerProvider.mode == mode;
                    return ChoiceChip(
                      label: Text(
                        _label(mode),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.background
                              : AppColors.primary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      backgroundColor: isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      onSelected: (_) => _switchMode(timerProvider, mode),
                      selectedColor: AppColors.secondary,
                      showCheckmark: false, // Remove default checkmark icon
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),

                /// Circle Timer with Video in Center
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress circle
                      CustomPaint(
                        size: const Size(260, 260),
                        painter: TimerPainter(
                          progress: _progress(
                            timerProvider.totalSeconds,
                            timerProvider.remainingSeconds,
                          ),
                        ),
                      ),
                      // Video player in the center
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _videoHasError
                              ? Container(
                                  color: Colors.red[100],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          'Video Error:\n$_videoErrorMessage',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.red,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _videoController != null &&
                                    _videoController!.value.isInitialized
                              ? FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoController!.value.size.width,
                                    height: _videoController!.value.size.height,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      CircularProgressIndicator(
                                        color: Colors.brown,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Loading video...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.brown,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

              

                // Cycle counter
                if (timerProvider.mode == TimerMode.pomodoro)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pomodoro ${timerProvider.pomodoroCount + 1} of 4',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),

                const SizedBox(height:12),


                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.remove),
                      onPressed: timerProvider.isRunning
                          ? null
                          : () => _addMinutes(timerProvider, -1),
                    ),
                    SizedBox(
                      width: 170,
                      child: TextField(
                        controller: _timeInputController,
                        focusNode: _timeInputFocusNode,
                        enabled: !timerProvider.isRunning,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_timerFormatter],
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintText: '25:00',
                        ),
                        onSubmitted: (_) => _applyTypedTime(timerProvider),
                        onEditingComplete: () {
                          _applyTypedTime(timerProvider);
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.add),
                      onPressed: timerProvider.isRunning
                          ? null
                          : () => _addMinutes(timerProvider, 1),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: timerProvider.isRunning
                      ? () => _stopTimer(timerProvider)
                      : () => _startTimer(timerProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                  ),
                  child: Text(timerProvider.isRunning ? 'Stop' : 'Start'),
                ),
              ],
            ),
          ),

          /// ===== TRACKING OVERLAY =====
          _trackingPanel(),
        ],
      ),
    );
  }
}
