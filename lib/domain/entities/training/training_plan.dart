import 'package:mobile_project_fitquest/domain/entities/training/training_week.dart';

import '../../enums/difficulty_level.dart';
import '../../enums/workout_intensity.dart';
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
  final List<String> _completedWorkouts; // Add this field

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
    List<String>? completedWorkouts, // Add this parameter
  }) : _completedWorkouts = completedWorkouts ?? [];

  List<String> get completedWorkouts => List.unmodifiable(_completedWorkouts);

  bool isWorkoutCompleted(String workoutId) => _completedWorkouts.contains(workoutId);

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
      'completedWorkouts': _completedWorkouts, // Add this field
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
      completedWorkouts: (map['completedWorkouts'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [], // Add this field
    );
  }

  // Helper method to get progress
  double get progress {
    final totalWorkouts = weeks
        .expand((week) => week.workouts)
        .length;
    return totalWorkouts > 0 ? _completedWorkouts.length / totalWorkouts : 0.0;
  }

  // Helper method to get completed workouts count
  int get completedWorkoutsCount => _completedWorkouts.length;

  // Helper method to get total workouts count
  int get totalWorkouts => weeks.expand((week) => week.workouts).length;

  // Create a new instance with updated completed workouts
  TrainingPlan copyWith({
    String? id,
    String? title,
    String? description,
    int? durationWeeks,
    DifficultyLevel? difficulty,
    List<TrainingWeek>? weeks,
    WorkoutType? type,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    bool? isCustom,
    String? createdBy,
    List<String>? completedWorkouts,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      difficulty: difficulty ?? this.difficulty,
      weeks: weeks ?? this.weeks,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
      isCustom: isCustom ?? this.isCustom,
      createdBy: createdBy ?? this.createdBy,
      completedWorkouts: completedWorkouts ?? List.from(_completedWorkouts),
    );
  }

  // Method to mark a workout as completed
  TrainingPlan markWorkoutCompleted(String workoutId) {
    if (_completedWorkouts.contains(workoutId)) return this;
    return copyWith(
      completedWorkouts: [..._completedWorkouts, workoutId],
    );
  }

  // Method to mark a workout as not completed
  TrainingPlan markWorkoutNotCompleted(String workoutId) {
    if (!_completedWorkouts.contains(workoutId)) return this;
    return copyWith(
      completedWorkouts: _completedWorkouts.where((id) => id != workoutId).toList(),
    );
  }
}


