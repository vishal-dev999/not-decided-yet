import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_enums.dart';
import '../services/database_helper.dart';
import '../services/local_ai_classifier.dart';
import '../services/storage_service.dart';
import '../services/sync_worker.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import 'classify_result_screen.dart';
import 'tabs/pickup_upload_tab.dart';

class ClassifyBulkScreen extends StatefulWidget {
  final ReNovaStorage? storage;
  final AppLanguage language;

  const ClassifyBulkScreen({super.key, this.storage, required this.language});

  @override
  State<ClassifyBulkScreen> createState() => _ClassifyBulkScreenState();
}

class _ClassifyBulkScreenState extends State<ClassifyBulkScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _weightController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();

  String? _selectedImagePath;
  String? _selectedCategory;
  final bool _isAnalyzing = false;
  double _enteredWeight = 5.0;

  bool _isSpeaking = false;

  // 9 Canonical Categories as the single source of truth
  final List<String> _categories = LocalAiClassifier.canonicalCategories;

  @override
  void initState() {
    super.initState();

    _selectedCategory = _categories.first;
    _weightController.text = '5.0';

    _weightController.addListener(() {
      final parsed = double.tryParse(_weightController.text);

      if (parsed != null && parsed > 0) {
        setState(() => _enteredWeight = parsed);
      }
    });

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
    _weightController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  String _t(String en, String hi, String mr) {
    switch (widget.language) {
      case AppLanguage.hindi:
        return hi;
      case AppLanguage.marathi:
        return mr;
      case AppLanguage.english:
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

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await _flutterTts.stop();

      if (mounted) {
        setState(() => _isSpeaking = false);
      }

      return;
    }

    final selectedMaterial = _selectedCategory == null
        ? ''
        : LocalAiClassifier.getLocalizedMaterialName(
            _selectedCategory!,
            widget.language,
          );

    final buffer = StringBuffer();

    buffer.write(
      _t('Create Scrap Lot. ', 'नया लॉट बनाएं। ', 'नवीन लॉट तयार करा। '),
    );

    buffer.write(
      _t('Material Category: ', 'सामग्री श्रेणी: ', 'साहित्य श्रेणी: '),
    );
    buffer.write('$selectedMaterial. ');

    buffer.write(_t('Approximate Weight: ', 'अनुमानित वजन: ', 'अंदाजे वजन: '));
    buffer.write('${_enteredWeight.toStringAsFixed(1)} kilograms. ');

    buffer.write(_t('Benchmark Rate: ', 'बेंचमार्क दर: ', 'बेंचमार्क दर: '));
    buffer.write('$_ratePerKg rupees per kilogram. ');

    buffer.write(_t('Estimated Price: ', 'अनुमानित मूल्य: ', 'अंदाजे किंमत: '));
    buffer.write('$_calculatedPrice rupees. ');

    buffer.write(
      _t(
        'To save this scrap lot, press Save and Record Lot.',
        'इस कबाड़ लॉट को सहेजने के लिए, लॉट सहेजें और जोड़ें बटन दबाएं।',
        'हा भंगार लॉट जतन करण्यासाठी, लॉट जतन करा आणि जोडा हे बटण दाबा.',
      ),
    );

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

  int get _ratePerKg {
    final benchmarks = LocalAiClassifier.getAllBenchmarks();

    if (_selectedCategory == null ||
        !benchmarks.containsKey(_selectedCategory)) {
      return 100;
    }

    return (benchmarks[_selectedCategory]['rate_per_kg'] as num? ?? 100)
        .toInt();
  }

  int get _calculatedPrice => (_enteredWeight * _ratePerKg).round();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);

    if (picked != null) {
      setState(() {
        _selectedImagePath = picked.path;
      });
    }
  }

  /// Opens the Single Item Scanner so the user can snap a close-up piece
  Future<void> _runAiDetection() async {
    // 1. Expect a Map<String, dynamic> result instead of a raw String
    final scanResult = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              _t(
                'Scan Single Piece',
                'एक टुकड़े को स्कैन करें',
                'एका तुकड्याचे स्कॅन करा',
              ),
            ),
          ),
          body: PickupUploadTab(
            storage: widget.storage,
            language: widget.language,
            isPickerMode: true,
          ),
        ),
      ),
    );

    if (scanResult == null || !mounted) return;

    // 2. Extract validation flags and codes from the result map
    final bool isValidEwaste = scanResult['isValidEwaste'] ?? true;
    final bool isNonEwaste = scanResult['isNonEwaste'] ?? false;
    final bool isLowConfidence = scanResult['isLowConfidence'] ?? false;
    final String detectedCode =
        scanResult['materialCode'] ?? scanResult['material'] ?? '';

    // 3. 🛑 Guardrail: Block low confidence or non-e-waste items from bulk selection
    if (!isValidEwaste) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            isNonEwaste
                ? _t('Not E-Waste', 'ई-कचरा नहीं', 'इ-कचरा नाही')
                : _t('Low AI Confidence', 'कम एआई सटीकता', 'कमी एआय अचूकता'),
          ),
          content: Text(
            isNonEwaste
                ? _t(
                    'The scanned item is not recognized as valid e-waste. Cannot add to bulk lot.',
                    'स्कैन की गई वस्तु वैध ई-कचरा नहीं है। बल्क लॉट में नहीं जोड़ा जा सकता।',
                    'स्कॅन केलेली वस्तू वैध इ-कचरा नाही. बल्क लॉटमध्ये जोडले जाऊ शकत नाही.',
                  )
                : _t(
                    'AI confidence is too low to auto-select. Please retake a clearer picture.',
                    'ऑटो-सेलेक्ट करने के लिए एआई सटीकता बहुत कम है। कृपया स्पष्ट तस्वीर लें.',
                    'ऑटो-निवड करण्यासाठी एआय अचूकता खूप कमी आहे. कृपया स्पष्ट चित्र घ्या.',
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t('OK', 'ठीक है', 'ठीक आहे')),
            ),
          ],
        ),
      );
      return; // Stop execution here!
    }

    // 4. Handle Wire & Cabling Sub-selection dialog
    if (detectedCode == 'CABLES_AND_WIRING' ||
        detectedCode == 'cables' ||
        detectedCode == 'wire' ||
        detectedCode == 'COPPER_HEAVY_INSULATED' ||
        detectedCode == 'ALUMINIUM_WIRE') {
      final chosenCategory = await _showWireSelectionDialog();

      if (chosenCategory != null && mounted) {
        setState(() => _selectedCategory = chosenCategory);
        _notifyIdentified(chosenCategory);
      }

      return;
    }

    // 5. Select valid category if it exists in our list
    if (_categories.contains(detectedCode)) {
      setState(() => _selectedCategory = detectedCode);
      _notifyIdentified(detectedCode);
    }
  }

  void _notifyIdentified(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.featherGreen,
        content: Text(
          '${_t("AI Identified:", "एआई ने पहचाना:", "एआय ने ओळखले:")} ${LocalAiClassifier.getLocalizedMaterialName(code, widget.language)}',
        ),
      ),
    );
  }

  Future<String?> _showWireSelectionDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.cable, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t(
                    'Inspect Wire Core',
                    'तार की जांच करें',
                    'तारेचा गाभा तपासा',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _t(
                    '⚠️ Peel a small tip of insulation to inspect the internal metal conductor:',
                    '⚠️ अंदर की धातु देखने के लिए तार का थोड़ा इंसुलेशन छीलें:',
                    '⚠️ आतील धातू पाहण्यासाठी वायरचे थोडे इन्सुलेशन काढा:',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFB87333),
                  radius: 14,
                ),
                title: Text(
                  _t(
                    'Copper Wire (Reddish / ₹455/kg)',
                    'तांबे का तार (लाल-भूरा / ₹455/kg)',
                    'तांब्याची तार (लालसर / ₹455/kg)',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  _t(
                    'Heavy reddish-brown metallic wire',
                    'लाल-भूरा भारी धातु का तार',
                    'लालसर रंगाची जड धातूची तार',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, 'COPPER_HEAVY_INSULATED'),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFC0C0C0),
                  radius: 14,
                ),
                title: Text(
                  _t(
                    'Aluminium Wire (Silver / ₹124/kg)',
                    'एल्युमिनियम तार (सफेद-चांदी / ₹124/kg)',
                    'अ‍ॅल्युमिनियम तार (चांदेरी / ₹124/kg)',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  _t(
                    'Lightweight silver metallic conductor',
                    'चांदी जैसा हल्का तार',
                    'हलकी चंदेरी रंगाची तार',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(ctx, 'ALUMINIUM_WIRE'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveAndConfirmLot() async {
    if (_selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            _t(
              'Please take or pick a photo of the scrap lot first.',
              'कृपया पहले कबाड़ लॉट की एक फोटो लें।',
              'कृपया आधी भंगार लॉटचा एक फोटो घ्या.',
            ),
          ),
        ),
      );
      return;
    }

    await _flutterTts.stop();

    if (mounted) {
      setState(() => _isSpeaking = false);
    }

    final lotUid = 'LOT_${DateTime.now().millisecondsSinceEpoch}';

    final payload = {
      'lot_uid': lotUid,
      'material_category': _selectedCategory!,
      'approx_weight_kg': _enteredWeight,
      'estimated_rate_per_kg': _ratePerKg,
      'estimated_total_payout': _calculatedPrice,
      'created_at': DateTime.now().toIso8601String(),
    };

    // 1. Enqueue lot in local SQLite database with explicit weight!
    await DatabaseHelper.instance.enqueueLot(
      lotUid: lotUid,
      imagePath: _selectedImagePath!,
      jsonPayload: jsonEncode(payload),
      materialCategory: _selectedCategory!,
      estimatedWeightKg: _enteredWeight, // 👈 Pass the entered weight here!
    );

    // 2. Trigger automatic background sync if device is online
    final storage = widget.storage ?? getStorage(context);
    SyncWorker.triggerImmediate(storage);

    if (!mounted) return;

    final lotData = {
      'lotUid': lotUid,
      'materialCode': _selectedCategory!,
      'weight': '${_enteredWeight.toStringAsFixed(1)} kg',
      'price': '₹$_calculatedPrice',
      'imagePath': _selectedImagePath!,
      'date': DateTime.now().toIso8601String(),
    };

    // 3. Open confirmation receipt
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ClassifyResultScreen(
          result: lotData,
          language: widget.language,
          isDiagnostic: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('Create Scrap Lot', 'नया लॉट बनाएं', 'नवीन लॉट तयार करा'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview & Upload Controls
            GestureDetector(
              onTap: () => _pickImage(ImageSource.camera),
              child: Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppThemeColors.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: activeAccent.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: _selectedImagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          File(_selectedImagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 48, color: activeAccent),
                          const SizedBox(height: 8),
                          Text(
                            _t(
                              'Take Photo of Scrap Lot',
                              'कबाड़ लॉट का फोटो लें',
                              'भंगार लॉटचा फोटो घ्या',
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppThemeColors.text(context),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: Text(_t('Camera', 'कैमरा', 'कॅमेरा')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text(_t('Gallery', 'गैलरी', 'गॅलरी')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Material Category Selection + AI Detect Helper
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _t('Material Category', 'सामग्री श्रेणी', 'साहित्य श्रेणी'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton.icon(
                  onPressed: _isAnalyzing ? null : _runAiDetection,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(
                    _t('Detect with AI', 'एआई से पहचानें', 'एआय द्वारे ओळखा'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppThemeColors.card(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: _categories.map((code) {
                    return DropdownMenuItem(
                      value: code,
                      child: Row(
                        children: [
                          Icon(
                            LocalAiClassifier.getMaterialIcon(code),
                            color: activeAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              LocalAiClassifier.getLocalizedMaterialName(
                                code,
                                widget.language,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Approximate Weight Input
            Text(
              _t(
                'Approximate Weight (kg)',
                'अनुमानित वजन (किग्रा)',
                'अंदाजे वजन (किग्रॅ)',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppThemeColors.card(context),
                suffixText: 'kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Valuation & Price Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: activeAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: activeAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _t('Benchmark Rate', 'बेंचमार्क दर', 'बेंचमार्क दर'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppThemeColors.muted(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹$_ratePerKg / kg',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _t('Estimated Price', 'अनुमानित मूल्य', 'अंदाजे किंमत'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppThemeColors.muted(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹$_calculatedPrice',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: activeAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save Lot Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saveAndConfirmLot,
                child: Text(
                  _t(
                    'Save & Record Lot',
                    'लॉट सहेजें और जोड़ें',
                    'लॉट जतन करा आणि जोडा',
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
