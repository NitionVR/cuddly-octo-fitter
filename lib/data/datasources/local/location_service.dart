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

  Future<LocationData> getCurrentLocation() async {
    return await _location.getLocation();
  }

  Stream<LocationData> get locationStream => _location.onLocationChanged;
}