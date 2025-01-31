import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  final String? imagePath;

  const AuthBackground({
    super.key,
    required this.child,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundStart,
            AppColors.backgroundEnd,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Optional: Add pattern or texture overlay
          if (imagePath != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  imagePath!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          // Content
          child,
        ],
      ),
    );
  }
}