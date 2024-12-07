import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_project_fitquest/domain/repository/social_repository.dart';
import '../entities/social/comment.dart';
import '../entities/social/shared_workout.dart';
import '../entities/social/social_profile.dart';

class FirebaseSocialRepository implements SocialRepository {
  final FirebaseFirestore _firestore;

  FirebaseSocialRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('social_profiles');

  CollectionReference<Map<String, dynamic>> get _workouts =>
      _firestore.collection('shared_workouts');

  @override
  Future<SocialProfile> getProfile(String userId) async {
    final doc = await _profiles.doc(userId).get();
    if (!doc.exists) {
      throw Exception('Profile not found');
    }
    return SocialProfile.fromMap({...doc.data()!, 'userId': doc.id});
  }

  @override
  Future<void> updateProfile(SocialProfile profile) async {
    await _profiles.doc(profile.userId).set(profile.toMap());
  }

  @override
  Future<List<SocialProfile>> searchUsers(String query) async {
    final snapshot = await _profiles
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: query + 'z')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => SocialProfile.fromMap({...doc.data(), 'userId': doc.id}))
        .toList();
  }

  @override
  Future<void> followUser(String userId, String targetUserId) async {
    final batch = _firestore.batch();

    // Update follower's following list
    batch.update(_profiles.doc(userId), {
      'following': FieldValue.arrayUnion([targetUserId]),
      'followingCount': FieldValue.increment(1),
    });

    // Update target's followers list
    batch.update(_profiles.doc(targetUserId), {
      'followers': FieldValue.arrayUnion([userId]),
      'followersCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  @override
  Future<void> unfollowUser(String userId, String targetUserId) async {
    final batch = _firestore.batch();

    batch.update(_profiles.doc(userId), {
      'following': FieldValue.arrayRemove([targetUserId]),
      'followingCount': FieldValue.increment(-1),
    });

    batch.update(_profiles.doc(targetUserId), {
      'followers': FieldValue.arrayRemove([userId]),
      'followersCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  @override
  Stream<List<SharedWorkout>> getFeed(String userId) {
    return _profiles.doc(userId).snapshots().asyncMap((profile) async {
      if (!profile.exists) return [];

      final following = List<String>.from(profile.data()!['following'] ?? []);
      following.add(userId); // Include user's own workouts

      final snapshot = await _workouts
          .where('userId', whereIn: following)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => SharedWorkout.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  @override
  Future<void> shareWorkout(SharedWorkout workout) async {
    await _workouts.doc(workout.id).set(workout.toMap());
  }

  @override
  Future<void> likeWorkout(String userId, String workoutId) async {
    await _workouts.doc(workoutId).update({
      'likes': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> unlikeWorkout(String userId, String workoutId) async {
    await _workouts.doc(workoutId).update({
      'likes': FieldValue.arrayRemove([userId]),
    });
  }

  @override
  Future<void> addComment(String workoutId, Comment comment) async {
    await _workouts.doc(workoutId).update({
      'comments': FieldValue.arrayUnion([comment.toMap()]),
    });
  }

  @override
  Future<void> deleteComment(String workoutId, String commentId) async {
    final workout = await _workouts.doc(workoutId).get();
    final comments = List<Comment>.from(
      (workout.data()!['comments'] as List)
          .map((c) => Comment.fromMap(c))
          .where((c) => c.id != commentId),
    );

    await _workouts.doc(workoutId).update({
      'comments': comments.map((c) => c.toMap()).toList(),
    });
  }

  @override
  Future<List<Comment>> getComments(String workoutId) async {
    final doc = await _workouts.doc(workoutId).get();
    final comments = doc.data()!['comments'] as List?;
    if (comments == null) return [];

    return comments.map((c) => Comment.fromMap(c)).toList();
  }

  @override
  Future<List<SocialProfile>> getFollowers(String userId) async {
    final profile = await getProfile(userId);
    return Future.wait(
      profile.followers.map((id) => getProfile(id)),
    );
  }

  @override
  Future<List<SocialProfile>> getFollowing(String userId) async {
    final profile = await getProfile(userId);
    return Future.wait(
      profile.following.map((id) => getProfile(id)),
    );
  }

  @override
  Future<void> deleteSharedWorkout(String workoutId) async {
    await _workouts.doc(workoutId).delete();
  }
}