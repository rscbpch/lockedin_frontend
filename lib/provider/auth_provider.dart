import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

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

  Future<bool> signInWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await AuthService.signInWithGoogle();

      if (response['success'] == true) {
        return true;
      } else {
        errorMessage = response['message'] ?? 'Google sign-in failed';
        return false;
      }
    } catch (e) {
      errorMessage = 'Google sign-in error';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
