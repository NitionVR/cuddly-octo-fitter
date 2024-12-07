// lib/presentation/viewmodels/social_view_model.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../domain/entities/social/comment.dart';
import '../../domain/entities/social/shared_workout.dart';
import '../../domain/entities/social/social_profile.dart';
import '../../domain/repository/social_repository.dart';

class SocialViewModel extends ChangeNotifier {
  final SocialRepository _repository;
  final String userId;

  List<SharedWorkout> _feed = [];
  SocialProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _feedSubscription;

  SocialViewModel(this._repository, this.userId) {
    _initialize();
  }

  List<SharedWorkout> get feed => _feed;
  SocialProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _initialize() {
    _loadUserProfile();
    _subscribeFeed();
  }

  Future<void> _loadUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await _repository.getProfile(userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeFeed() {
    _feedSubscription?.cancel();
    _feedSubscription = _repository.getFeed(userId).listen(
          (workouts) {
        _feed = workouts;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load feed: $e';
        notifyListeners();
      },
    );
  }

  Future<void> shareWorkout(SharedWorkout workout) async {
    try {
      await _repository.shareWorkout(workout);
      _error = null;
    } catch (e) {
      _error = 'Failed to share workout: $e';
      notifyListeners();
    }
  }

  Future<void> likeWorkout(String workoutId) async {
    try {
      await _repository.likeWorkout(userId, workoutId);
      _error = null;
    } catch (e) {
      _error = 'Failed to like workout: $e';
      notifyListeners();
    }
  }

  Future<void> unlikeWorkout(String workoutId) async {
    try {
      await _repository.unlikeWorkout(userId, workoutId);
      _error = null;
    } catch (e) {
      _error = 'Failed to unlike workout: $e';
      notifyListeners();
    }
  }

  Future<void> addComment(String workoutId, String text) async {
    try {
      final comment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        text: text,
        timestamp: DateTime.now(),
      );
      await _repository.addComment(workoutId, comment);
      _error = null;
    } catch (e) {
      _error = 'Failed to add comment: $e';
      notifyListeners();
    }
  }

  Future<void> deleteComment(String workoutId, String commentId) async {
    try {
      await _repository.deleteComment(workoutId, commentId);
      _error = null;
    } catch (e) {
      _error = 'Failed to delete comment: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    super.dispose();
  }
}

// lib/presentation/viewmodels/profile_view_model.dart
class ProfileViewModel extends ChangeNotifier {
  final SocialRepository _repository;
  final String profileId;
  final String currentUserId;

  SocialProfile? _profile;
  List<SocialProfile> _followers = [];
  List<SocialProfile> _following = [];
  bool _isLoading = false;
  String? _error;

  ProfileViewModel(this._repository, this.profileId, this.currentUserId) {
    _loadProfile();
  }

  SocialProfile? get profile => _profile;
  List<SocialProfile> get followers => _followers;
  List<SocialProfile> get following => _following;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isCurrentUser => profileId == currentUserId;
  bool get isFollowing => _profile?.followers.contains(currentUserId) ?? false;

  Future<void> _loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _repository.getProfile(profileId);
      _followers = await _repository.getFollowers(profileId);
      _following = await _repository.getFollowing(profileId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFollow() async {
    if (_profile == null) return;

    try {
      if (isFollowing) {
        await _repository.unfollowUser(currentUserId, profileId);
      } else {
        await _repository.followUser(currentUserId, profileId);
      }
      await _loadProfile();
    } catch (e) {
      _error = 'Failed to update follow status: $e';
      notifyListeners();
    }
  }

  Future<void> updateProfile(SocialProfile updatedProfile) async {
    try {
      await _repository.updateProfile(updatedProfile);
      await _loadProfile();
    } catch (e) {
      _error = 'Failed to update profile: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// lib/presentation/viewmodels/social_search_view_model.dart
