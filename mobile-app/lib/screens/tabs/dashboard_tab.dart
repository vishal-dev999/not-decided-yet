import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../constants/app_enums.dart';
import '../../services/database_helper.dart';
import '../../services/local_ai_classifier.dart';
import '../../services/storage_service.dart';
import '../../services/sync_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';
import '../classify_bulk_screen.dart';
import 'recy_chatbot_sheet.dart';

class DashboardTab extends StatefulWidget {
  final AppLanguage language;
  final ReNovaStorage? storage;
  final ValueChanged<int> onNavigateTab;

  const DashboardTab({
    super.key,
    required this.language,
    this.storage,
    required this.onNavigateTab,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _totalLotsCount = 0;
  int _pendingSyncCount = 0;
  double _totalQueuedWeightKg = 0.0;
  double _totalQueuedValue = 0.0;
  List<Map<String, dynamic>> _topMovers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _triggerManualSync() async {
    if (widget.storage == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing lots with central backend...')),
    );

    final res = await SyncService.syncPendingLots(storage: widget.storage!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: res['success'] == true
            ? Colors.green
            : Colors.redAccent,
        content: Text(res['message'] as String),
      ),
    );

    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // 1. Fetch latest rates sorted by highest recycler offer
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery('''
        SELECT material_category, recycler_offered_price_per_kg 
        FROM price_history 
        ORDER BY recycler_offered_price_per_kg DESC 
        LIMIT 4
      ''');

      if (rows.isNotEmpty && mounted) {
        setState(() {
          _topMovers = List<Map<String, dynamic>>.from(rows);
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading top rates from DB: $e');
    }

    // 2. Fallback to LocalAiClassifier benchmarks if DB hasn't populated yet
    if (mounted) {
      final fallback =
          LocalAiClassifier.benchmarks.entries.map((e) {
            return {
              'material_category': e.key,
              'recycler_offered_price_per_kg': (e.value['rate_per_kg'] as num)
                  .toDouble(),
            };
          }).toList()..sort(
            (a, b) => (b['recycler_offered_price_per_kg'] as double).compareTo(
              a['recycler_offered_price_per_kg'] as double,
            ),
          );

      setState(() {
        _topMovers = fallback.take(4).toList();
      });
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

  void _openRecyChatbot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecyChatbotSheet(language: widget.language),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    final collectorName = widget.storage?.collectorName ?? 'Collector';
    final location = widget.storage?.location ?? 'Bhubaneswar';
    final profileImagePath = widget.storage?.profileImagePath;
    final hasValidImage =
        profileImagePath != null &&
        profileImagePath.isNotEmpty &&
        File(profileImagePath).existsSync();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collector Profile Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppThemeColors.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: activeAccent.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(
                            'Welcome back,',
                            'वापसी पर स्वागत है,',
                            'पुन्हा स्वागत आहे,',
                          ),
                          style: TextStyle(
                            color: AppThemeColors.muted(context),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          collectorName.isEmpty ? 'Collector' : collectorName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: activeAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.mintGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              location.isEmpty ? 'Bhubaneswar' : location,
                              style: const TextStyle(
                                color: AppColors.mintGreen,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: activeAccent,
                    backgroundImage: hasValidImage
                        ? FileImage(File(profileImagePath))
                        : null,
                    child: !hasValidImage
                        ? const Icon(
                            Icons.person,
                            size: 30,
                            color: AppColors.darkBackground,
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Record Lot CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [activeAccent.withValues(alpha: 0.85), activeAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(
                            'Record Scrap Lot',
                            'कबाड़ लॉट दर्ज करें',
                            'भंगार लॉट नोंदवा',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _t(
                            'Save offline weights & benchmark prices',
                            'ऑफ़लाइन वजन और मंडी भाव सुरक्षित करें',
                            'ऑफलाइन वजन आणि बाजार दर जतन करा',
                          ),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.darkBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(Icons.add_a_photo, size: 18),
                    label: Text(
                      _t('Create', 'बनाएं', 'तयार करा'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ClassifyBulkScreen(language: widget.language),
                        ),
                      );
                      _loadDashboardData();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Collection Pulse
            Text(
              _t('Collection Pulse', 'संग्रह स्थिति', 'संकलन स्थिती'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppThemeColors.text(context),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    context,
                    _t('Queued Lots', 'कुल लॉट', 'एकूण लॉट'),
                    '$_totalLotsCount',
                    Icons.inventory_2_outlined,
                    activeAccent,
                    subtext: '$_pendingSyncCount pending sync',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    context,
                    _t('Total Weight', 'कुल वजन', 'एकूण वजन'),
                    '${_totalQueuedWeightKg.toStringAsFixed(1)} kg',
                    Icons.scale,
                    AppColors.mintGreen,
                    subtext: 'Stored offline',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    context,
                    _t('Est. Payout Value', 'अनुमानित मूल्य', 'अंदाजे मूल्य'),
                    '₹${_totalQueuedValue.toStringAsFixed(0)}',
                    Icons.currency_rupee,
                    AppColors.lightGreen,
                    subtext: 'Mandi benchmarks',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pendingSyncCount > 0 ? _triggerManualSync : null,
                    borderRadius: BorderRadius.circular(16),
                    child: _metricCard(
                      context,
                      _t('Sync Status', 'सिंक स्थिति', 'सिंक स्थिती'),
                      _pendingSyncCount == 0
                          ? 'Up to date'
                          : 'Tap to Sync ($_pendingSyncCount)',
                      _pendingSyncCount == 0
                          ? Icons.cloud_done
                          : Icons.cloud_upload,
                      _pendingSyncCount == 0
                          ? AppColors.lightGreen
                          : AppColors.warning,
                      subtext: _pendingSyncCount == 0
                          ? 'All lots backed up'
                          : 'Tap to upload to server',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Shortcuts Grid
            Text(
              _t('Quick Shortcuts', 'त्वरित शॉर्टकट', 'द्रुत शॉर्टकट'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppThemeColors.text(context),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shortcutButton(
                  context,
                  Icons.auto_awesome,
                  _t('Scan', 'स्कैन', 'स्कॅन'),
                  () => widget.onNavigateTab(4),
                ),
                _shortcutButton(
                  context,
                  Icons.inventory_2_outlined,
                  _t('My Lots', 'मेरे लॉट', 'माझे लॉट'),
                  () => widget.onNavigateTab(1),
                ),
                _shortcutButton(
                  context,
                  Icons.trending_up,
                  _t('Rates', 'भाव', 'दर'),
                  () => widget.onNavigateTab(2),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shortcutButton(
                  context,
                  Icons.smart_toy,
                  'Recy AI',
                  () => _openRecyChatbot(context),
                ),
                _shortcutButton(
                  context,
                  Icons.near_me_outlined,
                  _t('Recyclers', 'रीसाइक्लर', 'रिसायकलर'),
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Finding nearest authorized drop-points...',
                      ),
                    ),
                  ),
                ),
                _shortcutButton(
                  context,
                  Icons.account_balance_wallet,
                  _t('Payment', 'भुगतान', 'पेमेंट'),
                  () => widget.onNavigateTab(3),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Top Rates Snapshot
            if (_topMovers.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _t(
                      'Top Market Rates',
                      'शीर्ष बाजार दरें',
                      'प्रमुख बाजार दर',
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppThemeColors.text(context),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onNavigateTab(2),
                    child: Text(
                      _t('View All →', 'सभी देखें →', 'सर्व पहा →'),
                      style: TextStyle(
                        color: activeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              ..._topMovers.map((item) {
                final code = item['material_category'] as String;
                final localizedName =
                    LocalAiClassifier.getLocalizedMaterialName(
                      code,
                      widget.language,
                    );
                final price = (item['recycler_offered_price_per_kg'] as num)
                    .toDouble();

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppThemeColors.card(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LocalAiClassifier.getMaterialIcon(code),
                        size: 20,
                        color: activeAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          localizedName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '₹${price.toStringAsFixed(0)}/kg',
                        style: TextStyle(
                          color: activeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppThemeColors.muted(context),
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 4),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 10,
                color: AppThemeColors.faint(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _shortcutButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppThemeColors.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: activeAccent.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: activeAccent, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
