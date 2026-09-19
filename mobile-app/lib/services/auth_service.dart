import 'dart:convert';

import 'package:http/http.dart' as http;

import 'storage_service.dart';

class AuthService {
  // Use http://10.0.2.2:8000 for Android emulator, or http://localhost:8000 for desktop/web/Linux
  static const String baseUrl = 'http://localhost:8000';

  static Future<Map<String, dynamic>> registerCollector({
    required String phone,
    required String pin,
    required String fullName,
    required String language,
    String city = 'Bhubaneswar',
    String? upiId,
    required ReNovaStorage storage,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/collector/register');

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
        'message': 'Cannot reach server at $baseUrl: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> loginCollector({
    required String phone,
    required String pin,
    required ReNovaStorage storage,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/collector/login');

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
        'message': 'Cannot reach server at $baseUrl: $e',
      };
    }
  }
}
