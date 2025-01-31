import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class CountdownOverlay extends StatefulWidget {
  final VoidCallback onCountdownComplete;

  const CountdownOverlay({
    Key? key,
    required this.onCountdownComplete,
  }) : super(key: key);

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _count = 3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_count > 1) {
          setState(() {
            _count--;
          });
          _controller.reset();
          _controller.forward();
        } else {
          widget.onCountdownComplete();
        }
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: AppColors.backgroundStart.withOpacity(0.8),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 1.0 + (_controller.value * 0.3),
                    child: Opacity(
                      opacity: 1.0 - _controller.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Getting Ready...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Finding GPS Signal',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}