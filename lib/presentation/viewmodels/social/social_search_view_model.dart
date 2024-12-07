
import '../../domain/entities/social/social_profile.dart';
import '../../domain/repository/social_repository.dart';
import 'package:flutter/foundation.dart';

class SocialSearchViewModel extends ChangeNotifier {
  final SocialRepository _repository;

  List<SocialProfile> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  SocialSearchViewModel(this._repository);

  List<SocialProfile> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await _repository.searchUsers(query);
      _error = null;
    } catch (e) {
      _error = 'Failed to search users: $e';
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _error = null;
    notifyListeners();
  }
}