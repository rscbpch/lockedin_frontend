import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

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
  bool shouldRepaint(covariant TimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

enum TimerMode { pomodoro, shortBreak, longBreak }

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
  bool _isAutoTransition = false;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
    // Delay video initialization to ensure widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideo();
    });
  }

  void _initializeVideo() async {
    try {
      print('Starting video initialization...');
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
      _videoController!.setVolume(0.0);

      if (mounted) {
        setState(() {
          _videoHasError = false;
        });

        // Update video speed after initialization
        _updateVideoPlaybackSpeed();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoHasError = true;
          _videoErrorMessage = e.toString();
        });
      }
    }
  }

  void _initializeTimer() {
    _totalSeconds = defaultMinutes[_mode]! * 60;
    _remainingSeconds = _totalSeconds;
    _updateVideoPlaybackSpeed();
  }

  void _updateVideoPlaybackSpeed() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final videoDuration = _videoController!.value.duration.inSeconds;
      final timerDuration = _totalSeconds;

      if (videoDuration > 0 && timerDuration > 0) {
        // Calculate speed so that video duration matches timer duration
        final playbackSpeed =
            videoDuration.toDouble() / timerDuration.toDouble();

        // Clamp the speed to reasonable bounds (0.1x to 4x)
        final clampedSpeed = playbackSpeed.clamp(0.1, 4.0);

        _videoController!.setPlaybackSpeed(clampedSpeed);
      }
    }
  }

  void _switchMode(TimerMode mode) {
    if (_mode == mode) return;

    _stopTimer();
    setState(() {
      _mode = mode;
      _initializeTimer();
      _isAutoTransition = false;
    });

    // Reset video and update speed for new timer duration
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.seekTo(Duration.zero);
      _videoController!.pause();
      _updateVideoPlaybackSpeed();
    }
  }

  void _startTimer({bool autoStart = false}) {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _isAutoTransition = autoStart;
    });

    // Make sure video speed is correct before starting
    _updateVideoPlaybackSpeed();

    // Start video playback when timer starts
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.seekTo(Duration.zero); // Reset to beginning
      _videoController!.play();
    }

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
    _timer = null;

    // Pause video when timer stops
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.pause();
    }

    setState(() {
      _isRunning = false;
      _isAutoTransition = false;
    });
  }

  void _onTimerComplete() async {
    _stopTimer();

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

  String _formatTime() {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')} : ${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_totalSeconds == 0) return 0;
    return (_totalSeconds - _remainingSeconds) / _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro'), centerTitle: true),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Cycle counter
          if (_mode == TimerMode.pomodoro)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.brown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Pomodoro ${_pomodoroCount + 1} of 4',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.brown,
                ),
              ),
            ),

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
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => _switchMode(mode),
                selectedColor: Colors.brown,
                backgroundColor: Colors.grey[200],
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
                                CircularProgressIndicator(color: Colors.brown),
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

          // Auto-transition indicator
          if (_isAutoTransition)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.auto_mode, size: 16, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Auto-started',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

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
            child: Text(_isRunning ? 'Stop' : 'Start'),
          ),
        ],
      ),
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
}
