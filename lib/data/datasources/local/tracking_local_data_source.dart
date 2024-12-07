import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class TrackingLocalDataSource {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<void> saveTrackingHistory({
    required String userId,
    required DateTime timestamp,
    required List<LatLng> route,
    double? totalDistance,
    int? duration,
    String? avgPace,
  }) async {
    if (route.isEmpty) {
      throw ArgumentError('Route cannot be empty');
    }

    final db = await _databaseHelper.database;

    final serializedRoute = jsonEncode(route.map((latLng) => {
      'lat': latLng.latitude,
      'lng': latLng.longitude
    }).toList());

    await db.insert(
      'tracking_history',
      {
        'user_id': userId,
        'timestamp': timestamp.toIso8601String(),
        'route': serializedRoute,
        'total_distance': totalDistance,
        'duration': duration,
        'avg_pace': avgPace,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTrackingHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      'tracking_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: limit,
      offset: offset,
      orderBy: 'timestamp DESC',
    );

    return result.map((item) {
      final routeJson = item['route'] as String;
      final List<dynamic> routeList = jsonDecode(routeJson);

      return {
        ...item,
        'route': routeList.map((e) => LatLng(e['lat'], e['lng'])).toList(),
        'timestamp': DateTime.parse(item['timestamp']),
      };
    }).toList();
  }

  Future<void> clearTrackingHistory(String userId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'tracking_history',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteSpecificHistory(String userId, int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'tracking_history',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<Map<String, dynamic>?> getTrackingHistoryById(String userId, int id) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> results = await db.query(
      'tracking_history',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final item = results.first;
    final routeJson = item['route'] as String;
    final List<dynamic> routeList = jsonDecode(routeJson);

    return {
      ...item,
      'route': routeList.map((e) => LatLng(e['lat'], e['lng'])).toList(),
      'timestamp': DateTime.parse(item['timestamp']),
    };
  }

  Future<List<Map<String, dynamic>>> getTrackingHistoryByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
  }) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
      'tracking_history',
      where: 'user_id = ? AND timestamp BETWEEN ? AND ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      limit: limit,
      orderBy: 'timestamp DESC',
    );

    return result.map((item) {
      final routeJson = item['route'] as String;
      final List<dynamic> routeList = jsonDecode(routeJson);

      return {
        ...item,
        'route': routeList.map((e) => LatLng(e['lat'], e['lng'])).toList(),
        'timestamp': DateTime.parse(item['timestamp']),
      };
    }).toList();
  }

  Future<String> exportTrackingHistoryToJson(String userId) async {
    final history = await getTrackingHistory(userId: userId, limit: 100);
    return jsonEncode(history);
  }
}