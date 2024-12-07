// /*
// * TrackingRepository Tests
// * Tests workout tracking functionality with a fake data source
// */
//
// import 'package:flutter_test/flutter_test.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:mobile_project_fitquest/data/datasources/local/tracking_local_data_source.dart';
// import 'package:mobile_project_fitquest/domain/repository/tracking_repository.dart';
//
// class MockTrackingLocalDataSource extends Fake implements TrackingLocalDataSource {
//   List<Map<String, dynamic>> _mockData = [];
//   bool _shouldThrowError = false;
//
//   void setupMockData(List<Map<String, dynamic>> data) {
//     _mockData = data;
//   }
//
//   void setShouldThrowError(bool shouldThrow) {
//     _shouldThrowError = shouldThrow;
//   }
//
//   @override
//   Future<void> saveTrackingHistory({
//     required DateTime timestamp,
//     required List<LatLng> route,
//     double? totalDistance,
//     int? duration,
//     String? avgPace,
//   }) async {
//     if (_shouldThrowError) throw Exception('DB Error');
//     _mockData.add({
//       'timestamp': timestamp,
//       'route': route,
//       'total_distance': totalDistance,
//       'duration': duration,
//       'avg_pace': avgPace,
//     });
//   }
//
//   @override
//   Future<List<Map<String, dynamic>>> getTrackingHistory({
//     int limit = 20,
//     int offset = 0,
//   }) async {
//     if (_shouldThrowError) throw Exception('DB Error');
//     return _mockData;
//   }
// }
//
// void main() {
//   late TrackingRepository repository;
//   late MockTrackingLocalDataSource mockDataSource;
//
//   setUp(() {
//     mockDataSource = MockTrackingLocalDataSource();
//     repository = TrackingRepository(mockDataSource);
//   });
//
//   group('Workout Data Validation', () {
//     test('saves valid workout with complete stats', () async {
//       final route = [LatLng(0.0, 0.0), LatLng(1.0, 1.0)];
//
//       await repository.saveTrackingData(
//           timestamp: DateTime.now(),
//           route: route,
//           totalDistance: 1000,
//           duration: 600,
//           avgPace: '6:00'
//       );
//
//       expect(mockDataSource._mockData.length, 1);
//       expect(mockDataSource._mockData.first['total_distance'], 1000);
//     });
//
//     test('rejects workout with no GPS points', () {
//       expect(
//               () => repository.saveTrackingData(
//               timestamp: DateTime.now(),
//               route: []
//           ),
//           throwsArgumentError
//       );
//     });
//   });
//
//   group('Running Analytics', () {
//     test('calculates total stats from multiple workouts', () async {
//       mockDataSource.setupMockData([
//         {
//           'timestamp': DateTime.now(),
//           'route': [LatLng(0.0, 0.0)],
//           'total_distance': 5000.0,
//           'duration': 1800,
//           'avg_pace': '6:00'
//         },
//         {
//           'timestamp': DateTime.now(),
//           'route': [LatLng(1.0, 1.0)],
//           'total_distance': 3000.0,
//           'duration': 900,
//           'avg_pace': '5:00'
//         }
//       ]);
//
//       final stats = await repository.getRunningStats();
//       expect(stats.totalDistance, 8000.0);
//       expect(stats.totalDuration, Duration(seconds: 2700));
//     });
//   });
//
//   group('Error Recovery', () {
//     test('handles database errors gracefully', () async {
//       mockDataSource.setShouldThrowError(true);
//       final history = await repository.fetchTrackingHistory();
//       expect(history.isEmpty, true);
//     });
//   });
// }