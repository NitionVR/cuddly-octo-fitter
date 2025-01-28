import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class CustomProgressBar extends StatelessWidget {
  final double progress;

  const CustomProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.progressBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        widthFactor: progress / 100,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.progressBar,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}