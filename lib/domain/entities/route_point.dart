/*
* RoutePoint class keeps keep track of postion, timestamp and accuracy
* of the gps reading.
* */

import 'package:latlong2/latlong.dart';

class RoutePoint {
  final LatLng _position;
  final DateTime _timestamp;
  final double _accuracy;

  LatLng get position => _position;
  DateTime get timestamp => _timestamp;
  double get accuracy => _accuracy;

  RoutePoint(LatLng position,DateTime timestamp, {double accuracy = double.infinity})
      : assert (accuracy >= 0, 'Accuracy cannot be negative'),
        _position = position,
        _timestamp = timestamp,
        _accuracy = accuracy;

  @override
  bool operator ==(Object other){
    if (identical(this, other)) return true;
    return other is RoutePoint &&
    other._position == _position &&
    other._timestamp == _timestamp &&
    other._accuracy == accuracy;
  }

  @override
  // TODO: implement hashCode
  int get hashCode =>
      _position.hashCode ^ _timestamp.hashCode ^ _accuracy.hashCode;

  @override toString(){
    return 'RoutePoint(position: $_position, timestamp: $_timestamp, accuracy: $_accuracy)';
  }
}


