// lib/data/database/database_service.dart
import 'package:flutter/foundation.dart';
import 'package:mobile_project_fitquest/data/database/table_schemas.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_config.dart';
import 'database_migrations.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static const int _maxRetries = 3;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), DatabaseConfig.databaseName);
    int retryCount = 0;

    while (retryCount < _maxRetries) {
      try {
        return await openDatabase(
          path,
          version: DatabaseConfig.currentVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onOpen: _onOpen,
        );
      } catch (e) {
        retryCount++;
        if (kDebugMode) {
          print('Database initialization attempt $retryCount failed: $e');
        }

        if (retryCount == _maxRetries) {
          if (kDebugMode) {
            print('All retry attempts failed, attempting database reset');
          }
          await deleteDatabase(path);
          return await openDatabase(
            path,
            version: DatabaseConfig.currentVersion,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
          );
        }

        await Future.delayed(Duration(seconds: 1 * retryCount));
      }
    }

    throw Exception('Failed to initialize database after $_maxRetries attempts');
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.transaction((txn) async {
        await txn.execute(TableSchemas.trackingHistory);
        await txn.execute(TableSchemas.fitnessGoals);
        await txn.execute(TableSchemas.achievements);
        await txn.execute(TableSchemas.completedWorkouts);
        await txn.execute(TableSchemas.trainingPlans);
        await txn.execute(DatabaseConfig.tableWorkouts);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error creating database tables: $e');
      }
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      await DatabaseMigrations.migrate(db, oldVersion, newVersion);
    } catch (e) {
      if (kDebugMode) {
        print('Error upgrading database: $e');
      }
      rethrow;
    }
  }

  Future<void> _onOpen(Database db) async {
    try {
      await _verifyDatabaseIntegrity(db);
    } catch (e) {
      if (kDebugMode) {
        print('Error opening database: $e');
      }
      rethrow;
    }
  }

  Future<void> _verifyDatabaseIntegrity(Database db) async {
    try {
      await db.query('sqlite_master');
    } catch (e) {
      if (kDebugMode) {
        print('Database corruption detected: $e');
      }
      throw Exception('Database corruption detected: $e');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      try {
        await _database!.close();
        _database = null;
      } catch (e) {
        if (kDebugMode) {
          print('Error closing database: $e');
        }
        rethrow;
      }
    }
  }

  Future<void> reset() async {
    try {
      await close();
      final path = join(await getDatabasesPath(), DatabaseConfig.databaseName);
      await deleteDatabase(path);
      _database = null;
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting database: $e');
      }
      rethrow;
    }
  }
}