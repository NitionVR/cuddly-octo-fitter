import 'package:mobile_project_fitquest/domain/entities/training/planned_workout.dart';

class TrainingWeek {
  final int weekNumber;
  final List<PlannedWorkout> workouts;
  final String? notes;

  TrainingWeek({
    required this.weekNumber,
    required this.workouts,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'workouts': workouts.map((w) => w.toMap()).toList(),
      'notes': notes,
    };
  }

  factory TrainingWeek.fromMap(Map<String, dynamic> map) {
    return TrainingWeek(
      weekNumber: map['weekNumber'],
      workouts: (map['workouts'] as List)
          .map((w) => PlannedWorkout.fromMap(w))
          .toList(),
      notes: map['notes'],
    );
  }
}