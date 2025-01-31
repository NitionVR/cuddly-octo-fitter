// lib/presentation/widgets/map/stats_dashboard.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../viewmodels/tracking/map_view_model.dart';

class StatsDashboard extends StatelessWidget {
  final MapViewModel viewModel;

  const StatsDashboard({
    Key? key,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailedStats(context),
      child: Container(
        height: 80, // Fixed height
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: GlassmorphicContainer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactStat(
                icon: Icons.timer,
                value: viewModel.getElapsedTime(),
                label: 'TIME',
              ),
              _buildVerticalDivider(),
              _buildCompactStat(
                icon: Icons.straighten,
                value: (viewModel.totalDistance / 1000).toStringAsFixed(2),
                label: 'KM',
                showUnit: false,
              ),
              _buildVerticalDivider(),
              _buildCompactStat(
                icon: Icons.speed,
                value: _formatPace(viewModel.pace),
                label: 'MIN/KM',
                showUnit: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStat({
    required IconData icon,
    required String value,
    required String label,
    bool showUnit = true,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 4),
          AnimatedStatValue(
            value: value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.1),
    );
  }

  String _formatPace(String pace) {
    // Remove 'min/km' if present and just show the time
    return pace.split(' ').first;
  }

  void _showDetailedStats(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.6,
        builder: (_, controller) => _buildDetailedStatsSheet(controller),
      ),
    );
  }

  Widget _buildDetailedStatsSheet(ScrollController controller) {
    return GlassmorphicContainer(
      child: SingleChildScrollView(
        controller: controller,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailedStatRow(
                    'Current Stats',
                    [
                      _buildDetailedStatItem(
                        'Time',
                        viewModel.getElapsedTime(),
                        Icons.timer,
                      ),
                      _buildDetailedStatItem(
                        'Distance',
                        '${(viewModel.totalDistance / 1000).toStringAsFixed(2)} km',
                        Icons.straighten,
                      ),
                      _buildDetailedStatItem(
                        'Pace',
                        viewModel.pace,
                        Icons.speed,
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 32),
                  _buildDetailedStatRow(
                    'Additional Stats',
                    [
                      _buildDetailedStatItem(
                        'Avg Pace',
                        _calculateAveragePace(),
                        Icons.speed_outlined,
                      ),
                      _buildDetailedStatItem(
                        'Calories',
                        '0 kcal',
                        Icons.local_fire_department,
                      ),
                      _buildDetailedStatItem(
                        'Steps',
                        '0',
                        Icons.directions_walk,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatRow(String title, List<Widget> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: stats,
        ),
      ],
    );
  }

  Widget _buildDetailedStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _calculateAveragePace() {
    return '0:00 min/km';
  }
}

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;

  const GlassmorphicContainer({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// Optional: Add this for animated stats
class AnimatedStatValue extends StatelessWidget {
  final String value;
  final TextStyle? style;

  const AnimatedStatValue({
    super.key,
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 200),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Text(
        value,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}



