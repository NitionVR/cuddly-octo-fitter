import 'package:location/location.dart';

class LocationService{
  final Location _location;

  LocationService(this._location);

  Future<bool> isServiceEnabled() async {
    return await _location.requestService();
  }

  Future<PermissionStatus> requestPermission() async{
    return await _location.requestPermission();
  }

  Future<LocationData?> getCurrentLocation() async {
    try {
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 1000,
      );

      return await _location.getLocation();
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  Stream<LocationData> get locationStream => _location.onLocationChanged;
}