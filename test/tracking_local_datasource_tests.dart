/*
* Tests for TrackingLocalDataSource which handles workout history storage
* Covers saving routes, retrieving history, and data cleanup
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_project_fitquest/data/datasources/local/database_helper.dart';
import 'package:mobile_project_fitquest/data/datasources/local/tracking_local_data_source.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late TrackingLocalDataSource dataSource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dataSource = TrackingLocalDataSource();
    final helper = DatabaseHelper();
    await helper.resetDatabase();
  });

  group('Save and Retrieve Tracking', () {
    test('should save and retrieve tracking data', () async {
      final route = [
        LatLng(0.0, 0.0),
        LatLng(1.0, 1.0)
      ];
      final timestamp = DateTime.now();

      await dataSource.saveTrackingHistory(
          timestamp: timestamp,
          route: route,
          totalDistance: 1000.0,
          duration: 600,
          avgPace: "6:00"
      );

      final history = await dataSource.getTrackingHistory();
      expect(history.length, 1);
      expect(history.first['total_distance'], 1000.0);
      expect(history.first['duration'], 600);
      expect(history.first['avg_pace'], "6:00");

      final retrievedRoute = history.first['route'] as List<LatLng>;
      expect(retrievedRoute.length, 2);
      expect(retrievedRoute.first.latitude, 0.0);
    });

    test('should reject empty routes', () async {
      expect(() => dataSource.saveTrackingHistory(
          timestamp: DateTime.now(),
          route: []
      ), throwsArgumentError);
    });
  });

  group('History Management', () {
    test('should clear all history', () async {
      // Add sample data
      await dataSource.saveTrackingHistory(
          timestamp: DateTime.now(),
          route: [LatLng(0.0, 0.0)]
      );

      await dataSource.clearTrackingHistory();
      final history = await dataSource.getTrackingHistory();
      expect(history.isEmpty, true);
    });

    test('should retrieve by date range', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));
      final tomorrow = now.add(Duration(days: 1));

      await dataSource.saveTrackingHistory(
          timestamp: now,
          route: [LatLng(0.0, 0.0)]
      );

      final results = await dataSource.getTrackingHistoryByDateRange(
          startDate: yesterday,
          endDate: tomorrow
      );
      expect(results.length, 1);
    });
  });
}