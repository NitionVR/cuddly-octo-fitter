// lib/domain/usecases/goals/create_goal_usecase.dart
import '../../entities/goals/fitness_goal.dart';
import '../../repository/goals/goals_repository.dart';

class CreateGoalUseCase {
  final IGoalsRepository _repository;

  CreateGoalUseCase(this._repository);

  Future<FitnessGoal> call(FitnessGoal goal) async {
    return await _repository.createGoal(goal);
  }
}

// lib/domain/usecases/goals/get_user_goals_usecase.dart
class GetUserGoalsUseCase {
  final IGoalsRepository _repository;

  GetUserGoalsUseCase(this._repository);

  Future<List<FitnessGoal>> call(String userId) async {
    return await _repository.getUserGoals(userId);
  }
}

// lib/domain/usecases/goals/update_goal_progress_usecase.dart
class UpdateGoalProgressUseCase {
  final IGoalsRepository _repository;

  UpdateGoalProgressUseCase(this._repository);

  Future<void> call({
    required String userId,
    required String goalId,
    required double progress,
  }) async {
    await _repository.updateGoalProgress(userId, goalId, progress);
  }
}

// lib/domain/usecases/goals/delete_goal_usecase.dart
class DeleteGoalUseCase {
  final IGoalsRepository _repository;

  DeleteGoalUseCase(this._repository);

  Future<void> call(String userId, String goalId) async {
    await _repository.deleteGoal(userId, goalId);
  }
}

// lib/domain/usecases/goals/sync_goals_usecase.dart
class SyncGoalsUseCase {
  final IGoalsRepository _repository;

  SyncGoalsUseCase(this._repository);

  Future<void> call(String userId) async {
    await _repository.syncGoals(userId);
  }
}

// lib/domain/usecases/goals/watch_active_goals_usecase.dart
class WatchActiveGoalsUseCase {
  final IGoalsRepository _repository;

  WatchActiveGoalsUseCase(this._repository);

  Stream<List<FitnessGoal>> call(String userId) {
    return _repository.activeGoalsStream(userId);
  }
}