//
// import 'package:flutter/foundation.dart';
//
// import '../../../domain/entities/social/social_profile.dart';
// import '../../../domain/repository/social/social_repository.dart';
//
//
// class ProfileViewModel extends ChangeNotifier {
//   final SocialRepository _repository;
//   final String profileId;
//   final String currentUserId;
//
//   SocialProfile? _profile;
//   List<SocialProfile> _followers = [];
//   List<SocialProfile> _following = [];
//   bool _isLoading = false;
//   String? _error;
//
//   ProfileViewModel(this._repository, this.profileId, this.currentUserId) {
//     _loadProfile();
//   }
//
//   SocialProfile? get profile => _profile;
//   List<SocialProfile> get followers => _followers;
//   List<SocialProfile> get following => _following;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   bool get isCurrentUser => profileId == currentUserId;
//   bool get isFollowing => _profile?.followers.contains(currentUserId) ?? false;
//
//   Future<void> _loadProfile() async {
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       _profile = await _repository.getProfile(profileId);
//       _followers = await _repository.getFollowers(profileId);
//       _following = await _repository.getFollowing(profileId);
//       _error = null;
//     } catch (e) {
//       _error = 'Failed to load profile: $e';
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> toggleFollow() async {
//     if (_profile == null) return;
//
//     try {
//       if (isFollowing) {
//         await _repository.unfollowUser(currentUserId, profileId);
//       } else {
//         await _repository.followUser(currentUserId, profileId);
//       }
//       await _loadProfile();
//     } catch (e) {
//       _error = 'Failed to update follow status: $e';
//       notifyListeners();
//     }
//   }
//
//   Future<void> updateProfile(SocialProfile updatedProfile) async {
//     try {
//       await _repository.updateProfile(updatedProfile);
//       await _loadProfile();
//     } catch (e) {
//       _error = 'Failed to update profile: $e';
//       notifyListeners();
//     }
//   }
//
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }
// }
