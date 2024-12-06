/*
* MapViewModel Tests
*
* Purpose: Verify GPS tracking and route visualization functionality:
* 1. Location service initialization
* 2. Real-time GPS tracking controls
* 3. Route recording and metrics calculation
* 4. Map visualization updates
*
* Using fakes to simulate:
* - GPS location updates
* - Map controller interactions
* - Data persistence
*/

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_project_fitquest/data/datasources/local/location_service.dart';
import 'package:mobile_project_fitquest/domain/repository/tracking_repository.dart';
import 'package:mobile_project_fitquest/domain/usecases/location_tracking_use_case.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/map_view_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mobile_project_fitquest/domain/entities/route_point.dart';
import 'package:mockito/mockito.dart';

// Simulates GPS tracking updates
class FakeLocationTrackingUseCase extends Fake implements LocationTrackingUseCase {
  final _controller = StreamController<RoutePoint>();

  void emitLocation(RoutePoint point) {
    _controller.add(point);
  }

  @override
  Stream<RoutePoint> startTracking() => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

class FakeLocationService extends Fake implements LocationService {
  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<PermissionStatus> requestPermission() async => PermissionStatus.granted;

  @override
  Future<LocationData> getCurrentLocation() async => LocationData.fromMap({
    'latitude': 0.0,
    'longitude': 0.0,
    'accuracy': 10.0,
  });
}

class FakeTrackingRepository extends Fake implements TrackingRepository {
  final _savedData = <Map<String, dynamic>>[];

  @override
  Future<void> saveTrackingData({
    required DateTime timestamp,
    required List<LatLng> route,
    double? totalDistance,
    int? duration,
    String? avgPace,
  }) async {
    _savedData.add({
      'timestamp': timestamp,
      'route': route,
      'total_distance': totalDistance,
      'duration': duration,
      'avg_pace': avgPace,
    });
  }

  void clear() {
    _savedData.clear();
  }
}

void main() {
  late MapViewModel viewModel;
  late FakeLocationTrackingUseCase fakeLocationUseCase;
  late FakeTrackingRepository fakeRepository;
  late FakeLocationService fakeLocationService;

  setUp(() {
    fakeLocationUseCase = FakeLocationTrackingUseCase();
    fakeRepository = FakeTrackingRepository();
    fakeLocationService = FakeLocationService();
    viewModel = MapViewModel(
      fakeLocationUseCase,
      fakeRepository,
      fakeLocationService,
      MapController()
    );
  });

  tearDown(() {
    fakeLocationUseCase.dispose();
    fakeRepository.clear();
  });

  group('Location Service Setup', () {
    test('initializes GPS and starts receiving locations', () async {
      await viewModel.initializeLocation(fakeLocationService);
      expect(viewModel.route.length, 1, reason: 'Should record initial position');
    });
  });

  group('Workout Tracking Controls', () {
    test('starts tracking with clean initial state', () {
      viewModel.toggleTracking();
      expect(viewModel.isTracking, true, reason: 'Should be in tracking state');
      expect(viewModel.totalDistance, 0.0, reason: 'Distance should start at 0');
      expect(viewModel.pace, "0:00 min/km", reason: 'Pace should start at 0');
    });

    test('stops tracking and persists workout data', () async {
      viewModel.toggleTracking();
      await Future.delayed(Duration(milliseconds: 100));

      fakeLocationUseCase.emitLocation(
          RoutePoint(LatLng(0.0, 0.0), DateTime.now(), accuracy: 10.0)
      );
      await Future.delayed(Duration(milliseconds: 100));

      viewModel.toggleTracking();
      expect(viewModel.isTracking, false, reason: 'Should stop tracking');
      expect(fakeRepository._savedData.length, 1, reason: 'Should save workout data');
    });
  });

  group('GPS Data Processing', () {
    test('filters out inaccurate GPS readings', () async {
      viewModel.toggleTracking();
      await Future.delayed(Duration(milliseconds: 100));

      fakeLocationUseCase.emitLocation(
          RoutePoint(LatLng(0.0, 0.0), DateTime.now(), accuracy: 50.0)
      );
      await Future.delayed(Duration(milliseconds: 100));

      expect(viewModel.route.isEmpty, true,
          reason: 'Should reject points with poor accuracy');
    });

    // test('calculates workout metrics', () async {
    //   viewModel.toggleTracking();
    //   await Future.delayed(Duration(milliseconds: 100));
    //
    //   viewModel.startTime = DateTime.now().subtract(Duration(minutes: 10));
    //
    //   fakeLocationUseCase.emitLocation(
    //       RoutePoint(LatLng(0.0, 0.0), DateTime.now(), accuracy: 10.0)
    //   );
    //   await Future.delayed(Duration(milliseconds: 100));
    //
    //   fakeLocationUseCase.emitLocation(
    //       RoutePoint(LatLng(0.1, 0.1), DateTime.now(), accuracy: 10.0)
    //   );
    //   await Future.delayed(Duration(milliseconds: 100));
    //
    //   expect(viewModel.route.length, 2, reason: 'Should record both points');
    //   expect(viewModel.totalDistance, greaterThan(0.0),
    //       reason: 'Should calculate distance between points');
    //   expect(viewModel.getElapsedTime(), '10:00',
    //       reason: 'Should track elapsed time');
    // });
  });
}