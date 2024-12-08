import 'package:flutter/material.dart';
import 'package:mobile_project_fitquest/domain/repository/achievements_repository.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/goals/fitness_goal.dart';
import '../../domain/repository/goals/goals_repository.dart';
import '../../domain/repository/tracking/tracking_repository.dart';
import '../../theme/app_theme.dart';
import '../viewmodels/achievements_viewmodel.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/goals/goals_view_model.dart';
import '../viewmodels/tracking/map_view_model.dart';
import '../viewmodels/analytics_view_model.dart';
import 'history_screen.dart';
import 'achievements_screen.dart';
import 'goals/goals_screen.dart';
import 'training/interval_training_screen.dart';





class HomeScreen extends StatelessWidget {
  final TrackingRepository _trackingRepository;
  final GoalsRepository _goalsRepository;
  final AchievementsRepository _achievementsRepository;

  // Constructor to inject the dependencies
  const HomeScreen({super.key,
    required TrackingRepository trackingRepository,
    required GoalsRepository goalsRepository,
    required AchievementsRepository achievementsRepository,
  })  : _trackingRepository = trackingRepository,
        _goalsRepository = goalsRepository,
        _achievementsRepository = achievementsRepository;

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthViewModel>().currentUser!.id;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AnalyticsViewModel(_trackingRepository)..loadAnalytics(userId),
        ),
        ChangeNotifierProvider(
          create: (_) => GoalsViewModel(_goalsRepository, userId),
        ),
        ChangeNotifierProvider(
          create: (_) => AchievementsViewModel(_achievementsRepository, userId),
        ),
      ],
      child: const HomeScreenContent(),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecentActivitiesCard(context),
          const SizedBox(height: 16),
          _buildGoalsCard(context),
          const SizedBox(height: 16),
          _buildPersonalRecordsCard(context),
          const SizedBox(height: 16),
          _buildQuickStatsRow(context),
          const SizedBox(height: 16),
          _buildIntervalTrainingCard(context),
          const SizedBox(height: 16),
          _buildAchievementsCard(context),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesCard(BuildContext context) {
    final viewModel = Provider.of<MapViewModel>(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: viewModel.getLastThreeActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Center(
              child: Text(
                "Error loading recent activities: ${snapshot.error}",
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
        }

        final recentActivities = snapshot.data!;

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                trailing: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()), //note here goes history screen
                  ),
                  child: const Text('More', style: TextStyle(color: AppColors.accentGreen)),
                ),
              ),
              const Divider(color: AppColors.textSecondary),
              if (recentActivities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No recent activities',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...recentActivities.map((activity) => _buildActivityItem(activity)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final timestamp = activity['timestamp'];
    final duration = activity['duration'];
    final totalDistance = activity['total_distance'] ?? 00; // Handle null totalDistance
    final avgPace = activity['avg_pace'];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_run, color: AppColors.accentGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Date: ${_formatTimestamp(timestamp)}",
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  "${totalDistance.toStringAsFixed(2)} km • ${_formatDuration(duration)} • $avgPace min/km",
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Text(
            _formatTimeDifference(timestamp),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
  String _formatTimestamp(DateTime timestamp) {
    final dateFormat = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    final timeFormat = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    return '$dateFormat at $timeFormat';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes min ${remainingSeconds.toString().padLeft(2, '0')} sec';
  }

  String _formatTimeDifference(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildGoalsCard(BuildContext context) {
    final goals = context.watch<GoalsViewModel>();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('Goals Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            trailing: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GoalsScreen()),
              ),
              child: const Text('More', style: TextStyle(color: AppColors.accentGreen)),
            ),
          ),
          const Divider(color: AppColors.textSecondary),
          if (goals.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (goals.activeGoals.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No active goals',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: goals.activeGoals
                    .take(2)
                    .map((goal) => _buildGoalProgress(
                  goal.type.toString().split('.').last,
                  goal.progressPercentage / 100,
                  '${goal.currentProgress.toStringAsFixed(1)}/${goal.target} ${_getUnitForGoalType(goal.type)}',
                ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard('This Week', '23.4 km'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickStatCard('Active Streak', '3 days'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickStatCard('Next Plan', 'Tomorrow'),
        ),
      ],
    );
  }

  Widget _buildPersonalRecordsCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text('Personal Records',
              style: Theme.of(context).textTheme.titleLarge,
            ),

          ),
          const Divider(color: AppColors.textSecondary),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            padding: const EdgeInsets.all(16),
            children: [
              _buildRecordItem('Longest Run', '15.3 km'),
              _buildRecordItem('Fastest 5K', '25:30'),
              _buildRecordItem('Longest Streak', '7 days'),
              _buildRecordItem('Best Pace', '5:30/km'),
            ],
          ),
        ],
      ),
    );
  }

  String _getUnitForGoalType(GoalType type) {
    switch (type) {
      case GoalType.distance:
        return 'km';
      case GoalType.duration:
        return 'min';
      case GoalType.frequency:
        return 'runs';
      case GoalType.calories:
        return 'cal';
      case GoalType.pace:
        return 'min/km';
    }
  }

  Widget _buildGoalProgress(String label, double progress, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.progressBackground,
          color: AppColors.progressBar,
        ),
        const SizedBox(height: 4),
        Text(status, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }


  Widget _buildRecordItem(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }



  Widget _buildQuickStatCard(String label, String value) {
    return Card(
      color: AppColors.cardDark,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),

            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalTrainingCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IntervalTrainingScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Interval Training',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Improve your speed and endurance with high-intensity interval training sessions.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AchievementsScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Achievements',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlock achievements and earn rewards for your running milestones.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}