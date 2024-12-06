import 'package:latlong2/latlong.dart';

class RouteReplayState {
  final List<LatLng> route;
  final int currentPointIndex;
  final double totalDistance;
  final String pace;
  final Duration duration;
  final bool isPlaying;
  final double playbackSpeed;

  RouteReplayState({
    required this.route,
    this.currentPointIndex = 0,
    this.totalDistance = 0.0,
    this.pace = "0:00 min/km",
    required this.duration,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
  });

  RouteReplayState copyWith({
    List<LatLng>? route,
    int? currentPointIndex,
    double? totalDistance,
    String? pace,
    Duration? duration,
    bool? isPlaying,
    double? playbackSpeed,
  }) {
    return RouteReplayState(
      route: route ?? this.route,
      currentPointIndex: currentPointIndex ?? this.currentPointIndex,
      totalDistance: totalDistance ?? this.totalDistance,
      pace: pace ?? this.pace,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}