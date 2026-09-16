import 'dart:convert';
import 'package:flutter/services.dart';

class PricingService {
  static Map<String, dynamic>? _benchmarks;

  // Load JSON once on app startup or first call
  static Future<void> init() async {
    if (_benchmarks != null && _benchmarks!.isNotEmpty) return;
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/price_benchmarks.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      _benchmarks = data['benchmarks'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      _benchmarks = {};
    }
  }

  // Get benchmark record for a class (handles direct match or normalized key)
  static Map<String, dynamic>? getBenchmark(String subCategory) {
    if (_benchmarks == null) return null;
    if (_benchmarks!.containsKey(subCategory)) {
      return _benchmarks![subCategory] as Map<String, dynamic>?;
    }
    // Fallback: match ignoring case or leading/trailing whitespace
    final cleanKey = subCategory.trim().toUpperCase();
    for (final entry in _benchmarks!.entries) {
      if (entry.key.toUpperCase() == cleanKey) {
        return entry.value as Map<String, dynamic>?;
      }
    }
    return null;
  }

  // Calculate instant offline value: weight * recycler price
  static double estimateValue(String subCategory, double weightKg) {
    final item = getBenchmark(subCategory);
    if (item == null) return 0.0;

    // Checks 'recycler_price' first, falls back to 'recycler_offered_price'
    final num? rawRate = item['recycler_price'] as num? ??
        item['recycler_offered_price'] as num?;

    final rate = rawRate?.toDouble() ?? 0.0;
    return rate * weightKg;
  }
}
