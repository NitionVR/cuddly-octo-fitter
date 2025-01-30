// lib/presentation/screens/home/components/goals_card.dart
import 'package:flutter/material.dart';
import 'package:mobile_project_fitquest/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/goals/fitness_goal.dart';
import '../../../../domain/enums/goal_type.dart';
import '../../../../theme/app_colors.dart';
import '../../../viewmodels/goals/goals_view_model.dart';
import '../../../widgets/custom_progress_bar.dart';
import '../../../widgets/dashboard_card.dart';

class GoalsCard extends StatelessWidget {
  final VoidCallback? onTap;

  const GoalsCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsViewModel>();

    return DashboardCard(
      icon: const Icon(Icons.track_changes, color: Colors.white, size: 24),
      title: 'Goals',
      onTap: onTap,
      content: goals.isLoading
          ? const _LoadingState()
          : goals.activeGoals.isEmpty
          ? const _EmptyState()
          : _GoalsList(goals: goals.activeGoals),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Text(
      'No active goals',
      style: AppTheme.darkTheme.textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }
}

class _GoalsList extends StatelessWidget {
  final List<FitnessGoal> goals;

  const _GoalsList({required this.goals});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: goals
          .take(3)
          .map((goal) => _GoalItem(goal: goal))
          .toList(),
    );
  }
}

class _GoalItem extends StatelessWidget {
  final FitnessGoal goal;

  const _GoalItem({required this.goal});

  @override
  Widget build(BuildContext context) {
    final progressPercentage = goal.progressPercentage.round();
    final goalTitle = _formatGoalTitle();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GoalHeader(
            title: goalTitle,
            progress: progressPercentage,
          ),
          const SizedBox(height: 8),
          CustomProgressBar(
            progress: goal.progressPercentage,
          ),
        ],
      ),
    );
  }

  String _formatGoalTitle() {
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
    }
  }

  String _formatTargetValue(double value, GoalType type) {
    switch (type) {
      case GoalType.distance:
        return value.toStringAsFixed(1);
      case GoalType.duration:
      case GoalType.frequency:
      case GoalType.calories:
        return value.toInt().toString();
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
}

class _GoalHeader extends StatelessWidget {
  final String title;
  final int progress;

  const _GoalHeader({
    required this.title,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        Text(
          '$progress%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// Optional: Add this for goal type icons
class GoalTypeIcon extends StatelessWidget {
  final GoalType type;
  final double size;
  final Color? color;

  const GoalTypeIcon({
    super.key,
    required this.type,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      _getIconData(),
      size: size,
      color: color ?? Colors.white,
    );
  }

  IconData _getIconData() {
    switch (type) {
      case GoalType.distance:
        return Icons.straighten;
      case GoalType.duration:
        return Icons.timer;
      case GoalType.frequency:
        return Icons.repeat;
      case GoalType.calories:
        return Icons.local_fire_department;
      case GoalType.pace:
        return Icons.speed;
    }
  }
}

// Optional: Add this for goal progress animations
class AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.progress,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: duration,
      builder: (context, value, _) {
        return CustomProgressBar(progress: value);
      },
    );
  }
}