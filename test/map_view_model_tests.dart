/*
* Tests for MapViewModel controlling GPS tracking, route display, and workout data
*/

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_project_fitquest/data/datasources/local/location_service.dart';
import 'package:mobile_project_fitquest/domain/repository/tracking_repository.dart';
import 'package:mobile_project_fitquest/domain/usecases/location_tracking_use_case.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/map_view_model.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mobile_project_fitquest/domain/entities/route_point.dart';

class FakeLocationTrackingUseCase extends Fake implements LocationTrackingUseCase {
  final _controller = StreamController<RoutePoint>();

  void emitLocation(RoutePoint point) {
    _controller.add(point);
  }

  @override
  Stream<RoutePoint> startTracking() => _controller.stream;
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
    );
  });

  group('Location Services', () {
    test('initializes location successfully', () async {
      await viewModel.initializeLocation(fakeLocationService);
      expect(viewModel.route.length, 1);
    });
  });

  group('Tracking Controls', () {
    test('starts tracking with clean state', () {
      viewModel.toggleTracking();
      expect(viewModel.isTracking, true);
      expect(viewModel.totalDistance, 0.0);
      expect(viewModel.pace, "0:00 min/km");
    });

    test('stops tracking and saves workout', () async {
      viewModel.toggleTracking();
      await Future.delayed(Duration(milliseconds: 100));

      fakeLocationUseCase.emitLocation(
          RoutePoint(LatLng(0.0, 0.0), DateTime.now(), accuracy: 10.0)
      );
      await Future.delayed(Duration(milliseconds: 100));

      viewModel.toggleTracking();
      expect(viewModel.isTracking, false);
      expect(fakeRepository._savedData.length, 1);
    });
  });

  group('GPS Processing', () {
    test('filters poor accuracy points', () async {
      viewModel.toggleTracking();
      await Future.delayed(Duration(milliseconds: 100));

      fakeLocationUseCase.emitLocation(
          RoutePoint(LatLng(0.0, 0.0), DateTime.now(), accuracy: 50.0)
      );
      await Future.delayed(Duration(milliseconds: 100));

      expect(viewModel.route.isEmpty, true);
    });

    // test('calculates workout metrics', () async {
    //   viewModel.toggleTracking();
    //   await Future.delayed(Duration(milliseconds: 100));
    //
    //   viewModel.startTime = DateTime.now().subtract(Duration(minutes: 10));
    //
    //   // First point
    //   fakeLocationUseCase.emitLocation(
    //       RoutePoint(LatLng(0.0, 0.0), DateTime.now(), accuracy: 10.0)
    //   );
    //   await Future.delayed(Duration(milliseconds: 100));
    //
    //   // Second point with significant distance
    //   fakeLocationUseCase.emitLocation(
    //       RoutePoint(LatLng(0.1, 0.1), DateTime.now(), accuracy: 10.0)
    //   );
    //   await Future.delayed(Duration(milliseconds: 100));
    //
    //   expect(viewModel.route.length, 2);
    //   expect(viewModel.totalDistance, greaterThan(0.0));
    //   expect(viewModel.getElapsedTime(), '10:00');
    // });
  });

  group('Map Updates', () {
    test('updates route visualization', () async {
      viewModel.toggleTracking();
      await Future.delayed(Duration(milliseconds: 100));

      fakeLocationUseCase.emitLocation(
          RoutePoint(LatLng(0.0, 0.0), DateTime.now(), accuracy: 10.0)
      );
      await Future.delayed(Duration(milliseconds: 100));

      expect(viewModel.route.isNotEmpty, true);
      expect(viewModel.polylines.isNotEmpty, true);
    });
  });
}