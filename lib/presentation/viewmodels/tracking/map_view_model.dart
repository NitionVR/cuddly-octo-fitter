import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../data/datasources/local/location_service.dart';
import '../../../domain/entities/tracking/route_point.dart';
import '../../../domain/repository/tracking/tracking_repository.dart';
import '../../../domain/usecases/location_tracking_use_case.dart';
import '../auth/auth_viewmodel.dart';

class MapViewModel extends ChangeNotifier {
  final LocationTrackingUseCase? _locationTrackingUseCase;
  final TrackingRepository? _trackingRepository;
  final LocationService? _locationService;
  final AuthViewModel? _authViewModel;
  final MapController _mapController;

  List<LatLng> _route = [];
  List<Polyline> _polylines = [];
  List<Marker> _markers = [];
  List<Map<String, dynamic>> _history = [];
  double _totalDistance = 0.0;
  DateTime? _startTime;
  String _pace = "0:00 min/km";
  Timer? _timer;
  int _gpsAccuracy = 0;
  bool _isPaused = false;
  bool _isTracking = false;
  bool _showGpsSignal = true;
  bool _isReplaying = false;
  StreamSubscription<RoutePoint>? _locationSubscription;


  MapViewModel(
      this._locationTrackingUseCase,
      this._trackingRepository,
      this._locationService,
      this._mapController,
      this._authViewModel,
      );

  // Public getters
  List<LatLng> get route => _route;
  double get totalDistance => _totalDistance;
  String get pace => _pace;
  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  bool get showGpsSignal => _showGpsSignal;
  int get gpsAccuracy => _gpsAccuracy;
  bool get isReplaying => _isReplaying;
  MapController get mapController => _mapController;
  List<Polyline> get polylines => _polylines;
  List<Marker> get markers => _markers;
  List<Map<String, dynamic>> get history => _history;

  bool get isInitialized =>
      _locationTrackingUseCase != null &&
          _trackingRepository != null &&
          _locationService != null &&
          _authViewModel != null &&
          _mapController != null;

  // Initialization and cleanup
  Future<void> initialize() async {
    if (_locationService == null ||
        _trackingRepository == null ||
        _locationTrackingUseCase == null ||
        _authViewModel == null) {
      return;
    }

    await _checkLocationPermissions();
    await centerOnCurrentLocation();
    await loadTrackingHistory();
  }

