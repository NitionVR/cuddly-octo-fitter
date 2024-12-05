/*
* LocationTrackingUseCase Tests
*
* context:
* When a user is walking/running, we get a stream of raw GPS locations.
* We need to convert these into route points that:
* - Track the exact position (latitude/longitude)
* - Record when the position was captured (timestamp)
* - Store how accurate the reading is (accuracy in meters)
*
* Why tests like these are relevant:
* - Bad GPS data could make routes look wrong
* - Missing points could create gaps in the route
* - Inaccurate readings could make it seem like the user zigzagged
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:mobile_project_fitquest/domain/usecases/location_tracking_use_case.dart';


void main() {
  group('LocationTrackingUseCase', () {
    // Can we handle normal GPS updates?
    test('should convert location updates into route points correctly', () async {
      // Simulate a user walking north-east
      // From Starting position to 111 meters north and east
      final locationStream = Stream<LocationData>.fromIterable([
        LocationData.fromMap({
          'latitude': 0.0,
          'longitude': 0.0,
          'accuracy': 10.0,
        }),
        LocationData.fromMap({
          'latitude': 1.0,
          'longitude': 1.0,
          'accuracy': 15.0,
        }),
      ]);

      final useCase = LocationTrackingUseCase(locationStream);
      final points = await useCase.startTracking().take(2).toList();

      // Verify we got both points
      expect(points.length, 2, reason: 'Should receive two route points');

      // Check first point (starting position)
      expect(points[0].position.latitude, 0.0,
          reason: 'Starting latitude should be 0');
      expect(points[0].position.longitude, 0.0,
          reason: 'Starting longitude should be 0');
      expect(points[0].accuracy, 10.0,
          reason: 'First point should have 10m accuracy');

      // Check second point (moved position)
      expect(points[1].position.latitude, 1.0,
          reason: 'Should have moved north by 1 degree');
      expect(points[1].position.longitude, 1.0,
          reason: 'Should have moved east by 1 degree');
      expect(points[1].accuracy, 15.0,
          reason: 'Second point should have 15m accuracy');
    });

    // Can we handle bad GPS data?
    test('should protect against null coordinates', () async {
      // Simulate GPS failure
      final locationStream = Stream<LocationData>.fromIterable([
        LocationData.fromMap({
          'latitude': null,
          'longitude': null,
          'accuracy': 10.0,
        }),
      ]);

      final useCase = LocationTrackingUseCase(locationStream);
      final points = await useCase.startTracking().take(1).toList();

      // Verify no points were created from bad data
      expect(points.isEmpty, true,
          reason: 'Should not create route points from invalid GPS data');
    });
  });
}