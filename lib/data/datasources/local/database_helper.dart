import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  static const int _currentVersion = 4;
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
      return openDatabase(
        path,
        version: _currentVersion,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Database initialization error: $e');
      }
      rethrow;
    }
  }

  Future<void> onCreate(Database db, int version) async {
    try {
      await db.execute('''
      CREATE TABLE tracking_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_sync TEXT NOT NULL,
        user_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        route TEXT NOT NULL,
        total_distance REAL,
        duration INTEGER,
        avg_pace TEXT
      )
    ''');

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
        createdBy TEXT,
        isActive INTEGER DEFAULT 1
      )
    ''');

      await db.execute('''
      CREATE TABLE completed_workouts (
        userId TEXT NOT NULL,
        weekId TEXT NOT NULL,
        workoutId TEXT NOT NULL,
        completed INTEGER NOT NULL,
        PRIMARY KEY (userId, weekId, workoutId)
      )
    ''');

      // Add the new fitness_goals table
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
    } catch (e) {
      if (kDebugMode) {
        print('Database upgrade error: $e');
      }
      rethrow;
    }
  }


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

  Future<List<Map<String, dynamic>>> getTableInfo() async {
    try {
      final db = await database;
      return await db.rawQuery('PRAGMA table_info(tracking_history)');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting table info: $e');
      }
      rethrow;
    }
  }

}