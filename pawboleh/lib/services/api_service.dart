import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Networking service connecting Flutter frontend to Express backend.
class ApiService {
  /// Base URL auto-resolution for Web, Desktop, and Android Emulator.
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3001';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3001';
    return 'http://localhost:3001';
  }

  /// Sends customer question & dynamic product context to Express Paw Live endpoint.
  static Future<Map<String, dynamic>> sendPawLiveChat({
    required Map<String, dynamic> productContext,
    required String customerQuestion,
    String? sessionId,
  }) async {
    final url = Uri.parse('$baseUrl/api/paw-live/chat');
    final payload = {
      'productContext': productContext,
      'customerQuestion': customerQuestion,
      'sessionId': sessionId ?? 'default-session',
    };

    debugPrint('ApiService.sendPawLiveChat [POST] -> $url');
    debugPrint('Payload: ${jsonEncode(payload)}');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Connection timeout connecting to Express server at $url'),
    );

    debugPrint('ApiService.sendPawLiveChat HTTP ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorJson = jsonDecode(response.body);
      final errorMsg = errorJson['details'] ?? errorJson['error'] ?? response.body;
      throw Exception('Server error (${response.statusCode}): $errorMsg');
    }
  }

  /// Sends product context & selected demographic to Express Paw Snap endpoint.
  static Future<Map<String, dynamic>> generatePawSnapContent({
    required String imageContext,
    required String demographic,
  }) async {
    final url = Uri.parse('$baseUrl/api/paw-snap/generate');
    final payload = {
      'imageContext': imageContext,
      'demographic': demographic,
    };

    debugPrint('ApiService.generatePawSnapContent [POST] -> $url');
    debugPrint('Payload: ${jsonEncode(payload)}');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Connection timeout connecting to Express server at $url'),
    );

    debugPrint('ApiService.generatePawSnapContent HTTP ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorJson = jsonDecode(response.body);
      final errorMsg = errorJson['details'] ?? errorJson['error'] ?? response.body;
      throw Exception('Server error (${response.statusCode}): $errorMsg');
    }
  }
}
