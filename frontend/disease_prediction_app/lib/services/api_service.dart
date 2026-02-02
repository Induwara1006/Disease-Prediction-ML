import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Use emulator loopback for Android emulators; localhost for web/desktop.
  static String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1:5000";
    if (Platform.isAndroid) return "http://10.0.2.2:5000";
    return "http://127.0.0.1:5000";
  }

  static Future<Map<String, dynamic>> predictDisease(
      List<String> symptoms) async {
    final url = Uri.parse("$baseUrl/predict");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"symptoms": symptoms}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Prediction failed");
    }
  }
}
