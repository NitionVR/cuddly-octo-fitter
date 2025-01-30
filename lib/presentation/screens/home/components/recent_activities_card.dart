import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile_project_fitquest/presentation/screens/history_screen.dart';
import 'package:mobile_project_fitquest/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../viewmodels/tracking/map_view_model.dart';
import '../../../widgets/dashboard_card.dart';
import '../utils/date_formatter.dart';

class RecentActivitiesCard extends StatelessWidget {
  final VoidCallback? onTap;

  const RecentActivitiesCard({super.key, this.onTap,});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MapViewModel>(context);

    return DashboardCard(
      icon: const Icon(Icons.trending_up, color: Colors.white, size: 24),
      title: 'Recent Runs',
      onTap: onTap,
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: viewModel.getLastThreeActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }

          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error.toString());
          }

          final recentActivities = snapshot.data!;

          if (recentActivities.isEmpty) {
            return const _EmptyState();
          }

          return _ActivityList(activities: recentActivities);
        },
      ),
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

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Error loading recent activities: $error",
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Text(
      'No recent activities',
      style: AppTheme.darkTheme.textTheme.bodyMedium,
    );
  }
}

class _ActivityList extends StatelessWidget {
  final List<Map<String, dynamic>> activities;

  const _ActivityList({required this.activities});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: activities.map((activity) =>
          _ActivityItem(activity: activity)
      ).toList(),
    );
  }
}

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;

  const GlassmorphicContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cardHoverBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.05),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Update ActivityItem to use GlassmorphicContainer
class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final timestamp = activity['timestamp'] as DateTime;
    final duration = activity['duration'] as int;
    final totalDistanceMeters = activity['total_distance'] as double? ?? 0.0;
    final totalDistanceKm = totalDistanceMeters / 1000; // Convert to kilometers
    final avgPace = activity['avg_pace'];

    return GlassmorphicContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormatter.formatTimestamp(timestamp),
            style: AppTheme.darkTheme.textTheme.bodySmall,
          ),
          Row(
            children: [
              _StatItem(
                value: '${totalDistanceKm.toStringAsFixed(2)}km', // Now correctly shows in km
                context: context,
              ),
              const SizedBox(width: 16),
              _StatItem(
                value: DateFormatter.formatDuration(duration),
                context: context,
              ),
              const SizedBox(width: 16),
              _StatItem(
                value: '$avgPace',
                context: context,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _StatItem extends StatelessWidget {
  final String value;
  final BuildContext context;

  const _StatItem({
    required this.value,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: AppTheme.darkTheme.textTheme.bodySmall
    );
  }
}