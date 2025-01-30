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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('PACE', viewModel.pace, Icons.speed)),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'DISTANCE',
              '${(viewModel.totalDistance / 1000).toStringAsFixed(2)} km',
              Icons.straighten,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'TIME',
              viewModel.getElapsedTime(),
              Icons.timer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return GlassmorphicContainer(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Value
            Text(
              value,
              style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
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
    Key? key,
    required this.value,
    this.style,
  }) : super(key: key);

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

// Optional: Add this for a more detailed stats view
class DetailedStatsDashboard extends StatelessWidget {
  final MapViewModel viewModel;

  const DetailedStatsDashboard({
    Key? key,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailedStat(
                'Current Pace',
                viewModel.pace,
                Icons.speed,
              ),
              _buildDetailedStat(
                'Average Pace',
                _calculateAveragePace(),
                Icons.speed_outlined,
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailedStat(
                'Distance',
                '${(viewModel.totalDistance / 1000).toStringAsFixed(2)} km',
                Icons.straighten,
              ),
              _buildDetailedStat(
                'Duration',
                viewModel.getElapsedTime(),
                Icons.timer,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
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
    // Implement average pace calculation
    return '0:00 min/km';
  }
}

// Optional: Add this for collapsible stats
class CollapsibleStatsDashboard extends StatefulWidget {
  final MapViewModel viewModel;

  const CollapsibleStatsDashboard({
    Key? key,
    required this.viewModel,
  }) : super(key: key);

  @override
  State<CollapsibleStatsDashboard> createState() => _CollapsibleStatsDashboardState();
}

class _CollapsibleStatsDashboardState extends State<CollapsibleStatsDashboard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: _isExpanded
            ? DetailedStatsDashboard(viewModel: widget.viewModel)
            : StatsDashboard(viewModel: widget.viewModel),
      ),
    );
  }
}