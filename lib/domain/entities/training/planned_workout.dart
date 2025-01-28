import '../../enums/workout_intensity.dart';
import '../../enums/workout_type.dart';

class PlannedWorkout {
  final int dayOfWeek;
  final String title;
  final WorkoutType type;
  final Duration targetDuration;
  final double? targetDistance;
  final String? targetPace;
  final String description;
  final WorkoutIntensity intensity;

  PlannedWorkout({
    required this.dayOfWeek,
    required this.title,
    required this.type,
    required this.targetDuration,
    this.targetDistance,
    this.targetPace,
    required this.description,
    required this.intensity,
  });

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'title': title,
      'type': type.toString(),
      'targetDuration': targetDuration.inMinutes,
      'targetDistance': targetDistance,
      'targetPace': targetPace,
      'description': description,
      'intensity': intensity.toString(),
    };
  }

  factory PlannedWorkout.fromMap(Map<String, dynamic> map) {
    return PlannedWorkout(
      dayOfWeek: map['dayOfWeek'],
      title: map['title'],
      type: WorkoutType.values.firstWhere(
            (e) => e.toString() == map['type'],
      ),
      targetDuration: Duration(minutes: map['targetDuration']),
      targetDistance: map['targetDistance'],
      targetPace: map['targetPace'],
      description: map['description'],
      intensity: WorkoutIntensity.values.firstWhere(
            (e) => e.toString() == map['intensity'],
      ),
    );
  }
}