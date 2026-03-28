import 'env.dart';

class ApiConfig {
  static String login = '${Env.apiBaseUrl}/auth/login';
  static String register = '${Env.apiBaseUrl}/auth/register';
  static String googleSignIn = '${Env.apiBaseUrl}/auth/google';
  static String deleteAccount = '${Env.apiBaseUrl}/setting/delete';
  static String forgotPassword = '${Env.apiBaseUrl}/auth/forgot-password';
  static String get verifyEmailOTP => '${Env.apiBaseUrl}/auth/verify-email';
  static String sendOTP = '${Env.apiBaseUrl}/password/forgot';
  static String resetPasswordWithOTP = '${Env.apiBaseUrl}/password/reset';
  static String pomodoro = '${Env.apiBaseUrl}/pomodoro/session';
  static String flashcards = '${Env.apiBaseUrl}/flashcard';
  static String pomodoroRanking = '${Env.apiBaseUrl}/pomodoro/ranking';
  static String pomodoroStats = '${Env.apiBaseUrl}/pomodoro/stats';
  static String books = '${Env.apiBaseUrl}/books';
  static String bookFavorites = '${Env.apiBaseUrl}/books/favorites';
  static String bookReviews = '${Env.apiBaseUrl}/books/reviews';
}
