import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;

class Env {
  /// Returns the correct API base URL for the current platform.
  ///
  /// - iOS simulator shares the host network → uses `localhost`.
  /// - Android emulator is configured to use `localhost`.
  /// - Falls back to the raw .env value for physical devices / other cases.
  static String get apiBaseUrl {
    final raw = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

    // When running on a simulator/emulator that talks to localhost, replace
    // any hardcoded LAN IP (or localhost) with the right loopback alias.
    final uri = Uri.parse(raw);
    final port = uri.port; // e.g. 3000
    final path = uri.path; // e.g. /api

    if (Platform.isAndroid) {
      return 'http://localhost:$port$path';
    } else if (Platform.isIOS) {
      // iOS simulator shares the Mac network stack
      return 'http://localhost:$port$path';
    }

    // Physical device or desktop — use the .env value as-is
    return raw;
  }

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
