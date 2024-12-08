import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart';
import '../../../data/datasources/local/location_service.dart';
import '../../../domain/entities/tracking/route_point.dart';
import '../../../domain/repository/tracking/tracking_repository.dart';
import '../../../domain/usecases/location_tracking_use_case.dart';
import '../auth/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class MapViewModel extends ChangeNotifier {
  final LocationTrackingUseCase _locationTrackingUseCase;
  final MapController _mapController;
  final LocationService _locationService;
  final AuthViewModel _authViewModel;

  final TrackingRepository trackingRepository;

  List<LatLng> _route = [];
  List<Polyline> _polylines = [];
  List<Marker> _markers = [];
  double _totalDistance = 0.0;
  DateTime? _startTime;
  String _pace = "0:00 min/km";
  Timer? _timer;
  bool _isReplaying = false;
  bool _showGpsSignal = true;
  int _gpsAccuracy = 0;
  bool _isPaused = false;


  MapViewModel(
      this._locationTrackingUseCase,
      this.trackingRepository,
      this._locationService,
      this._mapController,
      this._authViewModel,
      );

  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> get history => _history;

  bool _isTracking = false;
  StreamSubscription<RoutePoint>? _locationSubscription;

  List<LatLng> get route => _route;
  double get totalDistance => _totalDistance;
  String get pace => _pace;
  bool get isTracking => _isTracking;
  bool get isActivelyTracking => _isTracking && !_isPaused;

  get mapController => _mapController;
  get polylines => _polylines;
  get markers => _markers;
  get locationService => _locationService;

  bool get isReplaying => _isReplaying;

  bool get showGpsSignal => _showGpsSignal;

  int get gpsAccuracy => _gpsAccuracy;

  bool get isPaused => _isPaused;

  set route(List<LatLng> value) {
    _route = value;
    notifyListeners();
  }

  set startTime(DateTime? value) {
    _startTime = value;
    notifyListeners();
  }

  Future<void> initializeLocation(LocationService locationService) async {
    bool serviceEnabled = await locationService.isServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    PermissionStatus permissionGranted = await locationService.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      return;
    }

    try {
      final LocationData location = await locationService.getCurrentLocation();

      RoutePoint routePoint = RoutePoint(
        LatLng(location.latitude!, location.longitude!),
        DateTime.now(),
        accuracy: location.accuracy ?? double.infinity,  // Pass accuracy from LocationData
      );
      _updateUserLocation(routePoint);

      if (location.latitude != null && location.longitude != null) {
        _mapController.move(
          LatLng(location.latitude!, location.longitude!),
          16.0, // Zoom level
        );
      } else {
        _mapController.move(
          LatLng(0.0, 0.0),
          16.0,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error while getting location: $e');
      }
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void toggleTracking() {
    if (!_isTracking) {
      // Start new tracking session
      _isTracking = true;
      _isPaused = false;
      _startTracking();
    } else {
      // If tracking is active, pause it
      pauseTracking();
    }
    notifyListeners();
  }


  void _startTracking() {
    _startTime = DateTime.now();
    _totalDistance = 0.0;
    _route.clear();

    _timer?.cancel();  // Cancel any existing timer
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (_isTracking) {  // Only notify if still tracking
          notifyListeners();
        }
      },
    );

    // Start location tracking using LocationTrackingUseCase stream
    _locationSubscription = _locationTrackingUseCase.startTracking().listen(_updateUserLocation);
  }

  void endTracking() {
    if (!_isTracking) return;

    _stopTracking();
    _isTracking = false;
    _isPaused = false;
    notifyListeners();
  }

  void _stopTracking() {
    saveTrackingData();
    _locationSubscription?.cancel();
    _locationSubscription = null;

    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void pauseTracking() {
    if (!_isTracking || _isPaused) return;

    _isPaused = true;
    _locationSubscription?.pause();
    _timer?.cancel();
    notifyListeners();
  }

  // New method to resume tracking
  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;

    _isPaused = false;
    _locationSubscription?.resume();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (isActivelyTracking) {
          notifyListeners();
        }
      },
    );
    notifyListeners();
  }

  Future<void> centerOnCurrentLocation() async {
    try{
      final location = await _locationService.getCurrentLocation();
      if (location.latitude != null && location.longitude != null){
        _mapController.move(LatLng(location.latitude!, location.longitude!),
        16.0,
        );
      }
    } catch(e){
      print('Error centering on current location, $e');
    }
  }

  void _updateUserLocation(RoutePoint routePoint) {
    _gpsAccuracy = routePoint.accuracy.round();

    // Only filter very poor accuracy points
    if (routePoint.accuracy > 1300) { // note this is an experiment value
      print("Skipping point due to poor accuracy: ${routePoint.accuracy}m");
      return;
    }

    if (_route.isNotEmpty) {
      final lastPoint = _route.last;
      final distance = Distance().as(
        LengthUnit.Meter,
        lastPoint,
        routePoint.position,
      );

      // Filter out obviously erroneous points
      if (distance > 100.0) {  // Allow larger movements but filter extreme jumps
        print("Skipping suspicious jump: $distance meters");
        return;
      }

      // Update total distance if we're actively tracking
      if (isActivelyTracking && distance >= 1.0) {  // Count movements of 1m or more
        _totalDistance += distance;

        // Update pace calculation
        if (_startTime != null) {
          final elapsedMinutes = DateTime.now().difference(_startTime!).inSeconds / 60.0;
          if (_totalDistance > 0) {  // Prevent division by zero
            final paceMinutes = elapsedMinutes / (_totalDistance / 1000.0);
            final paceMin = paceMinutes.floor();
            final paceSec = (paceMinutes % 1 * 60).round();
            _pace = "$paceMin:${paceSec.toString().padLeft(2, '0')}";
          }
        }
      }
    }

    // Add point to route if tracking is active
    if (isActivelyTracking) {
      _route.add(routePoint.position);

      // Update polyline with smoothed route
      _polylines = [
        Polyline(
          points: _smoothRoute(_route),
          color: Colors.blue,
          strokeWidth: 4.0,
        ),
      ];

      // Update current position marker
      _markers = [
        Marker(
          width: 40.0,
          height: 40.0,
          point: routePoint.position,
          builder: (ctx) => const Icon(
            Icons.navigation,
            color: Colors.red,
            size: 20.0,
          ),
        ),
      ];

      // Auto-center map occasionally
      if (_route.length % 5 == 0) {
        _mapController.move(routePoint.position, _mapController.zoom);
      }

      notifyListeners();
    }
  }

  List<LatLng> _smoothRoute(List<LatLng> points, {int windowSize = 3}) {
    if (points.length < windowSize) return points;

    List<LatLng> smoothed = [];
    for (int i = 0; i < points.length; i++) {
      if (i < windowSize ~/ 2 || i >= points.length - windowSize ~/ 2) {
        smoothed.add(points[i]);
        continue;
      }

      double latSum = 0, lngSum = 0;
      for (int j = i - windowSize ~/ 2; j <= i + windowSize ~/ 2; j++) {
        latSum += points[j].latitude;
        lngSum += points[j].longitude;
      }

      smoothed.add(LatLng(
        latSum / windowSize,
        lngSum / windowSize,
      ));
    }

    return smoothed;
  }


  String getElapsedTime() {
    if (_startTime == null || !_isTracking) return "0:00";
    final elapsed = DateTime.now().difference(_startTime!);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }


  Future<void> saveTrackingData() async {
    try {
      final userId = _authViewModel.currentUser?.id;
      if (userId == null) {
        print('No user logged in');
        return;
      }

      await trackingRepository.saveTrackingData(
        userId: userId,
        timestamp: DateTime.now(),
        route: _route,
        totalDistance: _totalDistance,
        duration: _startTime != null
            ? DateTime.now().difference(_startTime!).inSeconds
            : 0,
        avgPace: _pace,
      );
    } catch (e) {
      print('Error saving tracking data: $e');
    }
  }

  Future<void> clearTrackingHistory() async {
    final userId = _authViewModel.currentUser?.id;
    if (userId == null) {
      print('No user logged in');
      return;
    }

    await trackingRepository.clearTrackingHistory(userId);
    _history = [];
    notifyListeners();
  }

  Future<void> loadTrackingHistory() async {
    final userId = _authViewModel.currentUser?.id;
    if (userId == null) {
      print('No user logged in');
      return;
    }

    _history = await trackingRepository.fetchTrackingHistory(userId: userId);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getLastThreeActivities() async {
    final userId = _authViewModel.currentUser?.id;
    if (userId == null) {
      print('No user logged in');
      return [];
    }

    final history = await trackingRepository.fetchTrackingHistory(userId: userId);
    if (history.isEmpty) {
      return [];
    }
    print(history.take(3).toList()); // manual logging
    return history.take(3).toList();
  }

}

