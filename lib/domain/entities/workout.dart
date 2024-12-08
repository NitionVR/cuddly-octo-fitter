import 'package:latlong2/latlong.dart';

import '../enums/workout_type.dart';

class Workout {
  final String id;
  final String userId;
  final DateTime timestamp;
  final List<LatLng> route;
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

  Workout({
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
    this.type = WorkoutType.run,
    this.notes,
    this.isSynced = false,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'route': route.map((point) => {
        'lat': point.latitude,
        'lng': point.longitude,
      }).toList(),
      'totalDistance': totalDistance,
      'duration': duration,
      'avgPace': avgPace,
      'averageSpeed': averageSpeed,
      'caloriesBurned': caloriesBurned,
      'elevationGain': elevationGain,
      'type': type.toString(),
      'notes': notes,
      'isSynced': isSynced,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      userId: map['userId'],
      timestamp: DateTime.parse(map['timestamp']),
      route: (map['route'] as List)
          .map((point) => LatLng(point['lat'], point['lng']))
          .toList(),
      totalDistance: map['totalDistance'],
      duration: map['duration'],
      avgPace: map['avgPace'],
      averageSpeed: map['averageSpeed'],
      caloriesBurned: map['caloriesBurned'],
      elevationGain: map['elevationGain'],
      type: WorkoutType.values.firstWhere(
            (e) => e.toString() == map['type'],
        orElse: () => WorkoutType.run,
      ),
      notes: map['notes'],
      isSynced: map['isSynced'] ?? false,
      lastModified: DateTime.parse(map['lastModified']),
    );
  }
}

