// lib/presentation/screens/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/achievement.dart';
import '../viewmodels/achievements_viewmodel.dart';

class AchievementsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Achievements'),
      ),
      body: Consumer<AchievementsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _AchievementProgress(
                  totalCount: viewModel.totalAchievements,
                  unlockedCount: viewModel.unlockedCount,
                  percentage: viewModel.completionPercentage,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Recent Achievements',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              _buildAchievementsList(viewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAchievementsList(AchievementsViewModel viewModel) {
    final achievements = viewModel.achievements;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final achievement = achievements[index];
          return _AchievementCard(achievement: achievement);
        },
        childCount: achievements.length,
      ),
    );
  }
}

class _AchievementProgress extends StatelessWidget {
  final int totalCount;
  final int unlockedCount;
  final double percentage;

  const _AchievementProgress({
    required this.totalCount,
    required this.unlockedCount,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '$unlockedCount/$totalCount',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              minHeight: 8,
            ),
            SizedBox(height: 8),
            Text(
              '${percentage.toStringAsFixed(1)}% Complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: achievement.isUnlocked
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getAchievementIcon(),
            color: Colors.white,
          ),
        ),
        title: Text(
          achievement.title,
          style: TextStyle(
            color: achievement.isUnlocked ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          achievement.description,
          style: TextStyle(
            color: achievement.isUnlocked ? null : Colors.grey,
          ),
        ),
        trailing: achievement.isUnlocked
            ? Icon(Icons.check_circle, color: Colors.green)
            : null,
        onTap: () => _showAchievementDetails(context),
      ),
    );
  }

  IconData _getAchievementIcon() {
    switch (achievement.type) {
      case AchievementType.totalDistance:
        return Icons.directions_run;
      case AchievementType.totalWorkouts:
        return Icons.fitness_center;
      case AchievementType.longestWorkout:
        return Icons.timer;
      case AchievementType.fastestPace:
        return Icons.speed;
      case AchievementType.streakDays:
        return Icons.local_fire_department;
      case AchievementType.elevationGain:
        return Icons.landscape;
      case AchievementType.specialEvent:
        return Icons.emoji_events;
      case AchievementType.milestone:
        return Icons.flag;
    }
  }

  void _showAchievementDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            SizedBox(height: 16),
            if (achievement.isUnlocked) ...[
              Text(
                'Unlocked on',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _formatDate(achievement.unlockedAt!),
              ),
            ] else ...[
              Text(
                'Progress: ${_getProgressText()}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getProgressText() {
    // TODO: Implement progress calculation based on achievement type
    return 'In Progress';
  }
}