import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../data/database/providers/database_provider.dart';
import '../../../data/datasources/local/location_service.dart';
import '../../../domain/entities/tracking/route_point.dart';
import '../../../domain/enums/goal_type.dart';
import '../../../domain/repository/tracking/tracking_repository.dart';
import '../../../domain/usecases/location_tracking_use_case.dart';
import '../auth/auth_view_model.dart';
import '../goals/goals_view_model.dart';


class MapViewModel extends ChangeNotifier {
  final ITrackingRepository _trackingRepository;
  final LocationTrackingUseCase _locationTrackingUseCase;
  final LocationService _locationService;
  final DatabaseProvider _databaseProvider;
  final AuthViewModel _authViewModel;
  final GoalsViewModel _goalsViewModel;
  final MapController _mapController;
  bool _hasStableInitialPosition = false;
  LatLng? _initialPosition;


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


  MapViewModel({
    required ITrackingRepository trackingRepository,
    required LocationTrackingUseCase locationTrackingUseCase,
    required LocationService locationService,
    required DatabaseProvider databaseProvider,
    required AuthViewModel authViewModel,
    required GoalsViewModel goalsViewModel,
    required MapController mapController,
  }) : _trackingRepository = trackingRepository,
        _locationTrackingUseCase = locationTrackingUseCase,
        _locationService = locationService,
        _databaseProvider = databaseProvider,
        _authViewModel = authViewModel,
        _goalsViewModel = goalsViewModel,
        _mapController = mapController {
    initialize();
  }

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
  bool get hasStableInitialPosition => _hasStableInitialPosition;

  bool get isInitialized =>
      _locationTrackingUseCase != null &&
          _trackingRepository != null &&
          _locationService != null &&
          _authViewModel != null &&
          _mapController != null;

  // Initialization and cleanup
  Future<void> initialize() async {
    try {
      await _checkLocationPermissions();
      await _initializeLocation();
      await loadTrackingHistory();
      await _databaseProvider.syncService.syncWorkouts();
      notifyListeners();
    } catch (e) {
      _handleError('Initialization failed: $e');
    }
  }

