import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../constants/app_enums.dart';
import '../../services/auth_service.dart';
import '../../services/database_helper.dart';
import '../../services/local_ai_classifier.dart';
import '../../services/storage_service.dart'; // Make sure storage service is imported
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';

class MarketRatesTab extends StatefulWidget {
  final AppLanguage language;
  final ReNovaStorage storage; // 🆕 Added storage parameter to grab dynamic base URL & city

  const MarketRatesTab({
    super.key,
    required this.language,
    required this.storage,
  });

  @override
  State<MarketRatesTab> createState() => _MarketRatesTabState();
}

class _MarketRatesTabState extends State<MarketRatesTab> {
  List<Map<String, dynamic>> _rates = [];
  bool _isLoading = true;
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _syncAndFetchRates();
  }

  Future<void> _syncAndFetchRates() async {
    setState(() => _isLoading = true);
    bool liveSuccess = false;

    // 🚀 Use dynamic city from storage (fallback to Bhubaneswar if not set)
    final city = widget.storage.location ?? 'Bhubaneswar';
    final baseUrl = AuthService.getBaseUrl(widget.storage);

    try {
      final url = Uri.parse(
        '$baseUrl/api/v1/prices/board?city=$city',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final quotes = decoded['data'] as List<dynamic>? ?? [];
          if (quotes.isNotEmpty) {
            await DatabaseHelper.instance.saveBackendQuotes(
              quotes,
              city,
            );
            liveSuccess = true;
          }
        }
      }
    } catch (e) {
      debugPrint('Sync rates error: $e');
    }

    try {
      // Read local SQLite cache
      var data = await DatabaseHelper.instance.getLatestPrices();

      if (data.isEmpty) {
        await DatabaseHelper.instance.clearAndReseedPrices();
        data = await DatabaseHelper.instance.getLatestPrices();
      }

      if (mounted) {
        setState(() {
          _rates = data;
          _isLive = liveSuccess;
        });
      }
    } catch (e) {
      debugPrint('Database fetch error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _t(String en, String hi, String mr) {
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

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    final currentCity = widget.storage.location ?? 'Bhubaneswar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t(
            'Market Benchmarks',
            'मंडी व रीसाइक्लर भाव',
            'बाजार व रिसायकलर दर',
          ),
        ),
        actions: [
          IconButton(
            tooltip: _t(
              'Reset Benchmarks',
              'बेंचमार्क रीसेट करें',
              'बेंचमार्क रीसेट करा',
            ),
            icon: const Icon(Icons.download_for_offline),
            onPressed: () async {
              await DatabaseHelper.instance.clearAndReseedPrices();
              _syncAndFetchRates();
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _syncAndFetchRates,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status banner showing whether rates came from backend or local cache
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isLive
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isLive
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isLive ? Icons.wifi : Icons.wifi_off,
                        size: 16,
                        color: _isLive ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLive
                            ? _t(
                                'Live Mandi Rates • $currentCity',
                                'लाइव मंडी दर • $currentCity',
                                'थेट बाजार दर • $currentCity',
                              )
                            : _t(
                                'Offline Cached Rates • SQLite Active',
                                'ऑफ़लाइन संग्रहीत दरें • सक्रिय',
                                'ऑफलाइन सेव्ह केलेले दर',
                              ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _isLive ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rates.length,
                    itemBuilder: (context, index) {
                      final item = _rates[index];
                      final code = item['material_category'] as String;
                      final mandiPrice = (item['mandi_price_per_kg'] as num)
                          .toDouble();
                      final recyclerPrice =
                          (item['recycler_offered_price_per_kg'] as num)
                              .toDouble();
                      final minPrice = (item['min_market_price'] as num)
                          .toDouble();
                      final maxPrice = (item['max_market_price'] as num)
                          .toDouble();

                      final bonus = recyclerPrice - mandiPrice;
                      final localizedName =
                          LocalAiClassifier.getLocalizedMaterialName(
                            code,
                            widget.language,
                          );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppThemeColors.card(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: activeAccent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: activeAccent.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Icon(
                                    LocalAiClassifier.getMaterialIcon(code),
                                    color: activeAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localizedName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        code,
                                        style: TextStyle(
                                          color: AppThemeColors.muted(context),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (bonus > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGreen.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '+₹${bonus.toStringAsFixed(0)} ${_t("bonus", "अतिरिक्त", "अतिरिक्त")}',
                                      style: const TextStyle(
                                        color: AppColors.lightGreen,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _t(
                                        'Local Mandi Rate',
                                        'स्थानीय मंडी भाव',
                                        'स्थानिक मंडी दर',
                                      ),
                                      style: TextStyle(
                                        color: AppThemeColors.muted(context),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${mandiPrice.toStringAsFixed(0)}/kg',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _t(
                                        'Recycler Direct Offer',
                                        'रीसाइक्लर डायरेक्ट भाव',
                                        'रिसायकलर थेट ऑफर',
                                      ),
                                      style: TextStyle(
                                        color: AppThemeColors.muted(context),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${recyclerPrice.toStringAsFixed(0)}/kg',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: activeAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Divider(
                              height: 1,
                              color: AppThemeColors.muted(context)
                                  .withValues(alpha: 0.15),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_t("Market Range:", "बाजार दायरा:", "बाजार श्रेणी:")} ₹${minPrice.toStringAsFixed(0)} – ₹${maxPrice.toStringAsFixed(0)}/kg',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppThemeColors.muted(context),
                                  ),
                                ),
                                Text(
                                  item['location'] ?? currentCity,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppThemeColors.muted(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
