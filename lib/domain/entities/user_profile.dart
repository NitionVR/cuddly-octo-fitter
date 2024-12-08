
class UserProfile {
  final String userId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final double? weight; // in kg
  final double? height; // in cm
  final DateTime? dateOfBirth;
  final String? gender;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime lastModified;

  UserProfile({
    required this.userId,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.weight,
    this.height,
    this.dateOfBirth,
    this.gender,
    this.preferences,
    required this.createdAt,
    DateTime? lastModified,
  }) : lastModified = lastModified ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'weight': weight,
      'height': height,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'preferences': preferences,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'],
      email: map['email'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      weight: map['weight'],
      height: map['height'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'])
          : null,
      gender: map['gender'],
      preferences: map['preferences'],
      createdAt: DateTime.parse(map['createdAt']),
      lastModified: DateTime.parse(map['lastModified']),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    double? weight,
    double? height,
    DateTime? dateOfBirth,
    String? gender,
    Map<String, dynamic>? preferences,
    DateTime? lastModified,
  }) {
    return UserProfile(
      userId: userId,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
      lastModified: lastModified ?? DateTime.now(),
    );
  }

  double? get bmi {
    if (weight == null || height == null) return null;
    return weight! / ((height! / 100) * (height! / 100));
  }

  String? get formattedBMI {
    final bmiValue = bmi;
    if (bmiValue == null) return null;
    return bmiValue.toStringAsFixed(1);
  }
}