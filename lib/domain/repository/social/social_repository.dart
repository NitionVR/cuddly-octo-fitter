// import '../../entities/social/comment.dart';
// import '../../entities/social/shared_workout.dart';
// import '../../entities/social/social_profile.dart';
//
// abstract class SocialRepository {
//   // Profile management
//   Future<SocialProfile> getProfile(String userId);
//   Future<void> updateProfile(SocialProfile profile);
//   Future<List<SocialProfile>> searchUsers(String query);
//
//   // Following/Followers
//   Future<void> followUser(String userId, String targetUserId);
//   Future<void> unfollowUser(String userId, String targetUserId);
//   Future<List<SocialProfile>> getFollowers(String userId);
//   Future<List<SocialProfile>> getFollowing(String userId);
//
//   // Feed
//   Stream<List<SharedWorkout>> getFeed(String userId);
//   Future<void> shareWorkout(SharedWorkout workout);
//   Future<void> deleteSharedWorkout(String workoutId);
//
//   // Interactions
//   Future<void> likeWorkout(String userId, String workoutId);
//   Future<void> unlikeWorkout(String userId, String workoutId);
//   Future<void> addComment(String workoutId, Comment comment);
//   Future<void> deleteComment(String workoutId, String commentId);
//   Future<List<Comment>> getComments(String workoutId);
// }