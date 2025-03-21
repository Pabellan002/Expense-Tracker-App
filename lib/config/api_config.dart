import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConfig {
  // Base URLs for different environments
  static const String _webUrl = 'http://localhost/api';
  
  // Update this to your computer's actual IP address on your network
  // You can find this by running 'ipconfig' in Command Prompt on Windows
  static const String _physicalDeviceUrl = 'http://192.168.1.2/api';
  
  static const String _emulatorUrl = 'http://10.0.2.2/api';

  // Get the appropriate base URL based on platform
  static String get baseUrl {
    try {
      if (kIsWeb) {
        print('Running on web, using localhost');
        return _webUrl;
      }

      if (Platform.isAndroid) {
        final model = Platform.environment['ANDROID_HARDWARE'] ?? '';
        final isEmulator =
            model.contains('goldfish') || model.contains('ranchu');

        if (isEmulator) {
          print('Running on Android emulator, using 10.0.2.2');
          return _emulatorUrl;
        } else {
          print('Running on physical device, using IP address');
          return _physicalDeviceUrl;
        }
      }

      return _webUrl;
    } catch (e) {
      print('Error detecting platform: $e');
      return _webUrl;
    }
  }

  // Endpoint getters
  static String get userEndpoint => '$baseUrl/user.php';
  static String get transactionEndpoint => '$baseUrl/transaction.php';
  static String get uploadImageEndpoint => '$baseUrl/upload_profile_image.php';

  // Utility methods
  static void printCurrentUrl() {
    print('\n=== API Configuration ===');
    if (kIsWeb) {
      print('Platform: Web (Chrome)');
    } else if (Platform.isAndroid) {
      final model = Platform.environment['ANDROID_HARDWARE'] ?? '';
      final isEmulator = model.contains('goldfish') || model.contains('ranchu');
      print(
          'Platform: ${isEmulator ? 'Android Emulator' : 'Physical Android Device'}');
    }
    print('Base URL: $baseUrl');
    print('User endpoint: $userEndpoint');
    print('Transaction endpoint: $transactionEndpoint');
    print('Upload image endpoint: $uploadImageEndpoint');
    print('========================\n');
  }

  static Map<String, String> createRequestBody(
      String operation, Map<String, dynamic> data) {
    return {
      'operation': operation,
      'json': jsonEncode(data),
    };
  }

  static Future<http.Response> postRequest(
      String endpoint, String operation, Map<String, dynamic> data) async {
    print('\n=== Making POST Request ===');
    print('Endpoint: $endpoint');
    print('Operation: $operation');
    print('Data: $data');

    final Map<String, String> headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Accept'
    };

    final Map<String, String> body = {
      'operation': operation,
      'json': jsonEncode(data),
    };

    print('Request Headers: $headers');
    print('Request Body: $body');

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: body,
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('========================\n');

      return response;
    } catch (e) {
      print('Error making POST request: $e');
      rethrow;
    }
  }
}
