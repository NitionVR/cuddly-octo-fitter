// lib/data/database/database_migrations.dart
import 'package:flutter/foundation.dart';
import 'package:mobile_project_fitquest/data/database/table_schemas.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      print('Starting database migration from $oldVersion to $newVersion');
    }

    await db.transaction((txn) async {
      try {
        for (var i = oldVersion + 1; i <= newVersion; i++) {
          if (kDebugMode) {
            print('Applying migration version $i');
          }
          await _runMigration(txn, i);
          if (kDebugMode) {
            print('Migration version $i completed');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Migration failed: $e');
        }
        rethrow;
      }
    });

    if (kDebugMode) {
      print('Database migration completed successfully');
    }
  }

  static Future<void> _runMigration(Transaction txn, int version) async {
    try {
      switch (version) {
        case 2:
          await _migrationV2(txn);
          break;
        case 3:
          await _migrationV3(txn);
          break;
        case 4:
          await _migrationV4(txn);
          break;
        case 5:
          await _migrationV5(txn);
          break;
        case 6:
          await _migrationV6(txn);
          break;
        case 7:
          await _migrationV7(txn);
          break;
        case 8:
          await _migrationV8(txn);
          break;
        default:
          if (kDebugMode) {
            print('Unknown migration version: $version');
          }
      // ... other migrations
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during migration version $version: $e');
      }
      rethrow;
    }
  }

  static Future<void> _migrationV2(Transaction txn) async {
    await txn.execute('ALTER TABLE tracking_history ADD COLUMN total_distance REAL');
    await txn.execute('ALTER TABLE tracking_history ADD COLUMN duration INTEGER');
    await txn.execute('ALTER TABLE tracking_history ADD COLUMN avg_pace TEXT');
  }

  static Future<void> _migrationV3(Transaction txn) async{
    var tableInfo = await txn.rawQuery('PRAGMA table_info(tracking_history)');
    bool hasUserIdColumn = tableInfo.any((column) => column['name'] == 'user_id');

    if (!hasUserIdColumn) {
      await txn.execute('ALTER TABLE tracking_history ADD COLUMN user_id TEXT');
      await txn.execute("UPDATE tracking_history SET user_id = 'legacy_user' WHERE user_id IS NULL");
    }
  }

  static Future<void> _migrationV4(Transaction txn) async{
    await txn.execute('''
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
      '''
    );
  }

  static Future<void> _migrationV5(Transaction txn ) async{
    try {
      await txn.execute('ALTER TABLE tracking_history DROP COLUMN last_sync');
    } catch (e) {
      // ignore if column doesn't exist
    }
    await txn.execute('ALTER TABLE tracking_history ADD COLUMN last_sync TEXT');
  }

  static Future<void> _migrationV6(Transaction txn) async{
    await txn.execute('''
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

    await txn.execute('''
          CREATE INDEX IF NOT EXISTS idx_achievements_userId 
          ON achievements(userId)
        ''');

    await txn.execute('''
          CREATE INDEX IF NOT EXISTS idx_achievements_unlocked 
          ON achievements(userId, unlockedAt)
        ''');
  }

  static Future<void> _migrationV7(Transaction txn) async{
    await txn.execute('DROP TABLE IF EXISTS training_plans');
    await txn.execute('''
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
    await txn.execute('DROP TABLE IF EXISTS completed_workouts');
    await txn.execute('''
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
    await txn.execute('''
        CREATE INDEX idx_training_plans_user 
        ON training_plans(userId, isActive)
      ''');

    await txn.execute('''
        CREATE INDEX idx_completed_workouts_user 
        ON completed_workouts(userId, completed)
      ''');
  }

  static Future<void> _migrationV8(Transaction txn) async {
    if (kDebugMode) {
      print('Starting migration V8: Pace seconds conversion');
    }

    try {
      // Add new column
      await txn.execute(
          'ALTER TABLE tracking_history ADD COLUMN pace_seconds INTEGER DEFAULT 0'
      );

      // Get records to convert
      final records = await txn.query('tracking_history');
      if (kDebugMode) {
        print('Converting ${records.length} records');
      }

      // Convert pace strings to seconds
      for (var record in records) {
        final paceStr = record['avg_pace'] as String?;
        if (paceStr != null) {
          final seconds = _convertPaceStringToSeconds(paceStr);
          await txn.update(
            'tracking_history',
            {'pace_seconds': seconds},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
          if (kDebugMode) {
            print('Converted pace: $paceStr to $seconds seconds');
          }
        }
      }

      if (kDebugMode) {
        print('Migration V8 completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during pace conversion: $e');
      }
      rethrow;
    }
  }

  static Future<void> _migrationV9(Transaction txn) async {
    if (kDebugMode) {
      print('Starting migration V9: Adding workouts table');
    }

    try {
      // Create workouts table
      await txn.execute(TableSchemas.workouts);

      // Create index for better performance
      await txn.execute(TableSchemas.workoutsIndex);

      // Optional: Migrate existing tracking_history data to workouts table
      final existingTracks = await txn.query('tracking_history');

      for (var track in existingTracks) {
        await txn.insert(
          'workouts',
          {
            'id': track['id'].toString(),
            'userId': track['user_id'],
            'timestamp': track['timestamp'],
            'route': track['route'],
            'totalDistance': track['total_distance'],
            'duration': track['duration'],
            'avgPace': track['avg_pace'] ?? '0:00 min/km',
            'type': 'WorkoutType.run',
            'isSynced': 0,
            'lastModified': DateTime.now().toIso8601String(),
          },
        );
      }

      if (kDebugMode) {
        print('Migration V9 completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating workouts table: $e');
      }
      rethrow;
    }
  }

  static int _convertPaceStringToSeconds(String paceStr) {
    try {
      final timeStr = paceStr.split(' ')[0];
      final parts = timeStr.split(':');
      return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> validateMigration(Database db, int version) async {
    try {
      switch (version) {
        case 8:
          final tableInfo = await db.rawQuery('PRAGMA table_info(tracking_history)');
          return tableInfo.any((col) => col['name'] == 'pace_seconds');

        case 9:
          final tableExists = await db.rawQuery('''
              SELECT name FROM sqlite_master 
              WHERE type='table' AND name='workouts'
            ''');
          return tableExists.isNotEmpty;
        default:
          return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Migration validation failed: $e');
      }
      return false;
    }
  }

// ... other migration methods
}