// lib/domain/usecases/training/get_available_plans_usecase.dart
import '../../entities/training/training_plan.dart';
import '../../repository/training/training_plan_repository.dart';

class GetAvailablePlansUseCase {
  final ITrainingPlanRepository _repository;

  GetAvailablePlansUseCase(this._repository);

  Future<List<TrainingPlan>> call() async {
    return await _repository.getAvailablePlans();
  }
}

// lib/domain/usecases/training/get_active_plan_usecase.dart
class GetActivePlanUseCase {
  final ITrainingPlanRepository _repository;

  GetActivePlanUseCase(this._repository);

  Future<TrainingPlan?> call(String userId) async {
    return await _repository.getActivePlan(userId);
  }
}

// lib/domain/usecases/training/start_plan_usecase.dart
class StartPlanUseCase {
  final ITrainingPlanRepository _repository;

  StartPlanUseCase(this._repository);

  Future<TrainingPlan> call(String userId, String planId) async {
    return await _repository.startPlan(userId, planId);
  }
}

// lib/domain/usecases/training/complete_plan_usecase.dart
class CompletePlanUseCase {
  final ITrainingPlanRepository _repository;

  CompletePlanUseCase(this._repository);

  Future<void> call(String userId, String planId) async {
    await _repository.completePlan(userId, planId);
  }
}

// lib/domain/usecases/training/update_workout_status_usecase.dart
class UpdateWorkoutStatusUseCase {
  final ITrainingPlanRepository _repository;

  UpdateWorkoutStatusUseCase(this._repository);

  Future<void> call({
    required String userId,
    required String weekId,
    required String workoutId,
    required bool completed,
  }) async {
    await _repository.updateWorkoutStatus(
      userId,
      weekId,
      workoutId,
      completed,
    );
  }
}

// lib/domain/usecases/training/clear_training_data_usecase.dart
class ClearTrainingDataUseCase {
  final ITrainingPlanRepository _repository;

  ClearTrainingDataUseCase(this._repository);

  Future<void> call(String userId) async {
    await _repository.clearUserData(userId);
  }
}

// Optional: Combined use case for plan progress
// lib/domain/usecases/training/get_plan_progress_usecase.dart
class GetPlanProgressUseCase {
  final ITrainingPlanRepository _repository;

  GetPlanProgressUseCase(this._repository);

  Future<PlanProgress> call(String userId) async {
    final activePlan = await _repository.getActivePlan(userId);
    if (activePlan == null) {
      return PlanProgress.empty();
    }

    return PlanProgress(
      totalWorkouts: activePlan.totalWorkouts,
      completedWorkouts: activePlan.completedWorkoutsCount,
      progressPercentage: activePlan.progress * 100,
      plan: activePlan,
    );
  }
}

// lib/domain/models/plan_progress.dart
class PlanProgress {
  final int totalWorkouts;
  final int completedWorkouts;
  final double progressPercentage;
  final TrainingPlan? plan;

  const PlanProgress({
    required this.totalWorkouts,
    required this.completedWorkouts,
    required this.progressPercentage,
    this.plan,
  });

  factory PlanProgress.empty() {
    return const PlanProgress(
      totalWorkouts: 0,
      completedWorkouts: 0,
      progressPercentage: 0,
      plan: null,
    );
  }
}