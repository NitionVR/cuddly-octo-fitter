import 'package:latlong2/latlong.dart';

import 'comment.dart';

class SharedWorkout {
  final String id;
  final String userId;
  final String title;
  final DateTime timestamp;
  final List<LatLng> route;
  final double distance;
  final Duration duration;
  final String pace;
  final List<Comment> comments;
  final List<String> likes;
  final Map<String, dynamic>? additionalData;
  final String? caption;
  final List<String>? photos;

  SharedWorkout({
    required this.id,
    required this.userId,
    required this.title,
    required this.timestamp,
    required this.route,
    required this.distance,
    required this.duration,
    required this.pace,
    this.comments = const [],
    this.likes = const [],
    this.additionalData,
    this.caption,
    this.photos,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
      'route': route.map((point) => {
        'lat': point.latitude,
        'lng': point.longitude
      }).toList(),
      'distance': distance,
      'duration': duration.inSeconds,
      'pace': pace,
      'comments': comments.map((c) => c.toMap()).toList(),
      'likes': likes,
      'additionalData': additionalData,
      'caption': caption,
      'photos': photos,
    };
  }

  factory SharedWorkout.fromMap(Map<String, dynamic> map) {
    return SharedWorkout(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      timestamp: DateTime.parse(map['timestamp']),
      route: (map['route'] as List).map((point) =>
          LatLng(point['lat'], point['lng'])
      ).toList(),
      distance: map['distance'],
      duration: Duration(seconds: map['duration']),
      pace: map['pace'],
      comments: (map['comments'] as List?)?.map((c) => Comment.fromMap(c)).toList() ?? [],
      likes: List<String>.from(map['likes'] ?? []),
      additionalData: map['additionalData'],
      caption: map['caption'],
      photos: List<String>.from(map['photos'] ?? []),
    );
  }
}
