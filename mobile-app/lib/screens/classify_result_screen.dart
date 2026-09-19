import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../constants/app_enums.dart';
import '../services/local_ai_classifier.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import 'classify_bulk_screen.dart';

class ClassifyResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final AppLanguage language;
  final bool isDiagnostic;

  const ClassifyResultScreen({
    super.key,
    required this.result,
    required this.language,
    this.isDiagnostic = false,
  });

  @override
  State<ClassifyResultScreen> createState() => _ClassifyResultScreenState();
}

class _ClassifyResultScreenState extends State<ClassifyResultScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeaking = false;

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

  String _ttsLanguage() {
    switch (widget.language) {
      case AppLanguage.hindi:
        return 'hi-IN';
      case AppLanguage.marathi:
        return 'mr-IN';
      case AppLanguage.english:
      default:
        return 'en-IN';
    }
  }

  @override
  void initState() {
    super.initState();

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    _flutterTts.setCancelHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    _flutterTts.setErrorHandler((message) {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await _flutterTts.stop();

      if (mounted) {
        setState(() => _isSpeaking = false);
      }

      return;
    }

    final imagePath = widget.result['imagePath'] as String?;
    final rawCode =
        (widget.result['materialCode'] ??
                widget.result['material'] ??
                'CABLES_AND_WIRING')
            as String;

    final localizedName =
        LocalAiClassifier.getLocalizedMaterialName(rawCode, widget.language);

    final buffer = StringBuffer();

    if (widget.isDiagnostic) {
      buffer.write(
        _t(
          'AI Scan Result. ',
          'एआई पहचान परिणाम। ',
          'एआय स्कॅन निकाल। ',
        ),
      );
    } else {
      buffer.write(
        _t(
          'Scrap Lot Recorded. ',
          'कबाड़ लॉट दर्ज हुआ। ',
          'भंगार लॉट नोंदवला गेला। ',
        ),
      );
    }

    buffer.write(
      _t(
        'Identified Material: ',
        'पहचानी गई सामग्री: ',
        'ओळखलेले साहित्य: ',
      ),
    );
    buffer.write('$localizedName. ');

    if (widget.isDiagnostic) {
      buffer.write(
        _t(
          'AI Confidence: ',
          'एआई सटीकता: ',
          'एआय अचूकता: ',
        ),
      );
      buffer.write('${widget.result['confidence'] ?? '85%'}. ');

      buffer.write(
        _t(
          'Benchmark Rate: ',
          'बेंचमार्क दर: ',
          'बेंचमार्क दर: ',
        ),
      );
      buffer.write('${widget.result['price'] ?? '₹100/kg'}. ');
    } else {
      if (widget.result['lotUid'] != null) {
        final lotUid = widget.result['lotUid'] as String;

        buffer.write(
          _t(
            'Lot UID: ',
            'लॉट आईडी: ',
            'लॉट आयडी: ',
          ),
        );

        buffer.write(
          '${lotUid.substring(0, lotUid.length > 12 ? 12 : lotUid.length)}. ',
        );
      }

      buffer.write(
        _t(
          'Recorded Weight: ',
          'दर्ज वजन: ',
          'नोंदवलेले वजन: ',
        ),
      );
      buffer.write('${widget.result['weight'] ?? '0 kg'}. ');

      buffer.write(
        _t(
          'Estimated Payout: ',
          'अनुमानित भुगतान: ',
          'अंदाजे पेमेंट: ',
        ),
      );
      buffer.write('${widget.result['price'] ?? '₹0'}. ');

      buffer.write(
        _t(
          'Sync Status: Pending Sync, Offline. ',
          'सिंक स्थिति: लंबित, ऑफ़लाइन। ',
          'सिंक स्थिती: प्रलंबित, ऑफलाइन। ',
        ),
      );
    }

    try {
      await _flutterTts.setLanguage(_ttsLanguage());
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      if (mounted) {
        setState(() => _isSpeaking = true);
      }

      await _flutterTts.speak(buffer.toString());
    } catch (_) {
      if (mounted) {
        setState(() => _isSpeaking = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Unable to play audio.',
                'ऑडियो चलाया नहीं जा सका।',
                'ऑडिओ प्ले करता आले नाही.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    final imagePath = widget.result['imagePath'] as String?;
    final rawCode =
        (widget.result['materialCode'] ??
                widget.result['material'] ??
                'CABLES_AND_WIRING')
            as String;

    final localizedName =
        LocalAiClassifier.getLocalizedMaterialName(rawCode, widget.language);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isDiagnostic
              ? _t(
                  'AI Scan Result',
                  'एआई पहचान परिणाम',
                  'एआय स्कॅन निकाल',
                )
              : _t(
                  'Scrap Lot Recorded',
                  'कबाड़ लॉट दर्ज हुआ',
                  'भंगार लॉट नोंदवला गेला',
                ),
        ),

        // Audio button
        actions: [
          IconButton(
            tooltip: _isSpeaking
                ? _t('Stop Audio', 'ऑडियो रोकें', 'ऑडिओ थांबवा')
                : _t('Read Aloud', 'आवाज़ में सुनें', 'आवाजात ऐका'),
            icon: Icon(
              _isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up,
            ),
            onPressed: _toggleSpeech,
          ),
          const SizedBox(width: 4),
        ],
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
                border: Border.all(
                  color: activeAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: activeAccent.withValues(alpha: 0.15),
                        child: Icon(
                          LocalAiClassifier.getMaterialIcon(rawCode),
                          color: activeAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t(
                                'Identified Material',
                                'पहचानी गई सामग्री',
                                'ओळखलेले साहित्य',
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppThemeColors.muted(context),
                              ),
                            ),
                            Text(
                              localizedName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  if (widget.isDiagnostic) ...[
                    // Diagnostic Mode: Display Model Confidence & Market Rate
                    _infoRow(
                      context,
                      Icons.verified,
                      _t(
                        'AI Confidence',
                        'एआई सटीकता',
                        'एआय अचूकता',
                      ),
                      widget.result['confidence'] ?? '85%',
                      valueColor: AppColors.lightGreen,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      context,
                      Icons.currency_rupee,
                      _t(
                        'Benchmark Rate',
                        'बेंचमार्क दर',
                        'बेंचमार्क दर',
                      ),
                      widget.result['price'] ?? '₹100/kg',
                      valueColor: activeAccent,
                    ),
                  ] else ...[
                    // Lot Receipt Mode: Display Lot Details (Confidence Omitted)
                    if (widget.result['lotUid'] != null) ...[
                      _infoRow(
                        context,
                        Icons.qr_code,
                        _t(
                          'Lot UID',
                          'लॉट आईडी',
                          'लॉट आयडी',
                        ),
                        (widget.result['lotUid'] as String).substring(
                          0,
                          (widget.result['lotUid'] as String).length > 12
                              ? 12
                              : (widget.result['lotUid'] as String).length,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    _infoRow(
                      context,
                      Icons.scale,
                      _t(
                        'Recorded Weight',
                        'दर्ज वजन',
                        'नोंदवलेले वजन',
                      ),
                      widget.result['weight'] ?? '0 kg',
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      context,
                      Icons.payments,
                      _t(
                        'Estimated Payout',
                        'अनुमानित भुगतान',
                        'अंदाजे पेमेंट',
                      ),
                      widget.result['price'] ?? '₹0',
                      valueColor: activeAccent,
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      context,
                      Icons.cloud_upload_outlined,
                      _t(
                        'Sync Status',
                        'सिंक स्थिति',
                        'सिंक स्थिती',
                      ),
                      _t(
                        'Pending Sync (Offline)',
                        'लंबित (ऑफ़लाइन)',
                        'प्रलंबित (ऑफलाइन)',
                      ),
                      valueColor: AppColors.warning,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (widget.isDiagnostic) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    _t(
                      'Create Lot with this Item',
                      'इस वस्तु का लॉट बनाएं',
                      'या वस्तूचा लॉट तयार करा',
                    ),
                  ),
                  onPressed: () async {
                    await _flutterTts.stop();

                    if (!mounted) return;

                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassifyBulkScreen(
                          storage: null,
                          language: widget.language,
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
                  onPressed: () async {
                    await _flutterTts.stop();

                    if (!mounted) return;

                    Navigator.pop(context);
                  },
                  child: Text(
                    _t('Done', 'पूर्ण', 'झाले'),
                  ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    await _flutterTts.stop();

                    if (!mounted) return;

                    Navigator.pop(context);
                  },
                  child: Text(
                    _t(
                      'Back to Dashboard',
                      'डैशबोर्ड पर लौटें',
                      'डॅशबोर्डवर परत जा',
                    ),
                  ),
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
        Icon(
          icon,
          size: 18,
          color: AppThemeColors.muted(context),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppThemeColors.muted(context),
            fontSize: 13,
          ),
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
