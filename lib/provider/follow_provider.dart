import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/user/follow_user_model.dart';
import 'package:lockedin_frontend/services/follow_service.dart';

enum FollowStatus { idle, loading, success, error }

class FollowProvider extends ChangeNotifier {
  final FollowService _service;

  FollowStatus _status = FollowStatus.idle;
  String? _errorMessage;
  List<FollowUser> _followers = [];
  List<FollowUser> _following = [];

  // Tracks which userIds have a pending follow/unfollow in flight
  final Set<String> _pending = {};

  FollowProvider({required FollowService service}) : _service = service;

  FollowStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<FollowUser> get followers => _followers;
  List<FollowUser> get following => _following;

  bool isFollowing(String userId) => _following.any((u) => u.id == userId);
  bool isMutual(String userId) => _following.any((u) => u.id == userId && u.isMutual);
  bool isPending(String userId) => _pending.contains(userId);

  /// Load both lists at once
  Future<void> fetchAll() async {
    _status = FollowStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getFollowers(),
        _service.getFollowing(),
      ]);
      _followers = results[0];
      _following = results[1];
      _status = FollowStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = FollowStatus.error;
    }
    notifyListeners();
  }

  Future<void> fetchFollowers() async {
    try {
      _followers = await _service.getFollowers();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchFollowing() async {
    try {
      _following = await _service.getFollowing();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Follow a user — optimistic update
  Future<bool> followUser(String targetUserId) async {
    _pending.add(targetUserId);
    notifyListeners();

    try {
      await _service.followUser(targetUserId);
      _pending.remove(targetUserId);
      // Refresh to get updated isMutual status
      await fetchAll();
      return true;
    } catch (e) {
      _pending.remove(targetUserId);
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Unfollow a user — optimistic update
  Future<bool> unfollowUser(String targetUserId) async {
    _pending.add(targetUserId);
    notifyListeners();

    try {
      await _service.unfollowUser(targetUserId);
      _pending.remove(targetUserId);
      // Remove from following list immediately
      _following.removeWhere((u) => u.id == targetUserId);
      // Mark as no longer mutual in followers list
      _followers = _followers.map((u) {
        if (u.id == targetUserId) {
          return FollowUser(
            id: u.id,
            username: u.username,
            displayName: u.displayName,
            avatar: u.avatar,
            isMutual: false,
          );
        }
        return u;
      }).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _pending.remove(targetUserId);
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}