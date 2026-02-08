import 'dart:convert';
import 'package:lockedin_frontend/config/api_config.dart';
import 'package:lockedin_frontend/services/api_client.dart';

class NetworkHelper {
  /// Test basic internet connectivity
  static Future<bool> hasInternetConnection() async {
    return await ApiClient.testConnection();
  }

  /// Test backend server connectivity
  static Future<Map<String, dynamic>> testServerConnection() async {
    try {
      // Try connecting to the login endpoint with a simple GET request
      final response = await ApiClient.get(ApiConfig.login.replaceAll('/login', '/health'));
      return {
        'success': true,
        'message': 'Server is reachable',
        'statusCode': response.statusCode
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot reach server: ${e.toString()}'
      };
    }
  }

  /// Get detailed network diagnosis
  static Future<Map<String, dynamic>> getDiagnosis() async {
    final Map<String, dynamic> diagnosis = {
      'internetConnection': false,
      'serverConnection': false,
      'timestamp': DateTime.now().toIso8601String(),
      'apiBaseUrl': ApiConfig.login.split('/').sublist(0, 3).join('/'),
    };

    try {
      // Test internet connectivity
      diagnosis['internetConnection'] = await hasInternetConnection();
      
      if (diagnosis['internetConnection']) {
        // Test server connectivity
        final serverTest = await testServerConnection();
        diagnosis['serverConnection'] = serverTest['success'];
        diagnosis['serverMessage'] = serverTest['message'];
      } else {
        diagnosis['serverMessage'] = 'No internet connection';
      }
    } catch (e) {
      diagnosis['error'] = e.toString();
    }

    return diagnosis;
  }

  /// Get user-friendly error message based on diagnosis
  static Future<String> getConnectionIssueMessage() async {
    final diagnosis = await getDiagnosis();
    
    if (!diagnosis['internetConnection']) {
      return 'No internet connection detected. Please check your WiFi or mobile data and try again.';
    }
    
    if (!diagnosis['serverConnection']) {
      return 'Cannot connect to server at ${diagnosis['apiBaseUrl']}. The server might be down or the URL might be incorrect.';
    }
    
    return 'Connection looks good. The issue might be temporary - please try again.';
  }
}