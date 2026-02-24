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
        if (_token != null) {
          try {
            _currentUser = await UserProfileService.fetchMyProfile(_token!);
          } catch (profileError) {
            debugPrint('Failed to fetch profile after login: $profileError');
            // Fallback: build user from the login response data
            final userData = response['data']?['user'] ?? response['user'];
            if (userData is Map<String, dynamic>) {
              _currentUser = User.fromJson(userData);
            }
          }
        }
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

        // Try to fetch profile, but don't block sign-in if it fails
        if (_token != null) {
          try {
            _currentUser = await UserProfileService.fetchMyProfile(_token!);
          } catch (profileError) {
            debugPrint(
              'Failed to fetch profile after Google sign-in: $profileError',
            );
            // Fallback: build user from the sign-in response data
            final userData = response['data']?['user'] ?? response['user'];
            if (userData is Map<String, dynamic>) {
              _currentUser = User.fromJson(userData);
            }
          }
        }

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

  // ----------Get User Profile----------
  Future<void> fetchMyProfile() async {
    if (_token == null) return;

    isLoading = true;
    notifyListeners();

    try {
      _currentUser = await UserProfileService.fetchMyProfile(_token!);
    } catch (e) {
      errorMessage = 'Failed to load profile';
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
    required String avatar,
  }) async {
    if (_token == null) return;

    isLoading = true;
    notifyListeners();

    try {
      _currentUser = await UserProfileService.updateMyProfile(
        token: _token!,
        username: username,
        bio: bio,
        displayName: displayName,
        avatar: avatar,
      );
    } catch (e) {
      errorMessage = 'Failed to update profile';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
