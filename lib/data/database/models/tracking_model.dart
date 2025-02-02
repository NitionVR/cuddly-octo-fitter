import 'dart:convert';
import 'package:latlong2/latlong.dart';

class TrackingModel {
  final int? id;
  final String userId;
  final DateTime timestamp;
  final List<LatLng> route;
  final double? totalDistance;
  final int? duration;
  final int? paceSeconds;
  final DateTime? lastSync;

  const TrackingModel({
    this.id,
    required this.userId,
    required this.timestamp,
    required this.route,
    this.totalDistance,
    this.duration,
    this.paceSeconds,
    this.lastSync,
  });

  // Create from database map
  factory TrackingModel.fromMap(Map<String, dynamic> map) {
    final routeJson = map['route'] as String;
    final List<dynamic> routeList = jsonDecode(routeJson);

    return TrackingModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      route: routeList
          .map((e) => LatLng(
        (e['lat'] as num).toDouble(),
        (e['lng'] as num).toDouble(),
      ))
          .toList(),
      totalDistance: map['total_distance'] as double?,
      duration: map['duration'] as int?,
      paceSeconds: map['pace_seconds'] as int?,
      lastSync: map['last_sync'] != null
          ? DateTime.parse(map['last_sync'] as String)
          : null,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'route': jsonEncode(
        route.map((latLng) => {
          'lat': latLng.latitude,
          'lng': latLng.longitude,
        }).toList(),
      ),
      'total_distance': totalDistance,
      'duration': duration,
      'pace_seconds': paceSeconds,
      'last_sync': lastSync?.toIso8601String(),
    };
  }

  // Copy with method for immutability
  TrackingModel copyWith({
    int? id,
    String? userId,
    DateTime? timestamp,
    List<LatLng>? route,
    double? totalDistance,
    int? duration,
    int? paceSeconds,
    DateTime? lastSync,
  }) {
    return TrackingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      route: route ?? this.route,
      totalDistance: totalDistance ?? this.totalDistance,
      duration: duration ?? this.duration,
      paceSeconds: paceSeconds ?? this.paceSeconds,
      lastSync: lastSync ?? this.lastSync,
    );
  }


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TrackingModel &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              userId == other.userId &&
              timestamp == other.timestamp &&
              route.length == other.route.length &&
              totalDistance == other.totalDistance &&
              duration == other.duration &&
              paceSeconds == other.paceSeconds &&
              lastSync == other.lastSync;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      timestamp.hashCode ^
      route.hashCode ^
      totalDistance.hashCode ^
      duration.hashCode ^
      paceSeconds.hashCode ^
      lastSync.hashCode;


  @override
  String toString() {
    return 'TrackingModel('
        'id: $id, '
        'userId: $userId, '
        'timestamp: $timestamp, '
        'route: ${route.length} points, '
        'totalDistance: $totalDistance, '
        'duration: $duration, '
        'paceSeconds: $paceSeconds, '
        'lastSync: $lastSync)';
  }
}