  void clear() {
    _route.clear();
    _polylines.clear();
    _markers.clear();
    _totalDistance = 0.0;
    _startTime = null;
    _pace = "0:00 min/km";
    _isTracking = false;
    _isPaused = false;
    _gpsAccuracy = 0;
    _locationSubscription?.cancel();
    _timer?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  // Location permissions
  Future<void> _checkLocationPermissions() async {
    try {
      final serviceEnabled = await _locationService?.isServiceEnabled();
      if (!serviceEnabled!) return;

      final permission = await _locationService?.requestPermission();
      if (permission != PermissionStatus.granted) return;
    } catch (e) {
      _handleError('Location permissions check failed: $e');
    }
  }

  // Tracking control
  void toggleTracking() {
    if (_isTracking) {
      pauseTracking();
    } else {
      startTracking();
    }
  }

  void startTracking() {
    if (_isTracking || _locationTrackingUseCase == null) return;

    _isTracking = true;
    _isPaused = false;
    _startTime = DateTime.now();
    _totalDistance = 0.0;
    _route.clear();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isTracking && !_isPaused) notifyListeners();
    });

    _locationSubscription = _locationTrackingUseCase.startTracking().listen(
      _updateUserLocation,
      onError: (error) => _handleError('Location tracking error: $error'),
    );

    notifyListeners();
  }

  void pauseTracking() {
    if (!_isTracking || _isPaused) return;

    _isPaused = true;
    _locationSubscription?.pause();
    _timer?.cancel();
    notifyListeners();
  }

  void resumeTracking() {
    if (!_isTracking || !_isPaused) return;

    _isPaused = false;
    _locationSubscription?.resume();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isTracking && !_isPaused) notifyListeners();
    });
    notifyListeners();
  }

  Future<void> endTracking() async {
    if (!_isTracking) return;

    try {
      await saveTrackingData();
      _locationSubscription?.cancel();
      _timer?.cancel();
      _isTracking = false;
      _isPaused = false;
      notifyListeners();
    } catch (e) {
      _handleError('Failed to end tracking: $e');
    }
  }

  // Location updates
  void _updateUserLocation(RoutePoint routePoint) {
    try {
      _gpsAccuracy = routePoint.accuracy.round();

      if (_shouldFilterPoint(routePoint)) return;

      if (isActivelyTracking) {
        _updateRouteData(routePoint);
        _updateMapDisplay(routePoint);
        _updatePaceCalculation();
        notifyListeners();
      }
    } catch (e) {
      _handleError('Location update failed: $e');
    }
  }

  bool _shouldFilterPoint(RoutePoint point) {
    if (point.accuracy > 1300) return true;
    if (_route.isEmpty) return false;

    final distance = _calculateDistance(_route.last, point.position);
    return distance > 100;
  }

  void _updateRouteData(RoutePoint point) {
    _route.add(point.position);
    _totalDistance += _calculateDistance(_route.last, point.position);
    _polylines = [_createSmoothedPolyline()];
    _markers = [_createPositionMarker(point.position)];
  }

  void _updateMapDisplay(RoutePoint point) {
    if (_route.length % 5 == 0) {
      _mapController.move(point.position, _mapController.zoom);
    }
  }

  Polyline _createSmoothedPolyline() {
    return Polyline(
      points: _smoothRoute(_route),
      color: Colors.blue,
      strokeWidth: 4.0,
    );
  }

  Marker _createPositionMarker(LatLng position) {
    return Marker(
      width: 40.0,
      height: 40.0,
      point: position,
      builder: (ctx) => const Icon(Icons.navigation, color: Colors.red, size: 20.0),
    );
  }

  // Pace calculation
  void _updatePaceCalculation() {
    if (_startTime == null || _totalDistance == 0) return;

    final elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
    final paceSeconds = (elapsedSeconds / (_totalDistance / 1000)).round();
    _pace = '${(paceSeconds ~/ 60)}:${(paceSeconds % 60).toString().padLeft(2, '0')} min/km';
  }

  // Data persistence
  Future<void> saveTrackingData() async {
    final user = _authViewModel?.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _trackingRepository?.saveTrackingData(
      userId: user.id,
      timestamp: DateTime.now(),
      route: _route,
      totalDistance: _totalDistance,
      duration: DateTime.now().difference(_startTime!).inSeconds,
      avgPace: _pace,
    );
  }

  Future<void> clearTrackingHistory() async {
    final user = _authViewModel?.currentUser;
    if (user == null) return;

    try {
      await _trackingRepository?.clearTrackingHistory(user.id);
      _history.clear();
      notifyListeners();
    } catch (e) {
      _handleError('Failed to clear history: $e');
    }
  }

  Future<void> loadTrackingHistory() async {
    final user = _authViewModel?.currentUser;
    if (user == null) return;

    try {
      _history = (await _trackingRepository?.fetchTrackingHistory(userId: user.id))!;
      notifyListeners();
    } catch (e) {
      _handleError('Failed to load tracking history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLastThreeActivities() async {
    final user = _authViewModel?.currentUser;
    if (user == null) return [];

    try {
      final fullHistory = await _trackingRepository?.fetchTrackingHistory(userId: user.id);
      return fullHistory?.take(3).toList() ?? [];
    } catch (e) {
      _handleError('Failed to get activities: $e');
      return [];
    }
  }

  // Helpers
  Future<void> centerOnCurrentLocation() async {
    try {
      final location = await _locationService?.getCurrentLocation();
      if (location?.latitude != null && location?.longitude != null) {
        _mapController.move(LatLng(location!.latitude!, location.longitude!), 16.0);
      }
    } catch (e) {
      _handleError('Centering failed: $e');
    }
  }

  String getElapsedTime() {
    if (_startTime == null || !_isTracking) return "0:00";
    final elapsed = DateTime.now().difference(_startTime!);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  double _calculateDistance(LatLng a, LatLng b) {
    return const Distance().as(LengthUnit.Meter, a, b);
  }

  List<LatLng> _smoothRoute(List<LatLng> points, {int windowSize = 3}) {
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

  void _handleError(String message) {
    if (kDebugMode) print(message);
    // Consider adding error state notification to UI
  }

  bool get isActivelyTracking => _isTracking && !_isPaused;


}