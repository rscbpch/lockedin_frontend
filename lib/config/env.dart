import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;

class Env {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL']!;
  
  static String? get googleClientId {
    if (Platform.isIOS) {
      return dotenv.env['GOOGLE_CLIENT_ID_IOS'];
    } else if (Platform.isAndroid) {
      return dotenv.env['GOOGLE_CLIENT_ID_ANDROID'];
    }
    return null;
  }
  
  static String? get googleWebClientId => dotenv.env['GOOGLE_CLIENT_ID_WEB'];
}