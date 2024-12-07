import 'dart:async';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import '../entities/tracking/route_point.dart';

class LocationTrackingUseCase {
  final Stream<LocationData> _locationStream;

  LocationTrackingUseCase(this._locationStream);

  Stream<RoutePoint> startTracking() async* {
    await for (var location in _locationStream) {
      if (location.latitude != null && location.longitude != null) {
        yield RoutePoint(
          LatLng(location.latitude!, location.longitude!), DateTime.now(),
          accuracy: location.accuracy ?? double.infinity,  // Pass accuracy if available
        );
      }
    }
  }
}