import 'package:flutter/material.dart';
import 'package:lockedin_frontend/ui/responsive/responsive.dart';
import 'package:lockedin_frontend/ui/theme/app_theme.dart';

class FlipCard extends StatefulWidget {
  final String frontText;
  final String backText;

  /// Optional external animation controller. If not provided, tap-to-flip is
  /// handled internally.
  final AnimationController? controller;

  const FlipCard({
    super.key,
    required this.frontText,
    required this.backText,
    this.controller,
  });

  @override
  State<FlipCard> createState() => FlipCardState();
}

class FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _ownsController = false;

  bool get isFlipped => _animation.value >= 0.5;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _ownsController = true;
    }

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void flip() {
    if (_controller.isAnimating) return;
    if (_controller.value == 0) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void resetToFront() {
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isFront = _animation.value < 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_animation.value * 3.1416),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isFront ? AppColors.backgroundBox : AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(isFront ? 0 : 3.1416),
                  child: Text(
                    isFront ? widget.frontText : widget.backText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: Responsive.text(context, size: 20),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
