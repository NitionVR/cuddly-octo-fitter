/*
* For a GPS tracking app, we need to make sure our location service can:
* - Check if GPS is turned on the user's phone (isServiceEnabled)
* - Request permission to track location of the user (requestPermission)
* - Get the user's current location (getCurrentLocation)
*
* Tests use mocks because:
* 1. We can't access real GPS during automated tests
* 2. Tests need to be fast and reliable
* 3. We need to test error cases effectively
* */

import 'package:flutter_test/flutter_test.dart';
import 'package:location/location.dart';
import 'package:mobile_project_fitquest/data/datasources/local/location_service.dart';
import 'package:mockito/mockito.dart';

// Custom mock for Location
class MockLocation extends Mock implements Location {
  bool _serviceEnabled = true;
  PermissionStatus _permissionStatus = PermissionStatus.granted;
  LocationData _locationData = LocationData.fromMap({
    'latitude': 0.0,
    'longitude': 0.0,
    'accuracy': 10.0,
  });

  @override
  Future<bool> requestService() async {
    return _serviceEnabled;
  }

  @override
  Future<PermissionStatus> requestPermission() async {
    return _permissionStatus;
  }

  @override
  Future<LocationData> getLocation() async {
    return _locationData;
  }

  // Methods to control the mock's behavior
  void setServiceEnabled(bool value) {
    _serviceEnabled = value;
  }

  void setPermissionStatus(PermissionStatus status) {
    _permissionStatus = status;
  }

  void setLocationData(double latitude, double longitude, double accuracy) {
    _locationData = LocationData.fromMap({
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
    });
  }
}

void main() {
  late LocationService locationService;
  late MockLocation mockLocation;

  setUp(() {
    mockLocation = MockLocation();
    locationService = LocationService(mockLocation);
  });

  group('LocationService', () {
    test('isServiceEnabled should return value from location.requestService', () async {
      // Test when GPS is enabled
      mockLocation.setServiceEnabled(true);
      expect(await locationService.isServiceEnabled(), true);

      // Test when GPS is disabled
      mockLocation.setServiceEnabled(false);
      expect(await locationService.isServiceEnabled(), false);
    });

    test('requestPermission should return permission status', () async {
      // Test granted permission
      mockLocation.setPermissionStatus(PermissionStatus.granted);
      expect(await locationService.requestPermission(), PermissionStatus.granted);

      // Test denied permission
      mockLocation.setPermissionStatus(PermissionStatus.denied);
      expect(await locationService.requestPermission(), PermissionStatus.denied);

      // Test denied forever permission
      mockLocation.setPermissionStatus(PermissionStatus.deniedForever);
      expect(await locationService.requestPermission(), PermissionStatus.deniedForever);
    });


  });
}