import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  static const int connectTimeoutSeconds = 15;
  static const int receiveTimeoutSeconds = 30;
  static const int maxRetries = 2;

  static final http.Client _client = http.Client();

  // Test network connectivity
  static Future<bool> testConnection() async {
    try {
      final response = await _client
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    int retryCount = 0,
  }) async {
    try {
      final uri = Uri.parse(url);
      // Debug logging
      // ignore: avoid_print
      print('ApiClient.post -> URL: $url (attempt ${retryCount + 1})');
      // ignore: avoid_print
      print('ApiClient.post -> Headers: $headers');
      
      final response = await _client
          .post(
            uri,
            headers: headers ?? {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(
            const Duration(seconds: receiveTimeoutSeconds),
            onTimeout: () {
              throw TimeoutException(
                'Request timed out after ${receiveTimeoutSeconds}s',
                const Duration(seconds: receiveTimeoutSeconds),
              );
            },
          );
          
      // Debug logging
      // ignore: avoid_print
      print('ApiClient.post -> Response status: ${response.statusCode}');
      return response;
    } on SocketException catch (e) {
      if (retryCount < maxRetries) {
        // ignore: avoid_print
        print('SocketException occurred, retrying... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        return post(url, headers: headers, body: body, retryCount: retryCount + 1);
      }
      throw Exception(
        'No internet connection. Please check your network and try again. (${e.message})',
      );
    } on TimeoutException {
      if (retryCount < maxRetries) {
        // ignore: avoid_print
        print('TimeoutException occurred, retrying... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        return post(url, headers: headers, body: body, retryCount: retryCount + 1);
      }
      throw Exception(
        'Request timed out. Please check your network connection and try again.',
      );
    } on HttpException catch (e) {
      throw Exception('HTTP Error: ${e.message}');
    } catch (e) {
      if (retryCount < maxRetries && 
          (e.toString().contains('Connection refused') || 
           e.toString().contains('Failed to connect'))) {
        // ignore: avoid_print
        print('Connection error occurred, retrying... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        return post(url, headers: headers, body: body, retryCount: retryCount + 1);
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  static Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    int retryCount = 0,
  }) async {
    try {
      final uri = Uri.parse(url);
      // Debug logging
      // ignore: avoid_print
      print('ApiClient.get -> URL: $url (attempt ${retryCount + 1})');
      
      final response = await _client
          .get(
            uri,
            headers: headers ?? {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: receiveTimeoutSeconds),
            onTimeout: () {
              throw TimeoutException(
                'Request timed out after ${receiveTimeoutSeconds}s',
                const Duration(seconds: receiveTimeoutSeconds),
              );
            },
          );
          
      // Debug logging
      // ignore: avoid_print
      print('ApiClient.get -> Response status: ${response.statusCode}');
      return response;
    } on SocketException catch (e) {
      if (retryCount < maxRetries) {
        // ignore: avoid_print
        print('SocketException occurred, retrying... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        return get(url, headers: headers, retryCount: retryCount + 1);
      }
      throw Exception(
        'No internet connection. Please check your network and try again. (${e.message})',
      );
    } on TimeoutException {
      if (retryCount < maxRetries) {
        // ignore: avoid_print
        print('TimeoutException occurred, retrying... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        return get(url, headers: headers, retryCount: retryCount + 1);
      }
      throw Exception(
        'Request timed out. Please check your network connection and try again.',
      );
    } on HttpException catch (e) {
      throw Exception('HTTP Error: ${e.message}');
    } catch (e) {
      if (retryCount < maxRetries && 
          (e.toString().contains('Connection refused') || 
           e.toString().contains('Failed to connect'))) {
        // ignore: avoid_print
        print('Connection error occurred, retrying... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        return get(url, headers: headers, retryCount: retryCount + 1);
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  static void dispose() {
    _client.close();
  }
}