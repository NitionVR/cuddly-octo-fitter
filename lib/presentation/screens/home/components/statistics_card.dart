// lib/presentation/screens/home/components/statistics_card.dart
import 'package:flutter/material.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/analytics_view_model_extensions.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../viewmodels/analytics_view_model.dart';
import '../../../widgets/dashboard_card.dart';

class StatisticsCard extends StatelessWidget {
  final VoidCallback? onTap;

  const StatisticsCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsViewModel>();

    return DashboardCard(
      icon: const Icon(Icons.bar_chart, color: Colors.white, size: 24),
      onTap: onTap,
      title: 'Statistics',
      content: analytics.isLoading
          ? const _LoadingState()
          : _StatisticsGrid(analytics: analytics),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  final AnalyticsViewModel analytics;

  const _StatisticsGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatItem(
          label: 'Total Distance',
          value: '${analytics.totalDistance.toStringAsFixed(1)}km',
          icon: Icons.straighten,
        ),
        _StatItem(
          label: 'Total Runs',
          value: analytics.totalRuns.toString(),
          icon: Icons.directions_run,
        ),
        _StatItem(
          label: 'Avg Pace',
          value: analytics.averagePace ?? '0:00/km',
          icon: Icons.speed,
        ),
        _StatItem(
          label: 'Best Pace',
          value: analytics.bestPace ?? '0:00/km',
          icon: Icons.timer,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardHoverBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _AnimatedStatValue(
            value: value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStatValue extends StatelessWidget {
  final String value;
  final TextStyle? style;

  const _AnimatedStatValue({
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(value, style: style),
    );
  }
}

// Optional: Add this for detailed stats view
class StatDetailsSheet extends StatelessWidget {
  final String label;
  final String value;
  final List<_DetailedStat> details;

  const StatDetailsSheet({
    super.key,
    required this.label,
    required this.value,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ...details.map((detail) => _DetailedStatRow(detail: detail)),
        ],
      ),
    );
  }
}

class _DetailedStat {
  final String label;
  final String value;
  final String? comparison;

  const _DetailedStat({
    required this.label,
    required this.value,
    this.comparison,
  });
}

class _DetailedStatRow extends StatelessWidget {
  final _DetailedStat detail;

  const _DetailedStatRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            detail.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                detail.value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (detail.comparison != null)
                Text(
                  detail.comparison!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}