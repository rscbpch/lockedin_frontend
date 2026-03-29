// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'dart:io' show Platform;

// class Env {
//   /// Returns the correct API base URL for the current platform.
//   ///
//   /// - iOS simulator shares the host network → uses `localhost`.
//   /// - Android emulator uses `10.0.2.2` to reach the host loopback.
//   /// - Falls back to the raw .env value for physical devices / other cases.
//   static String get apiBaseUrl {
//     final raw = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

//     // When running on a simulator/emulator that talks to localhost, replace
//     // any hardcoded LAN IP (or localhost) with the right loopback alias.
//     final uri = Uri.parse(raw);
//     final port = uri.port; // e.g. 3000
//     final path = uri.path; // e.g. /api

//     if (Platform.isAndroid) {
//       // 10.0.2.2 is the Android emulator alias for the host machine's loopback
//       return 'http://10.0.2.2:$port$path';
//     } else if (Platform.isIOS) {
//       // iOS simulator shares the Mac network stack
//       return 'http://localhost:$port$path';
//     }

//     // Physical device or desktop — use the .env value as-is
//     return raw;
//   }

//   static String? get googleClientId {
//     if (Platform.isIOS) {
//       return dotenv.env['GOOGLE_CLIENT_ID_IOS'];
//     } else if (Platform.isAndroid) {
//       return dotenv.env['GOOGLE_CLIENT_ID_ANDROID'];
//     }
//     return null;
//   }

//   static String? get googleWebClientId => dotenv.env['GOOGLE_CLIENT_ID_WEB'];
// }

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;

class Env {
  static String get apiBaseUrl {
    final raw = dotenv.env['API_BASE_URL'] ?? 'https://lockedinbackend-production.up.railway.app/api';

    try {
      final uri = Uri.parse(raw);
      // If the path already contains an `api` segment, return as-is
      if (uri.pathSegments.contains('api')) return raw;

      // Otherwise append `/api` preserving existing path and query
      final newPath = uri.path.isEmpty || uri.path == '/' ? '/api' : (uri.path.endsWith('/') ? '${uri.path}api' : '${uri.path}/api');
      final fixed = Uri(
        scheme: uri.scheme,
        userInfo: uri.userInfo,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: newPath,
        query: uri.query,
        fragment: uri.fragment,
      ).toString();

      return fixed;
    } catch (_) {
      // If parsing fails, fall back to raw value
      return raw;
    }
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