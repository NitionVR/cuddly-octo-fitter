import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class TrackingLocalDataSource {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<void> saveTrackingHistory({
    required DateTime timestamp,
    required List<LatLng> route,
    double? totalDistance,
    int? duration,
    String? avgPace,
  }) async {
    // Validate input
    if (route.isEmpty) {
      throw ArgumentError('Route cannot be empty');
    }

    final db = await _databaseHelper.database;

    final result = await db.query('tracking_history');
    print(result);
    // Serialize route points
    final serializedRoute = jsonEncode(route.map((latLng) => {
      'lat': latLng.latitude,
      'lng': latLng.longitude
    }).toList());

    await db.insert(
      'tracking_history',
      {
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
    int limit = 20,
    int offset = 0
  }) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
        'tracking_history',
        limit: limit,
        offset: offset,
        orderBy: 'timestamp DESC'
    );

    // Process and decode route data
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

  Future<void> clearTrackingHistory() async {
    final db = await _databaseHelper.database;
    await db.delete('tracking_history');
  }

  Future<void> deleteSpecificHistory(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
        'tracking_history',
        where: 'id = ?',
        whereArgs: [id]
    );
  }

  Future<Map<String, dynamic>?> getTrackingHistoryById(int id) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> results = await db.query(
        'tracking_history',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1
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
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50
  }) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.query(
        'tracking_history',
        where: 'timestamp BETWEEN ? AND ?',
        whereArgs: [
          startDate.toIso8601String(),
          endDate.toIso8601String()
        ],
        limit: limit,
        orderBy: 'timestamp DESC'
    );

    // Process and decode route data
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

  // Export methods for data backup/sharing
  Future<String> exportTrackingHistoryToJson() async {
    final history = await getTrackingHistory(limit: 100);
    return jsonEncode(history);
  }
}