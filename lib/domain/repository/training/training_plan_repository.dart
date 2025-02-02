import '../../entities/training/training_plan.dart';

abstract class ITrainingPlanRepository {
  Future<List<TrainingPlan>> getAvailablePlans();
  Future<TrainingPlan?> getActivePlan(String userId);
  Future<TrainingPlan> startPlan(String userId, String planId);
  Future<void> completePlan(String userId, String planId);
  Future<void> updateWorkoutStatus(String userId, String weekId, String workoutId, bool completed);
  Future<void> clearUserData(String userId); // Optional: Add if needed
}