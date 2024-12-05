/*
* Tests for DatabaseHelper which manages a SQLite database for tracking workout history
* Key scenarios:
* - Database initialization and version management
* - Table creation with required fields
* - Database upgrades
* - Database reset functionality
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project_fitquest/data/datasources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    dbHelper = DatabaseHelper();
  });

  tearDown(() async {
    await dbHelper.resetDatabase();
  });

  group('Database Setup', () {
    test('should initialize database with correct version', () async {
      final version = await dbHelper.getDatabaseVersion();
      expect(version, 2);
    });

    test('should create tracking_history table on first run', () async {
      final db = await dbHelper.database;
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'tracking_history'],
      );

      expect(tables.length, 1);
    });
  });

  group('Database Migration', () {
    test('should handle upgrade from v1 to v2', () async {
      // Create v1 database
      final db = await dbHelper.database;
      await db.execute('DROP TABLE IF EXISTS tracking_history');
      await db.execute('''
      CREATE TABLE tracking_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        route TEXT NOT NULL
      )
    ''');

      // Insert test data
      await db.insert('tracking_history', {
        'timestamp': DateTime.now().toIso8601String(),
        'route': '[[0,0],[1,1]]'
      });

      // Trigger upgrade
      await dbHelper.onUpgrade(db, 1, 2);

      // Verify new columns
      final table = await db.query('tracking_history');
      final columns = table.first.keys.toList();

      expect(columns.contains('total_distance'), true);
      expect(columns.contains('duration'), true);
      expect(columns.contains('avg_pace'), true);
    });
  });

  group('Database Reset', () {
    test('should clear database on reset', () async {
      // First use
      final db1 = await dbHelper.database;

      // Reset
      await dbHelper.resetDatabase();

      // Second use
      final db2 = await dbHelper.database;

      expect(identical(db1, db2), false);
    });
  });
}