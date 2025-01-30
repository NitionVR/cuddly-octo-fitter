// lib/domain/services/route_calculator.dart
import 'package:latlong2/latlong.dart';

class RouteCalculator {
  static double calculateDistance(LatLng a, LatLng b) {
    return const Distance().as(LengthUnit.Meter, a, b);
  }

  static List<LatLng> smoothRoute(List<LatLng> points, {int windowSize = 3}) {
    if (points.length < windowSize) return points;

    return points.asMap().entries.map((entry) {
      final i = entry.key;
      if (i < windowSize ~/ 2 || i >= points.length - windowSize ~/ 2) {
        return entry.value;
      }

      final window = points.sublist(i - windowSize ~/ 2, i + windowSize ~/ 2 + 1);
      final avgLat = window.map((p) => p.latitude).reduce((a, b) => a + b) / windowSize;
      final avgLng = window.map((p) => p.longitude).reduce((a, b) => a + b) / windowSize;

      return LatLng(avgLat, avgLng);
    }).toList();
  }

  static String calculatePace(double distance, Duration duration) {
    if (distance <= 0) return "0:00 min/km";
    final paceSeconds = (duration.inSeconds / (distance / 1000)).round();
    return '${(paceSeconds ~/ 60)}:${(paceSeconds % 60).toString().padLeft(2, '0')} min/km';
  }
}