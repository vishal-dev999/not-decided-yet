import 'dart:io';
import 'package:flutter/material.dart';

import '../constants/app_enums.dart';
import '../services/local_ai_classifier.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import 'classify_bulk_screen.dart';

class ClassifyResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  final AppLanguage language;
  final bool isDiagnostic;

  const ClassifyResultScreen({
    super.key,
    required this.result,
    required this.language,
    this.isDiagnostic = false,
  });

  String _t(String en, String hi, String mr) {
    switch (language) {
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

    final imagePath = result['imagePath'] as String?;
    final rawCode = (result['materialCode'] ?? result['material'] ?? 'CABLES_AND_WIRING') as String;
    final localizedName = LocalAiClassifier.getLocalizedMaterialName(rawCode, language);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDiagnostic
              ? _t('AI Scan Result', 'एआई पहचान परिणाम', 'एआय स्कॅन निकाल')
              : _t('Scrap Lot Recorded', 'कबाड़ लॉट दर्ज हुआ', 'भंगार लॉट नोंदवला गेला'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image Preview
            if (imagePath != null && File(imagePath).existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(imagePath),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),

            // Card Container
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppThemeColors.card(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: activeAccent.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: activeAccent.withValues(alpha: 0.15),
                        child: Icon(LocalAiClassifier.getMaterialIcon(rawCode), color: activeAccent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('Identified Material', 'पहचानी गई सामग्री', 'ओळखलेले साहित्य'),
                              style: TextStyle(fontSize: 12, color: AppThemeColors.muted(context)),
                            ),
                            Text(
                              localizedName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  if (isDiagnostic) ...[
                    // Diagnostic Mode: Display Model Confidence & Market Rate
                    _infoRow(
                      context,
                      Icons.verified,
                      _t('AI Confidence', 'एआई सटीकता', 'एआय अचूकता'),
                      result['confidence'] ?? '85%',
                      valueColor: AppColors.lightGreen,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      context,
                      Icons.currency_rupee,
                      _t('Benchmark Rate', 'बेंचमार्क दर', 'बेंचमार्क दर'),
                      result['price'] ?? '₹100/kg',
                      valueColor: activeAccent,
                    ),
                  ] else ...[
                    // Lot Receipt Mode: Display Lot Details (Confidence Omitted)
                    if (result['lotUid'] != null) ...[
                      _infoRow(
                        context,
                        Icons.qr_code,
                        _t('Lot UID', 'लॉट आईडी', 'लॉट आयडी'),
                        (result['lotUid'] as String).substring(0, 12),
                      ),
                      const SizedBox(height: 10),
                    ],
                    _infoRow(
                      context,
                      Icons.scale,
                      _t('Recorded Weight', 'दर्ज वजन', 'नोंदवलेले वजन'),
                      result['weight'] ?? '0 kg',
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      context,
                      Icons.payments,
                      _t('Estimated Payout', 'अनुमानित भुगतान', 'अंदाजे पेमेंट'),
                      result['price'] ?? '₹0',
                      valueColor: activeAccent,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      context,
                      Icons.cloud_upload_outlined,
                      _t('Sync Status', 'सिंक स्थिति', 'सिंक स्थिती'),
                      _t('Pending Sync (Offline)', 'लंबित (ऑफ़लाइन)', 'प्रलंबित (ऑफलाइन)'),
                      valueColor: AppColors.warning,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (isDiagnostic) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(_t('Create Lot with this Item', 'इस वस्तु का लॉट बनाएं', 'या वस्तूचा लॉट तयार करा')),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassifyBulkScreen(
                          storage: null, // Initialized via DatabaseHelper
                          language: language,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_t('Done', 'पूर्ण', 'झाले')),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(_t('Back to Dashboard', 'डैशबोर्ड पर लौटें', 'डॅशबोर्डवर परत जा')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppThemeColors.muted(context)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: AppThemeColors.muted(context), fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor ?? AppThemeColors.text(context),
          ),
        ),
      ],
    );
  }
}
