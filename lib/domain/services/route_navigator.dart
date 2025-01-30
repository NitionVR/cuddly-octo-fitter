// lib/domain/services/route_navigator.dart
import 'package:latlong2/latlong.dart';
import 'package:mobile_project_fitquest/domain/services/route_calculator.dart';

class RouteNavigator {
  static const double OFF_ROUTE_THRESHOLD = 50.0; // meters
  static const double PROGRESS_UPDATE_THRESHOLD = 10.0; // percentage

  static LatLng findClosestPointOnRoute(List<LatLng> routePoints, LatLng position) {
    if (routePoints.isEmpty) {
      throw Exception('No route points available');
    }

    var closestPoint = routePoints.first;
    var minDistance = RouteCalculator.calculateDistance(position, closestPoint);

    for (var point in routePoints) {
      final distance = RouteCalculator.calculateDistance(position, point);
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = point;
      }
    }

    return closestPoint;
  }

  static double calculateRouteProgress(
      List<LatLng> routePoints,
      LatLng currentPosition,
      ) {
    final totalDistance = calculateTotalDistance(routePoints);
    if (totalDistance <= 0) return 0;

    final coveredDistance = calculateCoveredDistance(routePoints, currentPosition);
    return (coveredDistance / totalDistance) * 100;
  }

  static double calculateTotalDistance(List<LatLng> points) {
    double total = 0;
    for (var i = 0; i < points.length - 1; i++) {
      total += RouteCalculator.calculateDistance(points[i], points[i + 1]);
    }
    return total;
  }

  static double calculateCoveredDistance(
      List<LatLng> routePoints,
      LatLng currentPosition,
      ) {
    if (routePoints.isEmpty) return 0;

    final closestPointIndex = findClosestPointIndex(routePoints, currentPosition);
    double distance = 0;

    for (var i = 0; i < closestPointIndex; i++) {
      distance += RouteCalculator.calculateDistance(
        routePoints[i],
        routePoints[i + 1],
      );
    }

    return distance;
  }

  static int findClosestPointIndex(List<LatLng> points, LatLng position) {
    if (points.isEmpty) return -1;

    var closestIndex = 0;
    var minDistance = RouteCalculator.calculateDistance(position, points.first);

    for (var i = 1; i < points.length; i++) {
      final distance = RouteCalculator.calculateDistance(position, points[i]);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }
}