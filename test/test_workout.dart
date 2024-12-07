// test/domain/entities/workout_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_project_fitquest/domain/entities/workout.dart';
import 'package:mobile_project_fitquest/domain/enums/workout_type.dart';


void main() {
  group('Workout', () {
    test('should create a new Workout instance with optional properties', () {
      final workout = Workout(
        id: '1',
        userId: 'user1',
        timestamp: DateTime(2023, 5, 1, 10, 30),
        route: [
          LatLng(40.730610, -73.935242),
          LatLng(40.730810, -73.935442),
        ],
        totalDistance: 1.2,
        duration: 600,
        avgPace: '5:00',
        averageSpeed: 10.0,
        caloriesBurned: 500.0,
        elevationGain: 50.0,
        type: WorkoutType.cycle,
        notes: 'This was a great ride!',
      );

      expect(workout.id, '1');
      expect(workout.userId, 'user1');
      expect(workout.timestamp, DateTime(2023, 5, 1, 10, 30));
      expect(workout.route, [
        LatLng(40.730610, -73.935242),
        LatLng(40.730810, -73.935442),
      ]);
      expect(workout.totalDistance, 1.2);
      expect(workout.duration, 600);
      expect(workout.avgPace, '5:00');
      expect(workout.averageSpeed, 10.0);
      expect(workout.caloriesBurned, 500.0);
      expect(workout.elevationGain, 50.0);
      expect(workout.type, WorkoutType.cycle);
      expect(workout.notes, 'This was a great ride!');
    });

    test('should serialize and deserialize a Workout instance with optional properties', () {
      final workout = Workout(
        id: '1',
        userId: 'user1',
        timestamp: DateTime(2023, 5, 1, 10, 30),
        route: [
          LatLng(40.730610, -73.935242),
          LatLng(40.730810, -73.935442),
        ],
        totalDistance: 1.2,
        duration: 600,
        avgPace: '5:00',
        averageSpeed: 10.0,
        caloriesBurned: 500.0,
        elevationGain: 50.0,
        type: WorkoutType.cycle,
        notes: 'This was a great ride!',
      );

      final map = workout.toMap();
      final deserializedWorkout = Workout.fromMap(map);

      expect(deserializedWorkout.id, workout.id);
      expect(deserializedWorkout.userId, workout.userId);
      expect(deserializedWorkout.timestamp, workout.timestamp);
      expect(deserializedWorkout.route, workout.route);
      expect(deserializedWorkout.totalDistance, workout.totalDistance);
      expect(deserializedWorkout.duration, workout.duration);
      expect(deserializedWorkout.avgPace, workout.avgPace);
      expect(deserializedWorkout.averageSpeed, workout.averageSpeed);
      expect(deserializedWorkout.caloriesBurned, workout.caloriesBurned);
      expect(deserializedWorkout.elevationGain, workout.elevationGain);
      expect(deserializedWorkout.type, workout.type);
      expect(deserializedWorkout.notes, workout.notes);
    });
  });
}