import 'env.dart';

class ApiConfig {
  static String login = '${Env.apiBaseUrl}/auth/login';
  static String register = '${Env.apiBaseUrl}/auth/register';
  static String forgotPassword = '${Env.apiBaseUrl}/auth/forgot-password';
}
