// lib/data/database/models/workout_model.dart
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../../../domain/entities/workout.dart';
import '../../../domain/enums/workout_type.dart';

class WorkoutModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String route; // JSON string of LatLng points
  final double totalDistance;
  final int duration;
  final String avgPace;
  final double? averageSpeed;
  final double? caloriesBurned;
  final double? elevationGain;
  final WorkoutType type;
  final String? notes;
  final bool isSynced;
  final DateTime lastModified;

  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.route,
    required this.totalDistance,
    required this.duration,
    required this.avgPace,
    this.averageSpeed,
    this.caloriesBurned,
    this.elevationGain,
    required this.type,
    this.notes,
    this.isSynced = false,
    required this.lastModified,
  });

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      route: map['route'] as String,
      totalDistance: map['totalDistance'] as double,
      duration: map['duration'] as int,
      avgPace: map['avgPace'] as String,
      averageSpeed: map['averageSpeed'] as double?,
      caloriesBurned: map['caloriesBurned'] as double?,
      elevationGain: map['elevationGain'] as double?,
      type: WorkoutType.values.firstWhere(
            (e) => e.toString() == map['type'],
        orElse: () => WorkoutType.run,
      ),
      notes: map['notes'] as String?,
      isSynced: (map['isSynced'] as int) == 1,
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'route': route,
      'totalDistance': totalDistance,
      'duration': duration,
      'avgPace': avgPace,
      'averageSpeed': averageSpeed,
      'caloriesBurned': caloriesBurned,
      'elevationGain': elevationGain,
      'type': type.toString(),
      'notes': notes,
      'isSynced': isSynced ? 1 : 0,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  Workout toEntity() {
    final routeData = jsonDecode(route) as List;
    return Workout(
      id: id,
      userId: userId,
      timestamp: timestamp,
      route: routeData.map((point) =>
          LatLng(point['lat'] as double, point['lng'] as double)
      ).toList(),
      totalDistance: totalDistance,
      duration: duration,
      avgPace: avgPace,
      averageSpeed: averageSpeed,
      caloriesBurned: caloriesBurned,
      elevationGain: elevationGain,
      type: type,
      notes: notes,
      isSynced: isSynced,
      lastModified: lastModified,
    );
  }

  factory WorkoutModel.fromEntity(Workout entity) {
    return WorkoutModel(
      id: entity.id,
      userId: entity.userId,
      timestamp: entity.timestamp,
      route: jsonEncode(entity.route.map((point) => {
        'lat': point.latitude,
        'lng': point.longitude,
      }).toList()),
      totalDistance: entity.totalDistance,
      duration: entity.duration,
      avgPace: entity.avgPace,
      averageSpeed: entity.averageSpeed,
      caloriesBurned: entity.caloriesBurned,
      elevationGain: entity.elevationGain,
      type: entity.type,
      notes: entity.notes,
      isSynced: entity.isSynced,
      lastModified: entity.lastModified,
    );
  }
}