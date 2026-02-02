import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Prefer an explicit base URL when provided via --dart-define=API_BASE_URL
  static const String _definedBase = String.fromEnvironment('API_BASE_URL');

  // Use emulator loopback for Android emulators; localhost for web/desktop.
  static String get baseUrl {
    if (_definedBase.isNotEmpty) return _definedBase;
    if (kIsWeb) return "http://127.0.0.1:5000";
    if (Platform.isAndroid) return "http://10.0.2.2:5000";
    return "http://127.0.0.1:5000";
  }

  static Future<Map<String, dynamic>> predictDisease(
      List<String> symptoms) async {
    final url = Uri.parse("$baseUrl/predict");
    
    // Debug logging
    if (kDebugMode) {
      print('🔍 API Request to: $url');
      print('📋 Symptoms: $symptoms');
    }

    try {
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"symptoms": symptoms}),
          )
          // Avoid hanging indefinitely if the backend isn't reachable
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print('✅ Response status: ${response.statusCode}');
        print('📦 Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Prediction failed: ${response.statusCode} - ${response.body}");
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) print('⏱️ Timeout: $e');
      throw Exception("Request timed out. Check if backend is running on $baseUrl");
    } on SocketException catch (e) {
      if (kDebugMode) print('🔌 Network error: $e');
      throw Exception("Cannot connect to $baseUrl. Check network and backend.");
    } catch (e) {
      if (kDebugMode) print('❌ Error: $e');
      rethrow;
    }
  }
}
