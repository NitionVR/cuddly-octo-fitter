/*
* Tests for Interval Training View Model
*
* Purpose: Verify workout execution logic:
* - Workout control (start/pause/resume/stop)
* - Interval timing and transitions
* - Workout completion
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project_fitquest/domain/entities/interval_workout.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/training/interval_training_view_model.dart';

void main() {
  late IntervalTrainingViewModel viewModel;

  setUp(() {
    viewModel = IntervalTrainingViewModel();
  });

  group('Workout Controls', () {
    test('starts workout correctly', () {
      final workout = IntervalWorkout.basic();
      viewModel.startWorkout(workout);

      expect(viewModel.isRunning, true);
      expect(viewModel.currentSegmentIndex, 0);
      expect(viewModel.currentRepetition, 1);
      expect(viewModel.currentWorkout, workout);
    });

    test('pauses and resumes workout', () async {
      final workout = IntervalWorkout.basic();
      viewModel.startWorkout(workout);

      viewModel.pauseWorkout();
      expect(viewModel.isRunning, false);

      viewModel.resumeWorkout();
      expect(viewModel.isRunning, true);
    });

    test('stops workout and resets state', () {
      final workout = IntervalWorkout.basic();
      viewModel.startWorkout(workout);
      viewModel.stopWorkout();

      expect(viewModel.isRunning, false);
      expect(viewModel.currentWorkout, null);
      expect(viewModel.currentSegmentIndex, 0);
      expect(viewModel.currentRepetition, 1);
    });
  });

  group('Interval Timing', () {
    test('formats time remaining correctly', () {
      final workout = IntervalWorkout.basic();
      viewModel.startWorkout(workout);

      expect(viewModel.formatTimeRemaining(), '1:00');
    });

    test('advances to next segment after duration', () async {
      final workout = IntervalWorkout(
        name: 'Test',
        segments: [
          IntervalSegment(
            type: IntervalType.running,
            duration: Duration(seconds: 1),
          ),
          IntervalSegment(
            type: IntervalType.recovery,
            duration: Duration(seconds: 1),
          ),
        ],
      );

      viewModel.startWorkout(workout);
      await Future.delayed(Duration(seconds: 2));

      expect(viewModel.currentSegmentIndex, 1);
    });
  });
}