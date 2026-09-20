import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_enums.dart';
import '../../services/local_ai_classifier.dart';
import '../../services/storage_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';
import '../classify_result_screen.dart';

class PickupUploadTab extends StatefulWidget {
  final ReNovaStorage? storage;
  final AppLanguage language;
  final String? savedPhotoPath;
  final ValueChanged<String>? onPhotoUploaded;
  final bool isPickerMode; // True when called from "Create Lot"

  const PickupUploadTab({
    super.key,
    this.storage,
    required this.language,
    this.savedPhotoPath,
    this.onPhotoUploaded,
    this.isPickerMode = false,
  });

  @override
  State<PickupUploadTab> createState() => _PickupUploadTabState();
}

class _PickupUploadTabState extends State<PickupUploadTab> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.savedPhotoPath;
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _imagePath = picked.path;
        });
        widget.onPhotoUploaded?.call(picked.path);
        await _classifyScrap(picked.path);
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _classifyScrap(String path) async {
    setState(() => _isAnalyzing = true);

    try {
      final result = await LocalAiClassifier.classify(path, bulk: false);

      if (!mounted) return;
      setState(() => _isAnalyzing = false);

      // In picker mode, return the FULL result map back to the lot creator
      if (widget.isPickerMode) {
        Navigator.pop(context, result); // ✅ Returns the complete result map!
        return;
      }

      // Standalone exploratory mode: purely shows result preview
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClassifyResultScreen(
            result: result,
            language: widget.language,
            isDiagnostic: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Guidance banner if opened to assist bulk lot identification
          if (widget.isPickerMode)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: activeAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: activeAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.center_focus_strong,
                    color: activeAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _t(
                        'Take a close-up photo of a single item from the lot for best AI accuracy.',
                        'सटीक AI पहचान के लिए लॉट से किसी एक वस्तु की पास से फोटो लें।',
                        'अचूक AI ओळखीसाठी लॉटमधील कोणत्याही एका वस्तूचा जवळून फोटो घ्या.',
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppThemeColors.text(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Text(
            _t(
              'AI Single Item Scanner',
              'एआई एकल वस्तु स्कैनर',
              'एआय एकल वस्तू स्कॅनर',
            ),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppThemeColors.text(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'Capture or upload an individual scrap item to identify its category.',
              'श्रेणी की पहचान करने के लिए एक वस्तु का फोटो लें या अपलोड करें।',
              'श्रेणी ओळखण्यासाठी एका वस्तूचा फोटो घ्या किंवा अपलोड करा.',
            ),
            style: TextStyle(
              fontSize: 13,
              color: AppThemeColors.muted(context),
            ),
          ),
          const SizedBox(height: 20),

          // Upload / Camera Card
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppThemeColors.card(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: activeAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: _isAnalyzing
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: activeAccent),
                        const SizedBox(height: 16),
                        Text(
                          _t(
                            'Analyzing with on-device model...',
                            'डिवाइस पर मॉडल द्वारा विश्लेषण जारी...',
                            'डिव्हाइसवरील मॉडेलद्वारे विश्लेषण सुरू आहे...',
                          ),
                          style: TextStyle(
                            color: AppThemeColors.muted(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : _imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Image.file(
                      File(_imagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.document_scanner,
                        size: 56,
                        color: activeAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _t(
                          'No item photo selected',
                          'कोई फोटो चयनित नहीं',
                          'कोणताही फोटो निवडलेला नाही',
                        ),
                        style: TextStyle(
                          color: AppThemeColors.muted(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isAnalyzing
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    _t('Take Photo', 'फोटो खींचें', 'फोटो काढा'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isAnalyzing
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text(
                    _t('Gallery', 'गैलरी', 'गॅलरी'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
