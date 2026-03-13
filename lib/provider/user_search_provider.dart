import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/user/search_user_model.dart';

import '../services/user_service.dart';

enum UserSearchStatus { idle, loading, success, error }

class UserSearchProvider extends ChangeNotifier {
  final UserService _service;

  UserSearchStatus _status = UserSearchStatus.idle;
  List<SearchUserResult> _results = [];
  String? _errorMessage;

  UserSearchProvider({required UserService service}) : _service = service;

  UserSearchStatus get status => _status;
  List<SearchUserResult> get results => _results;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == UserSearchStatus.loading;

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _results = [];
      _status = UserSearchStatus.idle;
      notifyListeners();
      return;
    }

    _status = UserSearchStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _results = await _service.searchUsers(query.trim());
      _status = UserSearchStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = UserSearchStatus.error;
    }
    notifyListeners();
  }

  Future<void> toggleFollow(String userId) async {
    final index = _results.indexWhere((u) => u.id == userId);
    if (index == -1) return;

    final current = _results[index];
    // Optimistic update — flip immediately, revert on error
    _results[index] = current.copyWith(isFollowing: !current.isFollowing);
    notifyListeners();

    try {
      if (current.isFollowing) {
        await _service.unfollowUser(userId);
      } else {
        await _service.followUser(userId);
      }
    } catch (e) {
      // Revert on failure
      _results[index] = current;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clear() {
    _results = [];
    _status = UserSearchStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void updateFollowState(String userId, bool isFollowing) {
    final index = _results.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _results[index] = _results[index].copyWith(isFollowing: isFollowing);
      notifyListeners();
    }
  }
}
