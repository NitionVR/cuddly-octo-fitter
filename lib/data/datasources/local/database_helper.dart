import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  static const int _currentVersion = 2;
  static const String _databaseName = 'tracking_history.db';

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: _currentVersion,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }

  Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tracking_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        route TEXT NOT NULL,
        total_distance REAL,
        duration INTEGER,
        avg_pace TEXT
      )
    ''');
  }

  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate from version 1 to 2
      await db.execute('''
        ALTER TABLE tracking_history 
        ADD COLUMN total_distance REAL
      ''');
      await db.execute('''
        ALTER TABLE tracking_history 
        ADD COLUMN duration INTEGER
      ''');
      await db.execute('''
        ALTER TABLE tracking_history 
        ADD COLUMN avg_pace TEXT
      ''');
    }
  }

  // Method to check database version
  Future<int> getDatabaseVersion() async {
    final db = await database;
    return (await db.getVersion());
  }

  // Method to clear the database
  Future<void> resetDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    await deleteDatabase(path);
    _database = null;
  }
}