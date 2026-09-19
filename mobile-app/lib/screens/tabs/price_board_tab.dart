import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../constants/app_enums.dart';
import '../../services/local_ai_classifier.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';

class PriceBoardTab extends StatefulWidget {
  final AppLanguage language;

  const PriceBoardTab({super.key, this.language = AppLanguage.english});

  @override
  State<PriceBoardTab> createState() => _PriceBoardTabState();
}

class _PriceBoardTabState extends State<PriceBoardTab> {
  final FlutterTts tts = FlutterTts();

  String selectedLocation = 'Bhubaneswar';

  final locations = ['Bhubaneswar', 'Cuttack', 'Mumbai', 'Delhi', 'Pune'];

  String get headerTitle {
    switch (widget.language) {
      case AppLanguage.hindi:
        return 'वर्तमान खरीद दरें';
      case AppLanguage.marathi:
        return 'सध्याचे खरेदीचे दर';
      case AppLanguage.english:
      default:
        return 'Current Buying Rates';
    }
  }

  String get headerSubtitle {
    switch (widget.language) {
      case AppLanguage.hindi:
        return 'सांकेतिक स्थानीय दरें • लेनदेन से पहले सत्यापित करें';
      case AppLanguage.marathi:
        return 'स्थानिक दर • व्यवहारापूर्वी पडताळणी करा';
      case AppLanguage.english:
      default:
        return 'Indicative local rates • verify before transaction';
    }
  }

  String _t2(String en, String hi, String mr) {
    switch (widget.language) {
      case AppLanguage.hindi:
        return hi;
      case AppLanguage.marathi:
        return mr;
      case AppLanguage.english:
      default:
        return en;
    }
  }

  String get _weekRangeLabel {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${monday.day} ${months[monday.month - 1]} - ${sunday.day} ${months[sunday.month - 1]}, ${sunday.year}';
  }

  final Map<String, double> _locationMultipliers = const {
    'Bhubaneswar': 1.0,
    'Cuttack': 0.95,
    'Mumbai': 1.15,
    'Delhi': 1.10,
    'Pune': 1.05,
  };

  /// Dynamically generated from price_benchmark.json for all 9 categories
  List<Map<String, dynamic>> get _allBenchmarkItems {
    final allBenchmarks = LocalAiClassifier.getAllBenchmarks();
    if (allBenchmarks.isEmpty) return [];

    final multiplier = _locationMultipliers[selectedLocation] ?? 1.0;

    return allBenchmarks.entries.map((entry) {
      final code = entry.key;
      final data = entry.value as Map<String, dynamic>;
      final baseRate = (data['rate_per_kg'] as num? ?? 100).toInt();
      final adjustedRate = (baseRate * multiplier).round();

      return {
        'code': code,
        'material': LocalAiClassifier.getLocalizedMaterialName(code, widget.language),
        'base': baseRate,
        'rateNum': adjustedRate,
        'rate': '₹$adjustedRate/${_t2('kg', 'किग्रा', 'किग्रॅ')}',
        'unit': _t2('kg', 'किग्रा', 'किग्रॅ'),
        'trend': data['trend'] as String? ?? '+0.0%',
        'up': data['up'] as bool? ?? true,
        'icon': LocalAiClassifier.getMaterialIcon(code),
      };
    }).toList();
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) return;
    switch (widget.language) {
      case AppLanguage.hindi:
        await tts.setLanguage('hi-IN');
        break;
      case AppLanguage.marathi:
        await tts.setLanguage('mr-IN');
        break;
      case AppLanguage.english:
      default:
        await tts.setLanguage('en-IN');
        break;
    }
    await tts.setSpeechRate(0.42);
    await tts.speak(text);
  }

  Widget _weeklyPriceBoard(BuildContext context, Color accent) {
    final items = _allBenchmarkItems;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t2(
                    'This Week\'s Price Board',
                    'इस सप्ताह का मूल्य बोर्ड',
                    'या आठवड्याचा किंमत बोर्ड',
                  ),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppThemeColors.text(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _weekRangeLabel,
            style: TextStyle(color: AppThemeColors.muted(context), fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppThemeColors.background(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLocation,
                isExpanded: true,
                dropdownColor: AppThemeColors.card(context),
                icon: Icon(Icons.location_on, color: accent),
                items: locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedLocation = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    _t2('Material', 'सामग्री', 'साहित्य'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.muted(context),
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _t2('Location', 'स्थान', 'स्थान'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.muted(context),
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _t2(
                      'Standardized Market Price',
                      'मानकीकृत बाजार मूल्य',
                      'मानकीकृत बाजार किंमत',
                    ),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.muted(context),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (final item in items)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppThemeColors.background(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(item['icon'] as IconData, color: accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      item['material'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppThemeColors.text(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      selectedLocation,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppThemeColors.muted(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${item['rateNum']}/${item['unit']}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    final items = _allBenchmarkItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headerTitle,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headerSubtitle,
            style: TextStyle(color: AppThemeColors.muted(context)),
          ),
          const SizedBox(height: 20),
          _weeklyPriceBoard(context, activeAccent),
          const SizedBox(height: 24),
          Text(
            _t2(
              'Select a location for details',
              'विवरण के लिए स्थान चुनें',
              'तपशीलासाठी स्थान निवडा',
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppThemeColors.card(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLocation,
                isExpanded: true,
                dropdownColor: AppThemeColors.card(context),
                icon: Icon(Icons.location_on, color: activeAccent),
                items: locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedLocation = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 15),
          ...items.map((price) => _priceCard(context, price)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: activeAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: activeAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prices shown are sample prototype data. In the production version they can be synchronized with recycler and market feeds.',
                    style: TextStyle(
                      color: AppThemeColors.text(context),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceCard(BuildContext context, Map<String, dynamic> price) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: activeAccent.withValues(alpha: 0.15),
            child: Icon(price['icon'] as IconData, color: activeAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price['material'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  price['rate'] as String,
                  style: TextStyle(
                    color: activeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Icon(
                price['up'] as bool ? Icons.trending_up : Icons.trending_down,
                color: price['up'] as bool
                    ? AppColors.lightGreen
                    : AppColors.danger,
              ),
              Text(
                price['trend'] as String,
                style: TextStyle(
                  color: price['up'] as bool
                      ? AppColors.lightGreen
                      : AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Speak price',
            onPressed: () {
              _speak(
                '${price['material']} in $selectedLocation is ${price['rate']}. Trend ${price['trend']}',
              );
            },
            icon: const Icon(Icons.volume_up, color: AppColors.mintGreen),
          ),
        ],
      ),
    );
  }
}