  Future<void> _initializeLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (location?.latitude != null && location?.longitude != null) {
      _markers = [_createPositionMarker(
          LatLng(location!.latitude!, location.longitude!)
      )];
      _mapController.move(
        LatLng(location.latitude!, location.longitude!),
        16.0,
      );
    }
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
    _hasStableInitialPosition = false;
    _initialPosition = null;
    _startTime = null;  // We'll set this once we have a stable position
    _totalDistance = 0.0;
    _route.clear();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isTracking && !_isPaused && _hasStableInitialPosition) notifyListeners();
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

      // Update goals if available
      if (_goalsViewModel != null) {
        await _updateGoals(_goalsViewModel!);
      }

      _locationSubscription?.cancel();
      _timer?.cancel();
      _isTracking = false;
      _isPaused = false;
      notifyListeners();
    } catch (e) {
      _handleError('Failed to end tracking: $e');
    }
  }

  Future<void> _updateGoals(GoalsViewModel goalsViewModel) async {
    final distance = _totalDistance / 1000; // Convert to kilometers
    final duration = DateTime.now().difference(_startTime!).inMinutes;

    // Update distance-based goals
    final distanceGoals = goalsViewModel.getGoalsByType(GoalType.distance);
    for (var goal in distanceGoals) {
      if (!goal.isCompleted && !goal.isExpired) {
        final newProgress = goal.currentProgress + distance;
        await goalsViewModel.updateGoalProgress(goal.id, newProgress);
      }
    }

    // Update duration-based goals
    final durationGoals = goalsViewModel.getGoalsByType(GoalType.duration);
    for (var goal in durationGoals) {
      if (!goal.isCompleted && !goal.isExpired) {
        final newProgress = goal.currentProgress + duration;
        await goalsViewModel.updateGoalProgress(goal.id, newProgress);
      }
    }
  }

  // Location updates
  void _updateUserLocation(RoutePoint routePoint) {
    try {
      _gpsAccuracy = routePoint.accuracy.round();

      // Handle initial position stabilization
      if (!_hasStableInitialPosition) {
        if (_initialPosition == null) {
          _initialPosition = routePoint.position;
          return;
        }

        // Check if we've moved significantly from initial position
        final initialDistance = _calculateDistance(_initialPosition!, routePoint.position);
        if (initialDistance < 5 && routePoint.accuracy < 20) {  // 5 meters threshold and good accuracy
          _hasStableInitialPosition = true;
          _startTime = DateTime.now();  // Start timing only after stable position
          _route.add(routePoint.position);
          _markers = [_createPositionMarker(routePoint.position)];
          notifyListeners();
          return;
        }
        _initialPosition = routePoint.position;
        return;
      }

      // Normal tracking logic
      if (_shouldFilterPoint(routePoint)) {
        print('Point filtered out: ${routePoint.position}');
        return;
      }

      if (isActivelyTracking) {
        print('Before update - Distance: $_totalDistance, Pace: $_pace');
        _updateRouteData(routePoint);
        _updateMapDisplay(routePoint);
        print('After update - Distance: $_totalDistance, Pace: $_pace');
        notifyListeners();
      }
    } catch (e) {
      _handleError('Location update failed: $e');
    }
  }

  bool _shouldFilterPoint(RoutePoint point) {
    if (point.accuracy > 30) {  // More strict accuracy threshold
      print('Point filtered due to poor accuracy: ${point.accuracy}m');
      return true;
    }

    if (_route.isEmpty) return false;

    final distance = _calculateDistance(_route.last, point.position);
    if (distance < 0.5) {  // Filter out points that are too close (less than 0.5 meters)
      print('Point filtered due to minimal movement: ${distance}m');
      return true;
    }

    if (distance > 50) {  // Filter out sudden large jumps
      print('Point filtered due to large jump: ${distance}m');
      return true;
    }

    return false;
  }

  void _updateRouteData(RoutePoint point) {
    if (_route.isNotEmpty) {
      final lastPoint = _route.last;
      final newDistance = _calculateDistance(lastPoint, point.position);

      // Only add distance if we've moved more than 0.5 meters
      if (newDistance > 0.5) {
        print("New distance segment: $newDistance meters");
        _totalDistance += newDistance;
        print("Updated total distance: $_totalDistance meters");
        _route.add(point.position);
        _polylines = [_createSmoothedPolyline()];
        _markers = [_createPositionMarker(point.position)];
        _updatePaceCalculation();
      }
    } else {
      _route.add(point.position);
      _markers = [_createPositionMarker(point.position)];
    }
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
    if (_startTime == null || _totalDistance <= 0) {
      _pace = "0:00 min/km";
      return;
    }

    final elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
    if (elapsedSeconds <= 0) {
      _pace = "0:00 min/km";
      return;
    }

    // Convert distance to kilometers
    final distanceInKm = _totalDistance / 1000;
    if (distanceInKm <= 0) {
      _pace = "0:00 min/km";
      return;
    }

    // Calculate pace in seconds per kilometer
    final paceSeconds = (elapsedSeconds / distanceInKm).round();
    final minutes = paceSeconds ~/ 60;
    final seconds = paceSeconds % 60;
    _pace = '$minutes:${seconds.toString().padLeft(2, '0')} min/km';
  }


  // Data persistence
  Future<void> saveTrackingData() async {
    final user = _authViewModel.currentUser;
    if (user == null) throw Exception('User not authenticated');

    _updatePaceCalculation();

    if (kDebugMode) {
      print("=== Saving Tracking Data ===");
      print("Total Distance (meters): $_totalDistance");
      print("Total Distance (km): ${_totalDistance / 1000}");
      print("Route points count: ${_route.length}");
      print("Duration: ${getElapsedTime()}");
      print("Pace: $_pace");
    }

    try {
      await _trackingRepository.saveTrackingData(
        userId: user.id,
        timestamp: DateTime.now(),
        route: _route,
        totalDistance: _totalDistance,
        duration: DateTime.now().difference(_startTime!).inSeconds,
        paceSeconds: _calculatePaceSeconds(),
      );

      // Sync after saving
      await _databaseProvider.syncService.syncWorkouts();
    } catch (e) {
      _handleError('Failed to save tracking data: $e');
      rethrow;
    }
  }

  int _calculatePaceSeconds() {
    if (_totalDistance <= 0 || _startTime == null) return 0;
    final elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
    final distanceInKm = _totalDistance / 1000;
    return (elapsedSeconds / distanceInKm).round();
  }

  Future<void> clearTrackingHistory() async {
    final user = _authViewModel.currentUser;
    if (user == null) return;

    try {
      await _trackingRepository.clearTrackingHistory(user.id);
      await _databaseProvider.syncService.syncWorkouts();
      _history.clear();
      notifyListeners();
    } catch (e) {
      _handleError('Failed to clear history: $e');
    }
  }

  Future<void> loadTrackingHistory() async {
    final user = _authViewModel.currentUser;
    if (user == null) return;

    try {
      final trackingHistory = await _trackingRepository.fetchTrackingHistory(
        userId: user.id,
      );
      _history = trackingHistory.map((tracking) => tracking.toMap()).toList();
      notifyListeners();
    } catch (e) {
      _handleError('Failed to load tracking history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLastThreeActivities() async {
    final user = _authViewModel.currentUser;
    if (user == null) return [];

    try {
      final trackingHistory = await _trackingRepository.fetchTrackingHistory(
        userId: user.id,
        limit: 3,
        offset: 0,
      );

      return trackingHistory.map((tracking) => {
        'id': tracking.id,
        'userId': tracking.userId,
        'timestamp': tracking.timestamp.toIso8601String(),
        'route': tracking.route,
        'totalDistance': tracking.totalDistance,
        'duration': tracking.duration,
        'paceSeconds': tracking.paceSeconds,
        'pace': _formatPace(tracking.paceSeconds ?? 0),
        // Add any additional fields needed for the UI
      }).toList();
    } catch (e) {
      _handleError('Failed to get activities: $e');
      return [];
    }
  }

  String _formatPace(int paceSeconds) {
    if (paceSeconds <= 0) return "0:00 min/km";
    final minutes = paceSeconds ~/ 60;
    final seconds = paceSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')} min/km";
  }

  // Helpers
  Future<void> centerOnCurrentLocation() async {
    try {
      final location = await _locationService?.getCurrentLocation();
      if (location?.latitude != null && location?.longitude != null) {
        // Update marker
        _markers = [
          Marker(
            width: 40.0,
            height: 40.0,
            point: LatLng(location!.latitude!, location.longitude!),
            builder: (ctx) => const Icon(
              Icons.navigation,
              color: Colors.red,
              size: 20.0,
            ),
          ),
        ];

        // Move map
        _mapController.move(
          LatLng(location.latitude!, location.longitude!),
          _mapController.zoom,
        );

        notifyListeners();
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