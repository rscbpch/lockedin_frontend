import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../theme/app_theme.dart';
import '../../../../services/pomodoro_service.dart';

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

enum TimerMode { pomodoro, shortBreak, longBreak }

/// ================= SCREEN =================
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const Map<TimerMode, int> defaultMinutes = {
    TimerMode.pomodoro: 25,
    TimerMode.shortBreak: 5,
    TimerMode.longBreak: 10,
  };

  Timer? _timer;
  VideoPlayerController? _videoController;
  bool _videoHasError = false;
  String _videoErrorMessage = '';

  TimerMode _mode = TimerMode.pomodoro;
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  int _pomodoroCount = 0;

  /// ===== TRACKING PANEL STATE =====
  bool _showTracking = false;
  int _trackingTab = 0;
  Map<String, dynamic>? _stats;
  List<dynamic> _ranking = [];
  bool _loadingTracking = false;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideo();
    });
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
        setState(() {});
        _updateVideoPlaybackSpeed();
      }
    } catch (e) {
      setState(() {
        _videoHasError = true;
        _videoErrorMessage = e.toString();
      });
    }
  }

  /// ================= TIMER =================
  void _initializeTimer() {
    _totalSeconds = defaultMinutes[_mode]! * 60;
    _remainingSeconds = _totalSeconds;
    _updateVideoPlaybackSpeed();
  }

  void _updateVideoPlaybackSpeed() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }

    final videoDuration = _videoController!.value.duration.inSeconds;
    if (videoDuration == 0) return;

    final speed = (videoDuration / _totalSeconds).clamp(0.1, 4.0);
    _videoController!.setPlaybackSpeed(speed);
  }

  void _startTimer({bool autoStart = false}) {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    _videoController?.seekTo(Duration.zero);
    _videoController?.play();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _onTimerComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _videoController?.pause();
    setState(() => _isRunning = false);
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

  void _switchMode(TimerMode mode) {
    if (_mode == mode) return;

    _stopTimer();
    setState(() {
      _mode = mode;
      _initializeTimer();
    });

    // Reset video and update speed for new timer duration
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.seekTo(Duration.zero);
      _videoController!.pause();
      _updateVideoPlaybackSpeed();
    }
  }

  void _addMinutes(int minutes) {
    if (_isRunning) return;

    final newSeconds = _remainingSeconds + minutes * 60;
    if (newSeconds <= 0) return;

    setState(() {
      _remainingSeconds = newSeconds;
      _totalSeconds = newSeconds;
    });

    // Update video playback speed for new duration
    _updateVideoPlaybackSpeed();
  }

  String _formatFocusTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatTime() {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')} : ${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_totalSeconds == 0) return 0;
    return (_totalSeconds - _remainingSeconds) / _totalSeconds;
  }

  void _onTimerComplete() async {
    _stopTimer();

    if (_mode == TimerMode.pomodoro) {
      // Save focus session
      await PomodoroService.createSession(
        durationSeconds: _totalSeconds,
        type: 'focus',
      );
    }

    // Vibrate when timer completes
    HapticFeedback.heavyImpact();

    // Handle different completion scenarios
    if (_mode == TimerMode.pomodoro) {
      _pomodoroCount++;

      if (_pomodoroCount % 4 == 0) {
        // After 4 pomodoros, suggest long break
        _showCompletionDialog(
          'Pomodoro Complete!',
          'Great work! You\'ve completed 4 pomodoros. Time for a long break?',
          () => _autoSwitchMode(TimerMode.longBreak),
        );
      } else {
        // After each pomodoro, suggest short break
        _showCompletionDialog(
          'Pomodoro Complete!',
          'Great work! Time for a short break?',
          () => _autoSwitchMode(TimerMode.shortBreak),
        );
      }
    } else if (_mode == TimerMode.shortBreak) {
      // After short break, suggest pomodoro
      _showCompletionDialog(
        'Short Break Complete!',
        'Break\'s over! Ready to start another pomodoro?',
        () => _autoSwitchMode(TimerMode.pomodoro),
      );
    } else if (_mode == TimerMode.longBreak) {
      // After long break, reset count and suggest pomodoro
      _pomodoroCount = 0;
      _showCompletionDialog(
        'Long Break Complete!',
        'You\'re refreshed! Ready to start a new pomodoro cycle?',
        () => _autoSwitchMode(TimerMode.pomodoro),
      );
    }
  }

  void _showCompletionDialog(String title, String message, VoidCallback onYes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onYes();
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _autoSwitchMode(TimerMode mode) {
    setState(() {
      _mode = mode;
      _initializeTimer();
    });

    // Reset video for new timer mode
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.seekTo(Duration.zero);
      _updateVideoPlaybackSpeed();
    }

    _startTimer(autoStart: true);
  }

  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
          Center(
            child: Column(
              children: [
                /// ===== ORIGINAL UI (UNCHANGED) =====
                const SizedBox(height: 20),

                
                /// ✅ Tabs (no overflow, no crash)
                Wrap(
                  spacing: 8,
                  children: TimerMode.values.map((mode) {
                    final isSelected = _mode == mode;
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
                      onSelected: (_) => _switchMode(mode),
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
                        painter: TimerPainter(progress: _progress),
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
                if (_mode == TimerMode.pomodoro)
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
                      'Pomodoro ${_pomodoroCount + 1} of 4',
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
                      onPressed: () => _addMinutes(-1),
                    ),
                    Text(
                      _formatTime(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.add),
                      onPressed: () => _addMinutes(1),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isRunning ? _stopTimer : () => _startTimer(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                  ),
                  child: Text(_isRunning ? 'Stop' : 'Start'),
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
