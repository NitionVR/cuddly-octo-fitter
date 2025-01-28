import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project_fitquest/data/datasources/local/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() {
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
      expect(version, 3); // Updated to version 3
    });

    test('should create tracking_history table with all required fields', () async {
      final db = await dbHelper.database;
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'tracking_history'],
      );

      expect(tables.length, 1);

      // Verify table structure
      final tableInfo = await db.rawQuery('PRAGMA table_info(tracking_history)');
      final columns = tableInfo.map((col) => col['name'] as String).toList();

      expect(columns.contains('id'), true);
      expect(columns.contains('user_id'), true);
      expect(columns.contains('timestamp'), true);
      expect(columns.contains('route'), true);
      expect(columns.contains('total_distance'), true);
      expect(columns.contains('duration'), true);
      expect(columns.contains('avg_pace'), true);
    });

    test('should enforce user_id as NOT NULL', () async {
      final db = await dbHelper.database;

      // Attempt to insert without user_id should fail
      expect(() async {
        await db.insert('tracking_history', {
          'timestamp': DateTime.now().toIso8601String(),
          'route': '[[0,0],[1,1]]'
        });
      }, throwsException);
    });
  });

  group('Database Migration', () {
    test('should handle upgrade from v1 to v2', () async {
      final db = await dbHelper.database;
      await db.execute('DROP TABLE IF EXISTS tracking_history');
      await db.execute('''
        CREATE TABLE tracking_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          timestamp TEXT NOT NULL,
          route TEXT NOT NULL
        )
      ''');

      await db.insert('tracking_history', {
        'timestamp': DateTime.now().toIso8601String(),
        'route': '[[0,0],[1,1]]'
      });

      await dbHelper.onUpgrade(db, 1, 2);

      final table = await db.query('tracking_history');
      final columns = table.first.keys.toList();

      expect(columns.contains('total_distance'), true);
      expect(columns.contains('duration'), true);
      expect(columns.contains('avg_pace'), true);
    });

    test('should handle upgrade from v2 to v3', () async {
      final db = await dbHelper.database;
      await db.execute('DROP TABLE IF EXISTS tracking_history');

      // Create v2 table
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

      // Insert test data
      await db.insert('tracking_history', {
        'timestamp': DateTime.now().toIso8601String(),
        'route': '[[0,0],[1,1]]',
        'total_distance': 1.0,
        'duration': 60,
        'avg_pace': '5:00'
      });

      // Trigger upgrade to v3
      await dbHelper.onUpgrade(db, 2, 3);

      // Verify new user_id column
      final table = await db.query('tracking_history');
      final columns = table.first.keys.toList();
      expect(columns.contains('user_id'), true);

      // Verify legacy data has default user_id
      final row = table.first;
      expect(row['user_id'], 'legacy_user');
    });
  });

  group('Database Operations', () {
    test('should successfully insert and retrieve user-specific data', () async {
      final db = await dbHelper.database;
      const userId = 'test_user';

      await db.insert('tracking_history', {
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'route': '[[0,0],[1,1]]',
        'total_distance': 1.0,
        'duration': 60,
        'avg_pace': '5:00'
      });

      final results = await db.query(
        'tracking_history',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      expect(results.length, 1);
      expect(results.first['user_id'], userId);
    });
  });

  group('Database Reset', () {
    test('should clear database on reset', () async {
      final db1 = await dbHelper.database;

      // Insert test data
      await db1.insert('tracking_history', {
        'user_id': 'test_user',
        'timestamp': DateTime.now().toIso8601String(),
        'route': '[[0,0],[1,1]]',
      });

      // Reset
      await dbHelper.resetDatabase();

      // Second use
      final db2 = await dbHelper.database;

      // Verify database is new instance
      expect(identical(db1, db2), false);

      // Verify data is cleared
      final results = await db2.query('tracking_history');
      expect(results.isEmpty, true);
    });
  });
}