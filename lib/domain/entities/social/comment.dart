class Comment {
  final String id;
  final String userId;
  final String text;
  final DateTime timestamp;
  final List<String> likes;
  final String? parentId;

  Comment({
    required this.id,
    required this.userId,
    required this.text,
    required this.timestamp,
    this.likes = const [],
    this.parentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'likes': likes,
      'parentId': parentId,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      userId: map['userId'],
      text: map['text'],
      timestamp: DateTime.parse(map['timestamp']),
      likes: List<String>.from(map['likes'] ?? []),
      parentId: map['parentId'],
    );
  }
}