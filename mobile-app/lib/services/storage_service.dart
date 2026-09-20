import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../themes/app_theme.dart';

class ReNovaStorage {
  final SharedPreferences prefs;
  final Directory documentsDirectory;

  ReNovaStorage._(this.prefs, this.documentsDirectory);

  static Future<ReNovaStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    final directory = await getApplicationDocumentsDirectory();

    return ReNovaStorage._(prefs, directory);
  }

  // --- Profile & Preferences Getters ---
  String? get collectorName => prefs.getString('collector_name');
  String? get location => prefs.getString('collector_location');
  String? get age => prefs.getString('collector_age');
  String? get otherDetails => prefs.getString('collector_other_details');
  String? get language => prefs.getString('language');
  String? get theme => prefs.getString('theme');
  String? get profileImagePath => prefs.getString('profile_image_path');
  String? get pickupImagePath => prefs.getString('pickup_image_path');
  String? get paymentPreference => prefs.getString('payment_preference');
  String? get userType => prefs.getString('user_type');
  String? get savedUpiId => prefs.getString('saved_upi_id');
  
  // 🌐 Custom Backend URL (Ngrok / Hotspot / Localhost support)
  String? get customBaseUrl => prefs.getString('custom_base_url');

  String get collectorId =>
      prefs.getString('collector_id') ?? 'RN-COL-2026-01428';

  // --- Auth Session Getters & Setters ---
  String? get accessToken => prefs.getString('auth_access_token');
  String? get refreshToken => prefs.getString('auth_refresh_token');
  bool get isLoggedIn => accessToken != null && accessToken!.trim().isNotEmpty;

  Future<void> saveAuthSession({
    required String accessToken,
    required String refreshToken,
    required String collectorId,
    required String name,
    required String phone,
    String? city,
  }) async {
    await prefs.setString('auth_access_token', accessToken);
    await prefs.setString('auth_refresh_token', refreshToken);
    await prefs.setString('collector_id', collectorId);
    await prefs.setString('collector_name', name);
    await prefs.setString('collector_phone', phone);
    if (city != null) {
      await prefs.setString('collector_location', city);
    }
  }

  Future<void> clearAuthSession() async {
    await prefs.remove('auth_access_token');
    await prefs.remove('auth_refresh_token');
  }

  // --- Profile & Theme Management ---
  Future<void> saveProfile({
    required String name,
    required String location,
    String? age,
    String? otherDetails,
    required String language,
    required String paymentPreference,
    String? profileImagePath,
    String? userType,
  }) async {
    await prefs.setString('collector_name', name);
    await prefs.setString('collector_location', location);
    if (age != null) await prefs.setString('collector_age', age);
    if (otherDetails != null) {
      await prefs.setString('collector_other_details', otherDetails);
    }
    await prefs.setString('language', language);
    await prefs.setString('payment_preference', paymentPreference);
    if (userType != null) {
      await prefs.setString('user_type', userType);
    }

    if (profileImagePath != null) {
      await prefs.setString('profile_image_path', profileImagePath);
    }
  }

  Future<void> saveUpiId(String upiId) async {
    await prefs.setString('saved_upi_id', upiId);
  }

  Future<void> setCustomBaseUrl(String url) async {
    await prefs.setString('custom_base_url', url);
  }

  Future<void> saveTheme(ReNovaThemeMode mode) async {
    await prefs.setString(
      'theme',
      mode == ReNovaThemeMode.dark ? 'dark' : 'light',
    );
  }

  // --- Image Handling ---
  Future<String> saveImagePermanently(XFile image, String filename) async {
    final target = File('${documentsDirectory.path}/$filename');
    await File(image.path).copy(target.path);
    return target.path;
  }

  Future<void> savePickupImage(XFile image) async {
    final path = await saveImagePermanently(image, 'renova_pickup.jpg');
    await prefs.setString('pickup_image_path', path);
  }

  Future<void> saveProfileImage(XFile image) async {
    final path = await saveImagePermanently(image, 'renova_profile.jpg');
    await prefs.setString('profile_image_path', path);
  }

  Future<void> removePickupImage() async {
    final path = pickupImagePath;
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await prefs.remove('pickup_image_path');
  }

  // --- Local Cache History ---
  List<Map<String, dynamic>> get classificationHistory {
    final raw = prefs.getStringList('classification_history') ?? [];
    return raw
        .map((item) {
          try {
            return Map<String, dynamic>.from(jsonDecode(item) as Map);
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> saveClassification(Map<String, dynamic> item) async {
    final items = prefs.getStringList('classification_history') ?? [];
    items.insert(0, jsonEncode(item));
    if (items.length > 100) {
      items.removeRange(100, items.length);
    }
    await prefs.setStringList('classification_history', items);
  }

  List<Map<String, dynamic>> get paymentHistory {
    final raw = prefs.getStringList('payment_history') ?? [];
    return raw
        .map((item) {
          try {
            return Map<String, dynamic>.from(jsonDecode(item) as Map);
          } catch (_) {
            return <String, dynamic>{};
          }
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> savePayment(Map<String, dynamic> item) async {
    final items = prefs.getStringList('payment_history') ?? [];
    items.insert(0, jsonEncode(item));
    if (items.length > 100) {
      items.removeRange(100, items.length);
    }
    await prefs.setStringList('payment_history', items);
  }
}

ReNovaStorage getStorage(BuildContext context) {
  final state = context.findAncestorStateOfType<ReNovaAppState>();
  if (state == null) {
    throw Exception('ReNova storage is unavailable.');
  }
  return state.widget.storage;
}
