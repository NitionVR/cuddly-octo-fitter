import '../../entities/goals/fitness_goal.dart';

abstract class GoalsRepository {
  Future<List<FitnessGoal>> getUserGoals(String userId);
  Future<FitnessGoal> createGoal(FitnessGoal goal);
  Future<void> updateGoal(FitnessGoal goal);
  Future<void> deleteGoal(String goalId);
  Future<void> updateGoalProgress(String goalId, double progress);
  Stream<List<FitnessGoal>> activeGoalsStream(String userId);
}