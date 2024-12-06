/*
* Tests for Interval Training Models
*
* Purpose: Verify workout planning functionality:
* - Interval segment creation and validation
* - Workout template generation
* - Duration calculations
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project_fitquest/domain/entities/interval_workout.dart';

void main() {
  group('IntervalSegment', () {
    test('creates with default description', () {
      final segment = IntervalSegment(
        type: IntervalType.running,
        duration: Duration(minutes: 1),
      );

      expect(segment.description, 'Run Fast');
      expect(segment.targetPace, 0.0);
    });

    test('creates with custom values', () {
      final segment = IntervalSegment(
        type: IntervalType.recovery,
        duration: Duration(minutes: 2),
        targetPace: 5.5,
        description: 'Easy jog',
      );

      expect(segment.description, 'Easy jog');
      expect(segment.targetPace, 5.5);
      expect(segment.duration, Duration(minutes: 2));
    });
  });

  group('IntervalWorkout', () {
    test('calculates total duration correctly', () {
      final workout = IntervalWorkout(
        name: 'Test Workout',
        segments: [
          IntervalSegment(
            type: IntervalType.running,
            duration: Duration(minutes: 1),
          ),
          IntervalSegment(
            type: IntervalType.recovery,
            duration: Duration(minutes: 1),
          ),
        ],
        repetitions: 3,
      );

      expect(workout.totalDuration, Duration(minutes: 6));
    });

    test('creates basic interval template', () {
      final workout = IntervalWorkout.basic();

      expect(workout.name, 'Basic Intervals');
      expect(workout.segments.length, 2);
      expect(workout.repetitions, 8);
      expect(workout.totalDuration, Duration(minutes: 16));
    });

    test('creates pyramid interval template', () {
      final workout = IntervalWorkout.pyramid();

      expect(workout.name, 'Pyramid');
      expect(workout.segments.length, 9);
      expect(workout.repetitions, 1);
    });
  });
}