// import 'dart:async';
//
// import 'package:flutter/foundation.dart';
// import '../../../domain/entities/social/comment.dart';
// import '../../../domain/entities/social/shared_workout.dart';
// import '../../../domain/entities/social/social_profile.dart';
// import '../../../domain/repository/social/social_repository.dart';
//
// class SocialViewModel extends ChangeNotifier {
//   final SocialRepository _repository;
//   final String userId;
//
//   List<SharedWorkout> _feed = [];
//   SocialProfile? _userProfile;
//   bool _isLoading = false;
//   String? _error;
//   StreamSubscription? _feedSubscription;
//
//   SocialViewModel(this._repository, this.userId) {
//     _initialize();
//   }
//
//   List<SharedWorkout> get feed => _feed;
//   SocialProfile? get userProfile => _userProfile;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//
//   void _initialize() {
//     _loadUserProfile();
//     _subscribeFeed();
//   }
//
//   Future<void> _loadUserProfile() async {
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       _userProfile = await _repository.getProfile(userId);
//       _error = null;
//     } catch (e) {
//       _error = 'Failed to load profile: $e';
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   void _subscribeFeed() {
//     _feedSubscription?.cancel();
//     _feedSubscription = _repository.getFeed(userId).listen(
//           (workouts) {
//         _feed = workouts;
//         notifyListeners();
//       },
//       onError: (e) {
//         _error = 'Failed to load feed: $e';
//         notifyListeners();
//       },
//     );
//   }
//
//   Future<void> shareWorkout(SharedWorkout workout) async {
//     try {
//       await _repository.shareWorkout(workout);
//       _error = null;
//     } catch (e) {
//       _error = 'Failed to share workout: $e';
//       notifyListeners();
//     }
//   }
//
//   Future<void> likeWorkout(String workoutId) async {
//     try {
//       await _repository.likeWorkout(userId, workoutId);
//       _error = null;
//     } catch (e) {
//       _error = 'Failed to like workout: $e';
//       notifyListeners();
//     }
//   }
//
//   Future<void> unlikeWorkout(String workoutId) async {
//     try {
//       await _repository.unlikeWorkout(userId, workoutId);
//       _error = null;
//     } catch (e) {
//       _error = 'Failed to unlike workout: $e';
//       notifyListeners();
//     }
//   }
//
//   Future<void> addComment(String workoutId, String text) async {
//     try {
//       final comment = Comment(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         userId: userId,
//         text: text,
//         timestamp: DateTime.now(),
//       );
//       await _repository.addComment(workoutId, comment);
//       _error = null;
//     } catch (e) {
//       _error = 'Failed to add comment: $e';
//       notifyListeners();
//     }
//   }
//
//   Future<void> deleteComment(String workoutId, String commentId) async {
//     try {
//       await _repository.deleteComment(workoutId, commentId);
//       _error = null;
//     } catch (e) {
//       _error = 'Failed to delete comment: $e';
//       notifyListeners();
//     }
//   }
//
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }
//
//   @override
//   void dispose() {
//     _feedSubscription?.cancel();
//     super.dispose();
//   }
//
//   void deleteWorkout(String id) {}
//
//   loadFeed() {}
//
//   void reportWorkout(String id, String reason) {}
// }
//


