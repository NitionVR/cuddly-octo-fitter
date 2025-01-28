import 'package:flutter/material.dart';
import '../../../domain/entities/training/planned_workout.dart';
import '../../../domain/entities/training/training_plan.dart';
import '../../../domain/enums/workout_intensity.dart';


class ActivePlanScreen extends StatelessWidget {
  final TrainingPlan plan;

  const ActivePlanScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildProgress(context),
          _buildCurrentWeek(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Week ${_getCurrentWeek() + 1} of ${plan.durationWeeks}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final currentWeek = _getCurrentWeek();
    final progress = (currentWeek + 1) / plan.durationWeeks;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).round()}% Complete',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeek(BuildContext context) {
    final currentWeek = plan.weeks[_getCurrentWeek()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'This Week',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentWeek.workouts.length,
          itemBuilder: (context, index) {
            final workout = currentWeek.workouts[index];
            return _WorkoutCard(
              workout: workout,
              weekNumber: currentWeek.weekNumber,
            );
          },
        ),
        if (currentWeek.notes != null) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(currentWeek.notes!),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  int _getCurrentWeek() {
    // In a real app, you'd calculate this based on the start date
    return 0;
  }
}

class _WorkoutCard extends StatelessWidget {
  final PlannedWorkout workout;
  final int weekNumber;

  const _WorkoutCard({
    required this.workout,
    required this.weekNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Day ${workout.dayOfWeek}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildIntensityIndicator(context),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              workout.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(workout.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (workout.targetDistance != null)
                  Chip(
                    label: Text('${workout.targetDistance} km'),
                    avatar: const Icon(Icons.straighten, size: 16),
                  ),
                Chip(
                  label: Text('${workout.targetDuration.inMinutes} min'),
                  avatar: const Icon(Icons.timer, size: 16),
                ),
                if (workout.targetPace != null)
                  Chip(
                    label: Text(workout.targetPace!),
                    avatar: const Icon(Icons.speed, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _startWorkout(context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Workout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityIndicator(BuildContext context) {
    final colors = {
      WorkoutIntensity.recovery: Colors.green,
      WorkoutIntensity.easy: Colors.blue,
      WorkoutIntensity.moderate: Colors.orange,
      WorkoutIntensity.hard: Colors.red,
      WorkoutIntensity.veryHard: Colors.purple,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors[workout.intensity]!.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        workout.intensity.toString().split('.').last,
        style: TextStyle(
          color: colors[workout.intensity],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _startWorkout(BuildContext context) {
    // TODO: Navigate to workout screen with plan details
    // This will integrate with your existing workout tracking feature
  }
}