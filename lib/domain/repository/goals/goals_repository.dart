import '../../entities/goals/fitness_goal.dart';

abstract class GoalsRepository {
  Future<List<FitnessGoal>> getUserGoals(String userId);
  Future<FitnessGoal> createGoal(FitnessGoal goal);
  Future<void> updateGoal(FitnessGoal goal);
  Future<void> updateGoalProgress(String userId, String goalId, double progress);
  Future<void> deleteGoal(String userId, String goalId);
  Stream<List<FitnessGoal>> activeGoalsStream(String userId);
}