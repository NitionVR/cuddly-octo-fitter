// lib/data/database/base_dao.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

abstract class BaseDao {
  final Database db;

  BaseDao(this.db);

  Future<int> insert(String table, Map<String, dynamic> data) async {
    try {
      return await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting into $table: $e');
      }
      rethrow;
    }
  }


  Future<List<Map<String, dynamic>>> query(
      String table, {
        bool? distinct,
        List<String>? columns,
        String? where,
        List<Object?>? whereArgs,
        String? groupBy,
        String? having,
        String? orderBy,
        int? limit,
        int? offset,
      }) async {
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
      String table,
      Map<String, dynamic> data, {
        String? where,
        List<Object?>? whereArgs,
      }) async {
    try {
      return await db.update(
        table,
        data,
        where: where,
        whereArgs: whereArgs,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating $table: $e');
      }
      rethrow;
    }
  }

  Future<int> delete(
      String table, {
        String? where,
        List<Object?>? whereArgs,
      }) async {
    try {
      return await db.delete(
        table,
        where: where,
        whereArgs: whereArgs,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting from $table: $e');
      }
      rethrow;
    }
  }
}