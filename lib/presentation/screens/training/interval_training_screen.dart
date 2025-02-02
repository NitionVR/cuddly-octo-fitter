import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/interval_workout.dart';
import '../../viewmodels/training/interval_training_view_model.dart';


class IntervalTrainingScreen extends StatelessWidget {
  const IntervalTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IntervalTrainingViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Interval Training'),
          ),
          body: viewModel.currentWorkout == null
              ? _buildWorkoutSelection(context, viewModel)
              : _buildActiveWorkout(context, viewModel),
        );
      },
    );
  }

  Widget _buildWorkoutSelection(
      BuildContext context,
      IntervalTrainingViewModel viewModel
      ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Select Workout',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        _buildWorkoutCard(
          context,
          viewModel,
          IntervalWorkout.basic(),
        ),
        const SizedBox(height: 12),
        _buildWorkoutCard(
          context,
          viewModel,
          IntervalWorkout.pyramid(),
        ),
      ],
    );
  }

  Widget _buildWorkoutCard(
      BuildContext context,
      IntervalTrainingViewModel viewModel,
      IntervalWorkout workout,
      ) {
    return Card(
      child: InkWell(
        onTap: () => viewModel.startWorkout(workout),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                workout.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(workout.description),
              const SizedBox(height: 8),
              Text(
                'Total Time: ${workout.totalDuration.inMinutes} minutes',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveWorkout(
      BuildContext context,
      IntervalTrainingViewModel viewModel
      ) {
    final currentSegment = viewModel.currentSegment;
    if (currentSegment == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          currentSegment.description,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        Text(
          viewModel.formatTimeRemaining(),
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 16),
        Text(
          'Round ${viewModel.currentRepetition}/${viewModel.currentWorkout?.repetitions}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!viewModel.isRunning)
              FloatingActionButton.large(
                onPressed: viewModel.resumeWorkout,
                child: const Icon(Icons.play_arrow),
              )
            else
              FloatingActionButton.large(
                onPressed: viewModel.pauseWorkout,
                child: const Icon(Icons.pause),
              ),
            const SizedBox(width: 32),
            FloatingActionButton(
              onPressed: viewModel.stopWorkout,
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop),
            ),
          ],
        ),
      ],
    );
  }
}