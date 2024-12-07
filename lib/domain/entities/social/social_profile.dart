// class SocialProfile {
//   final String userId;
//   final String username;
//   final String? photoUrl;
//   final String? bio;
//   final int followersCount;
//   final int followingCount;
//   final List<String> followers;
//   final List<String> following;
//   final Map<String, dynamic>? stats;
//   final DateTime lastActive;
//
//   SocialProfile({
//     required this.userId,
//     required this.username,
//     this.photoUrl,
//     this.bio,
//     this.followersCount = 0,
//     this.followingCount = 0,
//     this.followers = const [],
//     this.following = const [],
//     this.stats,
//     required this.lastActive,
//   });
//
//   Map<String, dynamic> toMap() {
//     return {
//       'userId': userId,
//       'username': username,
//       'photoUrl': photoUrl,
//       'bio': bio,
//       'followersCount': followersCount,
//       'followingCount': followingCount,
//       'followers': followers,
//       'following': following,
//       'stats': stats,
//       'lastActive': lastActive.toIso8601String(),
//     };
//   }
//
//   factory SocialProfile.fromMap(Map<String, dynamic> map) {
//     return SocialProfile(
//       userId: map['userId'],
//       username: map['username'],
//       photoUrl: map['photoUrl'],
//       bio: map['bio'],
//       followersCount: map['followersCount'] ?? 0,
//       followingCount: map['followingCount'] ?? 0,
//       followers: List<String>.from(map['followers'] ?? []),
//       following: List<String>.from(map['following'] ?? []),
//       stats: map['stats'],
//       lastActive: DateTime.parse(map['lastActive']),
//     );
//   }
//
//   SocialProfile copyWith({
//     String? username,
//     String? photoUrl,
//     String? bio,
//     int? followersCount,
//     int? followingCount,
//     List<String>? followers,
//     List<String>? following,
//     Map<String, dynamic>? stats,
//     DateTime? lastActive,
//   }) {
//     return SocialProfile(
//       userId: this.userId,
//       username: username ?? this.username,
//       photoUrl: photoUrl ?? this.photoUrl,
//       bio: bio ?? this.bio,
//       followersCount: followersCount ?? this.followersCount,
//       followingCount: followingCount ?? this.followingCount,
//       followers: followers ?? this.followers,
//       following: following ?? this.following,
//       stats: stats ?? this.stats,
//       lastActive: lastActive ?? this.lastActive,
//     );
//   }
// }
