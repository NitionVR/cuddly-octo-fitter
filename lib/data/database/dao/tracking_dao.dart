// lib/data/database/dao/tracking_dao.dart
import 'package:flutter/foundation.dart';
import '../database_config.dart';
import '../models/tracking_model.dart';
import 'base_dao.dart';

class TrackingDao extends BaseDao {
  TrackingDao(super.db);

  Future<void> saveTracking(TrackingModel tracking) async {
    if (kDebugMode) {
      print("=== Saving Tracking Data ===");
      print("Total Distance: ${tracking.totalDistance}");
      print("Route points: ${tracking.route.length}");
    }

    if (tracking.route.isEmpty) {
      throw ArgumentError('Route cannot be empty');
    }

    final data = tracking.toMap();
    if (kDebugMode) {
      print("Data to insert: $data");
    }

    await insert(DatabaseConfig.tableTrackingHistory, data);
  }

  Future<List<TrackingModel>> getTrackingHistory(
      String userId, {
        int limit = 20,
        int offset = 0,
      }) async {
    final results = await query(
      DatabaseConfig.tableTrackingHistory,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: limit,
      offset: offset,
      orderBy: 'timestamp DESC',
    );

    return results.map(TrackingModel.fromMap).toList();
  }

  Future<void> clearTrackingHistory(String userId) async {
    await delete(
      DatabaseConfig.tableTrackingHistory,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteSpecificHistory(String userId, int id) async {
    await delete(
      DatabaseConfig.tableTrackingHistory,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<TrackingModel?> getTrackingHistoryById(String userId, int id) async {
    final results = await query(
      DatabaseConfig.tableTrackingHistory,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );

    return results.isEmpty ? null : TrackingModel.fromMap(results.first);
  }

  Future<List<TrackingModel>> getTrackingHistoryByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
  }) async {
    final results = await query(
      DatabaseConfig.tableTrackingHistory,
      where: 'user_id = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      limit: limit,
      orderBy: 'timestamp DESC',
    );

    return results.map(TrackingModel.fromMap).toList();
  }

  Future<List<TrackingModel>> getUnsyncedRecords(String userId) async {
    final results = await query(
      DatabaseConfig.tableTrackingHistory,
      where: 'user_id = ? AND last_sync IS NULL',
      whereArgs: [userId],
    );

    return results.map(TrackingModel.fromMap).toList();
  }

  Future<void> updateSyncStatus(TrackingModel tracking) async {
    if (tracking.id == null) {
      throw ArgumentError('Tracking ID cannot be null for sync update');
    }

    await update(
      DatabaseConfig.tableTrackingHistory,
      {'last_sync': DateTime.now().toIso8601String()},
      where: 'id = ? AND user_id = ?',
      whereArgs: [tracking.id, tracking.userId],
    );
  }

  Future<void> mergeFirestoreData(
      String userId,
      List<Map<String, dynamic>> firestoreData,
      ) async {
    await db.transaction((txn) async {
      for (var record in firestoreData) {
        final exists = await txn.query(
          DatabaseConfig.tableTrackingHistory,
          where: 'id = ? AND user_id = ?',
          whereArgs: [record['id'], userId],
        );

        if (exists.isEmpty) {
          final tracking = TrackingModel.fromMap(record);
          await txn.insert(DatabaseConfig.tableTrackingHistory, tracking.toMap());
        }
      }
    });
  }
}