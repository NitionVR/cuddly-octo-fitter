class DatabaseConfig {
  static const String databaseName = 'tracking_history.db';
  static const int currentVersion = 9;


  static const bool enableLogging = true;
  static const Duration migrationTimeout = Duration(minutes: 5);
  static const int maxRetries = 3;

  static const String tableTrackingHistory = 'tracking_history';
  static const String tableFitnessGoals = 'fitness_goals';
  static const String tableAchievements = 'achievements';
  static const String tableTrainingPlans = 'training_plans';
  static const String tableCompletedWorkouts = 'completed_workouts';
  static const String tableWorkouts = 'workouts';
}

