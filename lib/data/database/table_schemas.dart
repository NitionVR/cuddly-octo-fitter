
class TableSchemas {
  static const String trackingHistory = '''
    CREATE TABLE tracking_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      last_sync TEXT,
      user_id TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      route TEXT NOT NULL,
      total_distance REAL,
      duration INTEGER,
      pace_seconds INTEGER DEFAULT 0
    )
  ''';

  static const String fitnessGoals = '''
    CREATE TABLE fitness_goals (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      type TEXT NOT NULL,
      period TEXT NOT NULL,
      target REAL NOT NULL,
      currentProgress REAL DEFAULT 0.0,
      startDate TEXT NOT NULL,
      endDate TEXT NOT NULL,
      isCompleted INTEGER DEFAULT 0,
      lastUpdated TEXT NOT NULL,
      isActive INTEGER DEFAULT 1,
      FOREIGN KEY (userId) REFERENCES users(id)
    )
  ''';

  static const String achievements = '''
        CREATE TABLE achievements (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          type TEXT NOT NULL,
          unlockedAt TEXT,
          criteria TEXT,
          icon TEXT,
          isHidden INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL,
          lastUpdated TEXT NOT NULL
        )
      ''';

  static const String trainingPlans = '''
        CREATE TABLE training_plans (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          durationWeeks INTEGER NOT NULL,
          difficulty TEXT NOT NULL,
          type TEXT NOT NULL,
          weeks TEXT NOT NULL,
          imageUrl TEXT,
          metadata TEXT,
          isCustom INTEGER DEFAULT 0,
          isTemplate INTEGER DEFAULT 0,
          isActive INTEGER DEFAULT 1,
          startDate TEXT,
          completedDate TEXT,
          createdBy TEXT,
          lastUpdated TEXT
        )
      ''';

  static const completedWorkouts = '''
        CREATE TABLE completed_workouts (
          userId TEXT NOT NULL,
          weekId TEXT NOT NULL,
          workoutId TEXT NOT NULL,
          completed INTEGER NOT NULL,
          completedAt TEXT,
          PRIMARY KEY (userId, workoutId)
        )
      ''';

  static const String workouts = '''
    CREATE TABLE workouts (
      id TEXT PRIMARY KEY,
      userId TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      route TEXT NOT NULL,
      totalDistance REAL NOT NULL,
      duration INTEGER NOT NULL,
      avgPace TEXT NOT NULL,
      averageSpeed REAL,
      caloriesBurned REAL,
      elevationGain REAL,
      type TEXT NOT NULL,
      notes TEXT,
      isSynced INTEGER DEFAULT 0,
      lastModified TEXT NOT NULL
    )
  ''';

  static const String workoutsIndex = '''
    CREATE INDEX idx_workouts_user_date 
    ON workouts(userId, timestamp)
  ''';

// ... other table schemas ...
}