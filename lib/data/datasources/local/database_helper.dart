import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  static Database? _database;
  static const int _currentVersion = 7;
  static const String _databaseName = 'tracking_history.db';

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final path = join(await getDatabasesPath(), _databaseName);

      try {
        return await openDatabase(
          path,
          version: _currentVersion,
          onCreate: onCreate,
          onUpgrade: onUpgrade,
          onOpen: (db) async {
            // Verify database integrity
            try {
              await db.query('sqlite_master');
            } catch (e) {
              print('Database corruption detected: $e');
              await db.close();
              await deleteDatabase(path);
              throw Exception('Database corruption detected');
            }
          },
        );
      } catch (e) {
        print('Database open failed, attempting recovery: $e');
        await deleteDatabase(path);
        return await openDatabase(
          path,
          version: _currentVersion,
          onCreate: onCreate,
          onUpgrade: onUpgrade,
        );
      }
    } catch (e) {
      print('Database initialization error: $e');
      rethrow;
    }
  }


  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', tableName],
    );
    return result.isNotEmpty;
  }


  Future<void> onCreate(Database db, int version) async {
    try {

      if (!await _tableExists(db, 'tracking_history')) {
          await db.execute('''
            CREATE TABLE tracking_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              last_sync TEXT,
              user_id TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              route TEXT NOT NULL,
              total_distance REAL,
              duration INTEGER,
              avg_pace TEXT
            )
      ''');
      }

      if (!await _tableExists(db, 'fitness_goals')) {
          await db.execute('''
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
      ''');
      }

      if (!await _tableExists(db, 'achievements')) {
          await db.execute('''
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
      ''');
      }

      if (!await _tableExists(db, 'training_plans')) {
          await db.execute('''
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
      ''');
      }

      // Update completed_workouts table creation
      if (!await _tableExists(db, 'completed_workouts')) {
          await db.execute('''
        CREATE TABLE completed_workouts (
          userId TEXT NOT NULL,
          weekId TEXT NOT NULL,
          workoutId TEXT NOT NULL,
          completed INTEGER NOT NULL,
          completedAt TEXT,
          PRIMARY KEY (userId, workoutId)
        )
      ''');
      }

      try {
          await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_achievements_userId 
          ON achievements(userId)
        ''');

          await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_achievements_unlocked 
          ON achievements(userId, unlockedAt)
        ''');


          // Add indexes for training plans
          await db.execute('''
        CREATE INDEX IF NOT idx_training_plans_user 
        ON training_plans(userId, isActive)
      ''');

          await db.execute('''
        CREATE INDEX IF NOT idx_completed_workouts_user 
        ON completed_workouts(userId, completed)
      ''');
      } catch(e){
        if (kDebugMode) {
          print('Index creation error (non-fatal): $e');
        }
      }

    } catch (e) {
      if (kDebugMode) {
        print('Database creation error: $e');
      }
      rethrow;
    }
  }

  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        await db.execute('ALTER TABLE tracking_history ADD COLUMN total_distance REAL');
        await db.execute('ALTER TABLE tracking_history ADD COLUMN duration INTEGER');
        await db.execute('ALTER TABLE tracking_history ADD COLUMN avg_pace TEXT');
      }

      if (oldVersion < 3) {
        var tableInfo = await db.rawQuery('PRAGMA table_info(tracking_history)');
        bool hasUserIdColumn = tableInfo.any((column) => column['name'] == 'user_id');

        if (!hasUserIdColumn) {
          await db.execute('ALTER TABLE tracking_history ADD COLUMN user_id TEXT');
          await db.execute("UPDATE tracking_history SET user_id = 'legacy_user' WHERE user_id IS NULL");
        }
      }

      if (oldVersion < 4) {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS fitness_goals (
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
      ''');
      }

      if (oldVersion < 5) {
        try {
          await db.execute('ALTER TABLE tracking_history DROP COLUMN last_sync');
        } catch (e) {
          // ignore if column doesn't exist
        }
        await db.execute('ALTER TABLE tracking_history ADD COLUMN last_sync TEXT');
      }

      if (oldVersion < 6) {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS achievements (
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
        ''');

        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_achievements_userId 
          ON achievements(userId)
        ''');

        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_achievements_unlocked 
          ON achievements(userId, unlockedAt)
        ''');
      }

      if (oldVersion < 7) {
        // Drop and recreate training_plans table with new fields
        await db.execute('DROP TABLE IF EXISTS training_plans');
        await db.execute('''
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
      ''');

        // Drop and recreate completed_workouts table with new fields
        await db.execute('DROP TABLE IF EXISTS completed_workouts');
        await db.execute('''
        CREATE TABLE completed_workouts (
          userId TEXT NOT NULL,
          weekId TEXT NOT NULL,
          workoutId TEXT NOT NULL,
          completed INTEGER NOT NULL,
          completedAt TEXT,
          PRIMARY KEY (userId, workoutId)
        )
      ''');

        // Create new indexes for better performance
        await db.execute('''
        CREATE INDEX idx_training_plans_user 
        ON training_plans(userId, isActive)
      ''');

        await db.execute('''
        CREATE INDEX idx_completed_workouts_user 
        ON completed_workouts(userId, completed)
      ''');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Database upgrade error: $e');
      }
      rethrow;
    }
  }

  // Helper methods for database management
  Future<int> getDatabaseVersion() async {
    try {
      final db = await database;
      return await db.getVersion();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting database version: $e');
      }
      rethrow;
    }
  }

  Future<void> resetDatabase() async {
    try {
      final path = join(await getDatabasesPath(), _databaseName);
      await deleteDatabase(path);
      _database = null;
    } catch (e) {
      if (kDebugMode) {
        print('Database reset error: $e');
      }
      rethrow;
    }
  }

  Future<void> forceReset() async {
    try {
      final path = join(await getDatabasesPath(), _databaseName);
      await deleteDatabase(path);
      _database = null;
      // This will trigger database recreation
      await database;
      print('Database reset successful');
    } catch (e) {
      print('Force reset error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTableInfo(String tableName) async {
    try {
      final db = await database;
      return await db.rawQuery('PRAGMA table_info($tableName)');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting table info: $e');
      }
      rethrow;
    }
  }

  // Helper methods for achievements
  Future<bool> isTableExists(String tableName) async {
    try {
      final db = await database;
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', tableName],
      );
      return tables.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking table existence: $e');
      }
      return false;
    }
  }

  Future<void> clearTable(String tableName) async {
    try {
      final db = await database;
      await db.delete(tableName);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing table: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteUserData(String userId, String tableName) async {
    try {
      final db = await database;
      await db.delete(
        tableName,
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user data: $e');
      }
      rethrow;
    }
  }

  // Specific table existence checks
  Future<bool> isAchievementsTableExists() async {
    return isTableExists('achievements');
  }

  Future<bool> isGoalsTableExists() async {
    return isTableExists('fitness_goals');
  }

  Future<bool> isTrackingHistoryTableExists() async {
    return isTableExists('tracking_history');
  }

  Future<bool> isTrainingPlansTableExists() async {
    return isTableExists('training_plans');
  }

  Future<bool> isCompletedWorkoutsTableExists() async {
    return isTableExists('completed_workouts');
  }

  Future<void> clearTrainingData(String userId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'training_plans',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        'completed_workouts',
        where: 'userId = ?',
        whereArgs: [userId],
      );
    });
  }
}