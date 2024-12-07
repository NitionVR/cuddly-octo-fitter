import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../data/models/route_replay_state.dart';

class RouteReplayViewModel extends ChangeNotifier {
  // Dependencies
  final MapController mapController;

  // State
  RouteReplayState _state;
  Timer? _replayTimer;

  // Getters
  RouteReplayState get state => _state;
  bool get isPlaying => _state.isPlaying;
  int get currentIndex => _state.currentPointIndex;
  List<LatLng> get route => _state.route;

  // Polylines for visualization
  List<Polyline> get polylines => [
    // Completed route portion (blue)
    if (_state.currentPointIndex > 0)
      Polyline(
        points: _state.route.sublist(0, _state.currentPointIndex),
        color: Colors.blue,
        strokeWidth: 4.0,
      ),
    // Remaining route portion (gray)
    if (_state.currentPointIndex < _state.route.length)
      Polyline(
        points: _state.route.sublist(_state.currentPointIndex),
        color: Colors.grey,
        strokeWidth: 4.0,
      ),
  ];

  // Current position marker
  List<Marker> get markers => [
    if (_state.currentPointIndex < _state.route.length)
      Marker(
        width: 40.0,
        height: 40.0,
        point: _state.route[_state.currentPointIndex],
        builder: (ctx) => const Icon(
          Icons.navigation,
          color: Colors.red,
          size: 20.0,
        ),
      ),
  ];

  RouteReplayViewModel({
    required List<LatLng> route,
    required Duration duration,
    required this.mapController,
  }) : _state = RouteReplayState(
    route: route,
    duration: duration,
  );

  void togglePlayPause() {
    if (_state.isPlaying) {
      _pauseReplay();
    } else {
      _startReplay();
    }
  }

  void _startReplay() {
    if (_state.currentPointIndex >= _state.route.length - 1) {
      _resetReplay();
    }

    _state = _state.copyWith(isPlaying: true);
    notifyListeners();

    // Calculate interval based on duration and remaining points
    final remainingPoints = _state.route.length - _state.currentPointIndex;
    final intervalMs = (_state.duration.inMilliseconds / _state.route.length * _state.playbackSpeed).round();

    _replayTimer?.cancel();
    _replayTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      _onReplayTick,
    );
  }

  void _pauseReplay() {
    _replayTimer?.cancel();
    _state = _state.copyWith(isPlaying: false);
    notifyListeners();
  }

  void _resetReplay() {
    _replayTimer?.cancel();
    _state = _state.copyWith(
      currentPointIndex: 0,
      isPlaying: false,
      totalDistance: 0.0,
    );
    notifyListeners();
  }

  void _onReplayTick(Timer timer) {
    if (_state.currentPointIndex >= _state.route.length - 1) {
      _pauseReplay();
      return;
    }

    // Calculate new distance
    if (_state.currentPointIndex > 0) {
      final lastPoint = _state.route[_state.currentPointIndex - 1];
      final currentPoint = _state.route[_state.currentPointIndex];
      final distance = Distance().as(
        LengthUnit.Meter,
        lastPoint,
        currentPoint,
      );
      _state = _state.copyWith(
        totalDistance: _state.totalDistance + distance,
      );
    }

    // Update current position
    _state = _state.copyWith(
      currentPointIndex: _state.currentPointIndex + 1,
    );

    // Update map center if needed
    if (_state.currentPointIndex % 5 == 0) {
      mapController.move(
        _state.route[_state.currentPointIndex],
        mapController.zoom,
      );
    }

    notifyListeners();
  }

  void setPlaybackSpeed(double speed) {
    if (speed >= 0.5 && speed <= 3.0) {
      _state = _state.copyWith(playbackSpeed: speed);
      if (_state.isPlaying) {
        _startReplay(); // Restart with new speed
      }
      notifyListeners();
    }
  }

  void seekToPosition(double progress) {
    final targetIndex = (progress * (_state.route.length - 1)).round();
    _state = _state.copyWith(currentPointIndex: targetIndex);

    mapController.move(
      _state.route[targetIndex],
      mapController.zoom,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _replayTimer?.cancel();
    super.dispose();
  }
}