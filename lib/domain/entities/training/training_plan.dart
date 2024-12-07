
import '../../enums/workout_type.dart';

class TrainingPlan {
  final String id;
  final String title;
  final String description;
  final int durationWeeks;
  final DifficultyLevel difficulty;
  final List<TrainingWeek> weeks;
  final WorkoutType type;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final bool isCustom;
  final String? createdBy;

  TrainingPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.durationWeeks,
    required this.difficulty,
    required this.weeks,
    required this.type,
    this.imageUrl,
    this.metadata,
    this.isCustom = false,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'durationWeeks': durationWeeks,
      'difficulty': difficulty.toString(),
      'weeks': weeks.map((w) => w.toMap()).toList(),
      'type': type.toString(),
      'imageUrl': imageUrl,
      'metadata': metadata,
      'isCustom': isCustom,
      'createdBy': createdBy,
    };
  }

  factory TrainingPlan.fromMap(Map<String, dynamic> map) {
    return TrainingPlan(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      durationWeeks: map['durationWeeks'],
      difficulty: DifficultyLevel.values.firstWhere(
            (e) => e.toString() == map['difficulty'],
      ),
      weeks: (map['weeks'] as List)
          .map((w) => TrainingWeek.fromMap(w))
          .toList(),
      type: WorkoutType.values.firstWhere(
            (e) => e.toString() == map['type'],
      ),
      imageUrl: map['imageUrl'],
      metadata: map['metadata'],
      isCustom: map['isCustom'] ?? false,
      createdBy: map['createdBy'],
    );
  }
}

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

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert
}

enum WorkoutIntensity {
  recovery,
  easy,
  moderate,
  hard,
  veryHard
}