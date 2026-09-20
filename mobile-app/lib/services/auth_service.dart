import 'dart:convert';

import 'package:http/http.dart' as http;

import 'storage_service.dart';

class AuthService {
  // Hardcoded permanent Ngrok domain for your hackathon demo
  static const String defaultBaseUrl =
      'https://consonant-unequal-happening.ngrok-free.dev';

  // 🛡️ Backward compatibility getter for files using AuthService.baseUrl
  static String get baseUrl => defaultBaseUrl;

  /// Dynamically resolves baseUrl from local storage if configured, otherwise falls back to default
  static String getBaseUrl([ReNovaStorage? storage]) {
    if (storage != null &&
        storage.customBaseUrl != null &&
        storage.customBaseUrl!.isNotEmpty) {
      return storage.customBaseUrl!;
    }
    return defaultBaseUrl;
  }

  static Future<Map<String, dynamic>> registerCollector({
    required String phone,
    required String pin,
    required String fullName,
    required String language,
    String city = 'Bhubaneswar',
    String? upiId,
    required ReNovaStorage storage,
  }) async {
    final currentBaseUrl = getBaseUrl(storage);
    final url = Uri.parse('$currentBaseUrl/api/v1/auth/collector/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'pin': pin,
          'full_name': fullName,
          'language': language,
          'city': city,
          'state': 'Odisha',
          'pincode': '751001',
          'upi_id': upiId ?? '$phone@upi',
        }),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 && data['ok'] == true) {
        final tokens = data['tokens'] as Map<String, dynamic>;
        final collector = data['collector'] as Map<String, dynamic>;

        await storage.saveAuthSession(
          accessToken: tokens['access_token'] ?? '',
          refreshToken: tokens['refresh_token'] ?? '',
          collectorId: collector['id'] ?? '',
          name: collector['full_name'] ?? fullName,
          phone: collector['phone'] ?? phone,
          city: collector['city'] ?? city,
        );

        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot reach server at $currentBaseUrl: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> loginCollector({
    required String phone,
    required String pin,
    required ReNovaStorage storage,
  }) async {
    final currentBaseUrl = getBaseUrl(storage);
    final url = Uri.parse('$currentBaseUrl/api/v1/auth/collector/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'pin': pin}),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['ok'] == true) {
        final tokens = data['tokens'] as Map<String, dynamic>;
        final collector = data['collector'] as Map<String, dynamic>;

        await storage.saveAuthSession(
          accessToken: tokens['access_token'] ?? '',
          refreshToken: tokens['refresh_token'] ?? '',
          collectorId: collector['id'] ?? '',
          name: collector['full_name'] ?? 'Collector',
          phone: collector['phone'] ?? phone,
          city: collector['city'],
        );

        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Authentication failed',
          'spoken': data['message_spoken']?['hi'] ?? data['message'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot reach server at $currentBaseUrl: $e',
      };
    }
  }
}
