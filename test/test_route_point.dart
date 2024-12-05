/* Context: When tracking someone's position on a map,
 * we need to store where they were and when they were there.
 * Since we are using GPS to read positions along the person's route,
 * we also need to track the accuracy of the reading.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_project_fitquest/domain/entities/route_point.dart';


void main (){
  group ('RoutePoint', () {

    test('should create RoutePoint data object with specified values', () {
        // Given some location data with known gps coordinates and time
        final position = LatLng(51.5074, -0.1278);
        final timestamp = DateTime(2024,12,4,14,30); // 4th December 2024, 2:30 pm
        final accuracy = 5.0;

        //when we create a RoutePoint object with this data
        final routePoint = RoutePoint(position,timestamp,accuracy:accuracy);

        //then RoutePoint should store all these values correctly
        expect(routePoint.position, position);
        expect(routePoint.timestamp,timestamp);
        expect(routePoint.accuracy, accuracy);

    });

    // Default accuracy test
    test('should use infinity as default accuracy when not specified', () {
    // Given position and time (maybe our GPS didn't report accuracy)
        final position = LatLng(40.7128, -74.0060); // NYC coordinates
        final timestamp = DateTime.now();

        // When we create a RoutePoint without specifying accuracy
        final routePoint = RoutePoint(position, timestamp);

        // Then it should use infinity as default accuracy
        expect(routePoint.accuracy, double.infinity);
    });

    // Practical usage test
    test('should be usable for tracking movement over time', () {
        // Given two points representing movement
        final point1 = RoutePoint(
        LatLng(51.5074, -0.1278), // Soweto
        DateTime(2024, 1, 1, 12, 0),
            accuracy: 10.0
        );

        final point2 = RoutePoint(
        LatLng(51.5074, -0.1268), // Move east
        DateTime(2024, 1, 1, 12, 5),
            accuracy: 8.0
        );

        // Time difference should show movement over 5 minutes
        expect(
            point2.timestamp.difference(point1.timestamp).inMinutes, 5
        );

        // And the positions should be different
        expect(point1.position != point2.position, true);

        // Both points should have good accuracy
        expect(point1.accuracy < 20, true); // Less than 20 meters inaccuracy
        expect(point2.accuracy < 20, true);
        });
  });
}
