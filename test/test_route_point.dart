/* Context: When tracking someone's position on a map,
 * we need to store where they were and when they were there.
 * Since we are using GPS to read positions along the person's route,
 * we also need to track the accuracy of the reading.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';


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
  });
}
