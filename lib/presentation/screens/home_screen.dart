import 'package:flutter/material.dart';
import 'package:mobile_project_fitquest/domain/repository/achievements_repository.dart';
import 'package:provider/provider.dart';
import '../../data/models/weekly_summary.dart';
import '../../domain/entities/goals/fitness_goal.dart';
import '../../domain/repository/goals/goals_repository.dart';
import '../../domain/repository/tracking/tracking_repository.dart';
import '../../theme/app_theme.dart';
import '../viewmodels/achievements_viewmodel.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/goals/goals_view_model.dart';
import '../viewmodels/tracking/map_view_model.dart';
import '../viewmodels/analytics_view_model.dart';
import 'tracking/map_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'achievements_screen.dart';
import 'goals/goals_screen.dart';
import 'training/active_plan_screen.dart';
import 'training/interval_training_screen.dart';
import 'training/plan_details_screen.dart';
import 'training/training_plan_screens.dart';




class HomeScreen extends StatelessWidget {
  final TrackingRepository _trackingRepository;
  final GoalsRepository _goalsRepository;
  final AchievementsRepository _achievementsRepository;

  // Constructor to inject the dependencies
  HomeScreen({
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
      child: HomeScreenContent(),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecentActivitiesCard(context),
          SizedBox(height: 16),
          _buildGoalsCard(context),
          SizedBox(height: 16),
          _buildPersonalRecordsCard(context),
          SizedBox(height: 16),
          _buildQuickStatsRow(context),
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
          return Card(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Center(
              child: Text(
                "Error loading recent activities: ${snapshot.error}",
                style: TextStyle(color: AppColors.textPrimary),
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
                    MaterialPageRoute(builder: (_) => HistoryScreen()),
                  ),
                  child: Text('More', style: TextStyle(color: AppColors.accentGreen)),
                ),
              ),
              Divider(color: AppColors.textSecondary),
              if (recentActivities.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No recent activities',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...recentActivities.map((activity) => _buildActivityItem(activity)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    print("activity");
    print(activity); //manual logging
    final timestamp = activity['timestamp'];
    final duration = activity['duration'];
    final totalDistance = activity['total_distance'] ?? 5; // Handle null totalDistance
    final avgPace = activity['avg_pace'];

    print(avgPace.toString());

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.directions_run, color: AppColors.accentGreen),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Date: ${_formatTimestamp(timestamp)}",
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                SizedBox(height: 4),
                Text(
                  "${totalDistance.toStringAsFixed(2)} km • ${_formatDuration(duration)} • $avgPace min/km",
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Text(
            _formatTimeDifference(timestamp),
            style: TextStyle(color: AppColors.textSecondary),
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
              child: Text('More', style: TextStyle(color: AppColors.accentGreen)),
            ),
          ),
          Divider(color: AppColors.textSecondary),
          if (goals.isLoading)
            Center(child: CircularProgressIndicator())
          else if (goals.activeGoals.isEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('No active goals',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            Padding(
              padding: EdgeInsets.all(16),
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
        SizedBox(width: 8),
        Expanded(
          child: _buildQuickStatCard('Active Streak', '3 days'),
        ),
        SizedBox(width: 8),
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
          Divider(color: AppColors.textSecondary),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            padding: EdgeInsets.all(16),
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

  // ... Rest of the widget implementations ...

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}';
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
        Text(label, style: TextStyle(color: AppColors.textPrimary)),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.progressBackground,
          color: AppColors.progressBar,
        ),
        SizedBox(height: 4),
        Text(status, style: TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }


  Widget _buildRecordItem(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }



  Widget _buildQuickStatCard(String label, String value) {
    return Card(
      color: AppColors.cardDark,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}