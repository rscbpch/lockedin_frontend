// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';

// class AuthProvider extends ChangeNotifier {
//   bool isLoading = false;
//   String? errorMessage;

//   String? token;

//   Future<bool> register({
//     required String email,
//     required String username,
//     required String password,
//     required String confirmPassword,
//   }) async {
//     isLoading = true;
//     errorMessage = null;
//     notifyListeners();

//     try {
//       final response = await AuthService.register(
//         email: email,
//         username: username,
//         password: password,
//         confirmPassword: confirmPassword,
//       );

//       if (response['success'] == true) {
//         return true;
//       } else {
//         errorMessage = response['message'] ?? 'Registration failed';
//         return false;
//       }
//     } catch (e) {
//       errorMessage = 'Server error';
//       return false;
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<bool> login({required String email, required String password}) async {
//     isLoading = true;
//     errorMessage = null;
//     notifyListeners();

//     try {
//       final response = await AuthService.login(
//         email: email,
//         password: password,
//       );

//       if (response['success'] == true) {
//         return true;
//       } else {
//         errorMessage = response['message'] ?? 'Login failed';
//         return false;
//       }
//     } catch (e) {
//       errorMessage = 'Server error';
//       return false;
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<bool> signInWithGoogle() async {
//     isLoading = true;
//     errorMessage = null;
//     notifyListeners();

//     try {
//       final response = await AuthService.signInWithGoogle();

//       if (response['success'] == true) {
//         return true;
//       } else {
//         errorMessage = response['message'] ?? 'Google sign-in failed';
//         return false;
//       }
//     } catch (e) {
//       errorMessage = 'Google sign-in error';
//       return false;
//     } finally {
//       isLoading = false;
//       notifyListeners();
//     }
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lockedin_frontend/models/user/user.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  String? _token;
  User? _currentUser;

  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null;

  // ---------- INITIALIZE (restore session on app launch) ----------
  Future<void> initialize() async {
    _token = await AuthService.getToken();
    notifyListeners();
  }

  // ---------- LOGOUT ----------
  Future<void> logout() async {
    await AuthService.clearToken();
    _token = null;
    _currentUser = null;
    notifyListeners();
  }

  // ---------- LOGIN ----------
  Future<bool> login({required String email, required String password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.login(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _token = response['token'] ?? response['data']?['token'];
        _token ??= await AuthService.getToken();
        return true;
      } else {
        errorMessage = response['message'] ?? 'Login failed';
        return false;
      }
    } catch (e) {
      errorMessage = 'Server error';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------- REGISTER ----------
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.register(
        email: email,
        username: username,
        password: password,
        confirmPassword: confirmPassword,
      );

      if (response['success'] == true) {
        return true;
      } else {
        errorMessage = response['message'] ?? 'Registration failed';
        return false;
      }
    } catch (e) {
      errorMessage = 'Server error';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------- GOOGLE SIGN-IN ----------
  Future<bool> signInWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.signInWithGoogle();

      if (response['success'] == true) {
        _token = response['token'] ?? response['data']?['token'];
        // Fallback: read from secure storage if token wasn't in the response map
        _token ??= await AuthService.getToken();
        return true;
      } else {
        errorMessage = response['message'] ?? 'Google sign-in failed';
        return false;
      }
    } catch (e) {
      errorMessage = 'Google sign-in error: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------- GET USER PROFILE ----------
  Future<void> fetchMyProfile() async {
    // If _token is not in memory (e.g. after hot restart), read from secure storage
    _token ??= await AuthService.getToken();

    if (_token == null) {
      debugPrint('[AuthProvider] fetchMyProfile: no token found anywhere');
      errorMessage = 'Not authenticated';
      notifyListeners();
      return;
    }
    debugPrint(
      '[AuthProvider] fetchMyProfile calling with token: ${_token!.substring(0, 20)}...',
    );

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await UserProfileService.fetchMyProfile(_token!);
      debugPrint(
        '[AuthProvider] fetchMyProfile success: ${_currentUser?.username}',
      );
    } catch (e) {
      debugPrint('[AuthProvider] fetchMyProfile error: $e');
      errorMessage = 'Failed to load profile: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------- UPDATE PROFILE ----------
  Future<void> updateProfile({
    required String username,
    required String bio,
    required String displayName,
    File? avatarFile,
  }) async {
    // Ensure we have a token — try storage if not in memory.
    _token ??= await AuthService.getToken();
    if (_token == null) {
      errorMessage = 'Not authenticated';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 1. Upload avatar if a new image was picked.
      //    uploadAvatar persists the avatar on the server via its own endpoint.
      String? newAvatarUrl;
      if (avatarFile != null) {
        newAvatarUrl = await UserProfileService.uploadAvatar(
          token: _token!,
          imageFile: avatarFile,
        );
        debugPrint('[AuthProvider] avatar uploaded: $newAvatarUrl');
      }

      // 2. Update all fields in one call. If a new image was picked,
      //    include the Cloudinary URL so the server saves everything together.
      await UserProfileService.updateMyProfile(
        token: _token!,
        username: username,
        bio: bio,
        displayName: displayName,
        avatar: newAvatarUrl, // null = don't touch avatar on server
      );

      // 3. Update _currentUser in memory immediately so the UI reflects
      //    the saved values the moment the modal closes.
      //    No background re-fetch — that races against the write and can
      //    return stale data, overwriting what we just saved.
      _currentUser = _currentUser?.copyWith(
        username: username,
        bio: bio,
        displayName: displayName,
        avatar: newAvatarUrl, // null = keep existing avatar
      );

      debugPrint(
        '[AuthProvider] updateProfile success: ${_currentUser?.username}',
      );
    } catch (e) {
      debugPrint('[AuthProvider] updateProfile error: $e');
      errorMessage = 'Failed to update profile: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
