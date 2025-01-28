import 'package:flutter/material.dart';
import 'package:mobile_project_fitquest/domain/repository/achievements_repository.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/analytics_view_model_extensions.dart';
import 'package:mobile_project_fitquest/theme/app_colors.dart';
import 'package:provider/provider.dart';
import '../../data/models/personal_record.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/goals/fitness_goal.dart';
import '../../domain/enums/goal_type.dart';
import '../../domain/repository/goals/goals_repository.dart';
import '../../domain/repository/tracking/tracking_repository.dart';
import '../viewmodels/achievements_viewmodel.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/goals/goals_view_model.dart';
import '../viewmodels/tracking/map_view_model.dart';
import '../viewmodels/analytics_view_model.dart';
import '../widgets/custom_progress_bar.dart';
import '../widgets/dashboard_card.dart';
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
      child:  Container(
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
        child: const HomeScreenContent(),
      ),
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
          _buildStatisticsCard(context),
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

    return DashboardCard(
      icon: const Icon(Icons.trending_up, color: Colors.white, size: 24),
      title: 'Recent Runs',
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: viewModel.getLastThreeActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading recent activities: ${snapshot.error}",
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium,
              ),
            );
          }

          final recentActivities = snapshot.data!;

          if (recentActivities.isEmpty) {
            return Text(
              'No recent activities',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium,
            );
          }

          return Column(
            children: recentActivities.map((activity) =>
                _buildActivityItem(context, activity)
            ).toList(),
          );
        },
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context,
      Map<String, dynamic> activity) {
    final timestamp = activity['timestamp'];
    final duration = activity['duration'];
    final totalDistance = activity['total_distance'] ?? 0.0;
    final avgPace = activity['avg_pace'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardHoverBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date
          Text(
            _formatTimestamp(timestamp),
            style: Theme
                .of(context)
                .textTheme
                .bodyMedium,
          ),

          // Stats
          Row(
            children: [
              // Distance
              Text(
                '${totalDistance.toStringAsFixed(1)}km',
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),

              // Duration
              Text(
                _formatDuration(duration),
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),

              // Pace
              Text(
                '$avgPace/km',
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(
        2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }


  Widget _buildGoalsCard(BuildContext context) {
    final goals = context.watch<GoalsViewModel>();

    return DashboardCard(
      icon: const Icon(Icons.track_changes, color: Colors.white, size: 24),
      title: 'Goals',
      content: goals.isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : goals.activeGoals.isEmpty
          ? Text(
        'No active goals',
        style: Theme
            .of(context)
            .textTheme
            .bodyMedium,
      )
          : Column(
        children: goals.activeGoals
            .take(3) // Show only 3 goals like in React example
            .map((goal) => _buildGoalItem(context, goal))
            .toList(),
      ),
    );
  }



  Widget _buildGoalItem(BuildContext context, FitnessGoal goal) {
    final progressPercentage = goal.progressPercentage.round();
    final goalTitle = _formatGoalTitle(goal);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal title and percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goalTitle,
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '$progressPercentage%',
                style: Theme
                    .of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          CustomProgressBar(
            progress: goal.progressPercentage,
          ),
        ],
      ),
    );
  }

  String _formatGoalTitle(FitnessGoal goal) {
    final unit = _getUnitForGoalType(goal.type);
    final targetFormatted = _formatTargetValue(goal.target, goal.type);

    switch (goal.type) {
      case GoalType.distance:
        return 'Run $targetFormatted$unit this week';
      case GoalType.duration:
        return 'Run for $targetFormatted$unit this week';
      case GoalType.frequency:
        return 'Complete ${goal.target.toInt()} runs';
      case GoalType.calories:
        return 'Burn $targetFormatted$unit';
      case GoalType.pace:
        return 'Achieve $targetFormatted$unit pace';
      default:
        return 'Unknown goal type';
    }
  }

  String _formatTargetValue(double value, GoalType type) {
    switch (type) {
      case GoalType.distance:
        return value.toStringAsFixed(1);
      case GoalType.duration:
        return '${value.toInt()}';
      case GoalType.frequency:
        return '${value.toInt()}';
      case GoalType.calories:
        return '${value.toInt()}';
      case GoalType.pace:
        return value.toStringAsFixed(2);
    }
  }

  String _getUnitForGoalType(GoalType type) {
    switch (type) {
      case GoalType.distance:
        return 'km';
      case GoalType.duration:
        return 'min';
      case GoalType.frequency:
        return '';
      case GoalType.calories:
        return 'cal';
      case GoalType.pace:
        return 'min/km';
    }
  }

  Widget _buildPersonalRecordsCard(BuildContext context) {
    final analytics = context.watch<AnalyticsViewModel>();
    print(analytics);
    final records = analytics.personalRecords;

    if (analytics.isLoading) {
      return const Card(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text('Personal Records',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge,
            ),
          ),
          const Divider(color: AppColors.textSecondary),
          if (records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No records yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              children: [
                // Find specific records
                _buildRecordItem(
                  'Longest Run',
                  records
                      .firstWhere(
                        (r) => r.category == 'Longest Run',
                    orElse: () =>
                        PersonalRecord(
                          category: 'Longest Run',
                          value: 0,
                          displayValue: '0.0 km',
                          achievedDate: DateTime.now(),
                        ),
                  )
                      .displayValue,
                ),
                _buildRecordItem(
                  'Best Pace',
                  records
                      .firstWhere(
                        (r) => r.category == 'Fastest Pace',
                    orElse: () =>
                        PersonalRecord(
                          category: 'Fastest Pace',
                          value: 0,
                          displayValue: '0:00 /km',
                          achievedDate: DateTime.now(),
                        ),
                  )
                      .displayValue,
                ),
                _buildRecordItem(
                  'Longest Duration',
                  records
                      .firstWhere(
                        (r) => r.category == 'Longest Duration',
                    orElse: () =>
                        PersonalRecord(
                          category: 'Longest Duration',
                          value: 0,
                          displayValue: '0h 0m',
                          achievedDate: DateTime.now(),
                        ),
                  )
                      .displayValue,
                ),
                _buildRecordItem(
                  'Most Distance (Week)',
                  records
                      .firstWhere(
                        (r) => r.category == 'Weekly Distance',
                    orElse: () =>
                        PersonalRecord(
                          category: 'Weekly Distance',
                          value: 0,
                          displayValue: '0.0 km',
                          achievedDate: DateTime.now(),
                        ),
                  )
                      .displayValue,
                ),
              ],
            ),
        ],
      ),
    );
  }


  Widget _buildRecordItem(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }


  Widget _buildStatisticsCard(BuildContext context) {
    final analytics = context.watch<AnalyticsViewModel>();

    return DashboardCard(
      icon: const Icon(Icons.bar_chart, color: Colors.white, size: 24),
      title: 'Statistics',
      content: analytics.isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStatItem(
            context,
            'Total Distance',
            '${analytics.totalDistance.toStringAsFixed(1)}km',
          ),
          _buildStatItem(
            context,
            'Total Runs',
            analytics.totalRuns.toString(),
          ),
          _buildStatItem(
            context,
            'Avg Pace',
            analytics.averagePace ?? '0:00/km',
          ),
          _buildStatItem(
            context,
            'Best Pace',
            analytics.bestPace ?? '0:00/km',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalTrainingCard(BuildContext context) {
    return DashboardCard(
      icon: const Icon(Icons.timer, color: Colors.white, size: 24),
      title: 'Interval Training',
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardHoverBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Session',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '5x400m repeats',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            Text(
              '2 min recovery between sets',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IntervalTrainingScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text('Start Workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(BuildContext context) {
    final achievements = context.watch<AchievementsViewModel>();

    return DashboardCard(
      icon: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
      title: 'Achievements',
      content: achievements.isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : achievements.achievements.isEmpty
          ? Text(
        'No achievements yet',
        style: Theme
            .of(context)
            .textTheme
            .bodyMedium,
      )
          : Column(
        children: achievements.achievements
            .take(2) // Show only recent achievements
            .map((achievement) => _buildAchievementItem(context, achievement))
            .toList(),
      ),
    );
  }

  Widget _buildAchievementItem(BuildContext context, Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardHoverBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Achievement Title
          Expanded(
            child: Text(
              achievement.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ),

          // Achievement Date
          Text(
            _formatAchievementDate(achievement.unlockedAt!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAchievementDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}