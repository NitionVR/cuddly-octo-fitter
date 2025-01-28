import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/entities/achievement.dart';
import '../../../../theme/app_colors.dart';
import '../../../viewmodels/achievements_viewmodel.dart';
import '../../../widgets/dashboard_card.dart';
import '../utils/date_formatter.dart';

class AchievementsCard extends StatelessWidget {
  const AchievementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = context.watch<AchievementsViewModel>();

    return DashboardCard(
      icon: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
      title: 'Achievements',
      content: achievements.isLoading
          ? const _LoadingState()
          : achievements.achievements.isEmpty
          ? const _EmptyState()
          : _AchievementsList(
        achievements: achievements.achievements.take(2).toList(),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Text(
      'No achievements yet',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _AchievementsList extends StatelessWidget {
  final List<Achievement> achievements;

  const _AchievementsList({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: achievements
          .map((achievement) => _AchievementItem(achievement: achievement))
          .toList(),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final Achievement achievement;

  const _AchievementItem({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _AnimatedAchievement(
        child: InkWell(
          onTap: () => _showAchievementDetails(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardHoverBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _AchievementIcon(type: achievement.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateFormatter.formatAchievementDate(achievement.unlockedAt!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (achievement.isNew) const _NewBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _AchievementDetailsSheet(achievement: achievement),
    );
  }
}

class _AnimatedAchievement extends StatefulWidget {
  final Widget child;

  const _AnimatedAchievement({required this.child});

  @override
  _AnimatedAchievementState createState() => _AnimatedAchievementState();
}

class _AnimatedAchievementState extends State<_AnimatedAchievement>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _AchievementIcon extends StatelessWidget {
  final AchievementType type;

  const _AchievementIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.buttonPrimary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getIconData(),
        color: AppColors.buttonPrimary,
        size: 20,
      ),
    );
  }

  IconData _getIconData() {
    switch (type) {
      case AchievementType.totalDistance:
        return Icons.straighten;
      case AchievementType.totalWorkouts:
        return Icons.fitness_center;
      case AchievementType.longestWorkout:
        return Icons.timer;
      case AchievementType.fastestPace:
        return Icons.speed;
      case AchievementType.streakDays:
        return Icons.local_fire_department;
      case AchievementType.elevationGain:
        return Icons.terrain;
      case AchievementType.specialEvent:
        return Icons.star;
      case AchievementType.milestone:
        return Icons.emoji_events;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case AchievementType.totalDistance:
      case AchievementType.totalWorkouts:
        return Colors.blue;
      case AchievementType.longestWorkout:
      case AchievementType.fastestPace:
        return Colors.green;
      case AchievementType.streakDays:
        return Colors.orange;
      case AchievementType.elevationGain:
        return Colors.purple;
      case AchievementType.specialEvent:
        return Colors.amber;
      case AchievementType.milestone:
        return Colors.red;
    }
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.buttonPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AchievementDetailsSheet extends StatelessWidget {
  final Achievement achievement;

  const _AchievementDetailsSheet({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AchievementIcon(type: achievement.type),
          const SizedBox(height: 16),
          Text(
            achievement.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Unlocked on ${DateFormatter.formatAchievementDate(achievement.unlockedAt!)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}