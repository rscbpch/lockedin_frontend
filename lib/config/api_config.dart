import 'env.dart';

class ApiConfig {
  static String login = '${Env.apiBaseUrl}/auth/login';
  static String register = '${Env.apiBaseUrl}/auth/register';
  static String forgotPassword = '${Env.apiBaseUrl}/auth/forgot-password';
  static String sendOTP = '${Env.apiBaseUrl}/password/forgot';
  static String resetPasswordWithOTP = '${Env.apiBaseUrl}/password/reset';
  static String pomodoro = '${Env.apiBaseUrl}/pomodoro/session';
  static String flashcards = '${Env.apiBaseUrl}/flashcards';
  static String pomodoroRanking = '${Env.apiBaseUrl}/pomodoro/ranking';
  static String pomodoroStats = '${Env.apiBaseUrl}/pomodoro/stats';
}
