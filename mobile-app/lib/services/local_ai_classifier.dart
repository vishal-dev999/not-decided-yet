import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime_v2/onnxruntime_v2.dart';

import '../constants/app_enums.dart';

/// Top-level function executed on a background isolate
Float32List _preprocessImageIsolate(Uint8List imageBytes) {
  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) return Float32List(0);

  // Resize directly to training dimensions (224x224)
  final resized = img.copyResize(decoded, width: 224, height: 224);

  // Buffer: [1, 3, 224, 224] (NCHW)
  const int planeSize = 224 * 224;
  final inputList = Float32List(3 * planeSize);

  // ImageNet standard mean & std matching torchvision data_transforms
  const meanR = 0.485, meanG = 0.456, meanB = 0.406;
  const stdR = 0.229, stdG = 0.224, stdB = 0.225;

  int rIdx = 0;
  int gIdx = planeSize;
  int bIdx = planeSize * 2;

  for (int y = 0; y < 224; y++) {
    for (int x = 0; x < 224; x++) {
      final p = resized.getPixel(x, y);
      inputList[rIdx++] = ((p.r / 255.0) - meanR) / stdR;
      inputList[gIdx++] = ((p.g / 255.0) - meanG) / stdG;
      inputList[bIdx++] = ((p.b / 255.0) - meanB) / stdB;
    }
  }

  return inputList;
}

class LocalAiClassifier {
  static OrtSession? _session;
  static List<String> _labels = [];
  static bool _isInitialized = false;

  /// The 9 canonical backend categories (Source of Truth)
  static const List<String> canonicalCategories = [
    'MOTHERBOARD_HIGH_GRADE',
    'POWER_SUPPLY_LOW_GRADE',
    'BATTERY_LITHIUM_PORTABLE',
    'LEAD_ACID',
    'CRT_MONITOR',
    'LCD_PANEL_INTACT',
    'MIXED_EWASTE_CASING',
    'COPPER_HEAVY_INSULATED',
    'ALUMINIUM_WIRE',
  ];

  /// Static baseline benchmarks matching the database seed rates
  static const Map<String, Map<String, dynamic>> benchmarks = {
    'MOTHERBOARD_HIGH_GRADE': {
      'rate_per_kg': 305,
      'min_rate': 250,
      'max_rate': 380,
    },
    'POWER_SUPPLY_LOW_GRADE': {
      'rate_per_kg': 54,
      'min_rate': 40,
      'max_rate': 72,
    },
    'BATTERY_LITHIUM_PORTABLE': {
      'rate_per_kg': 142,
      'min_rate': 110,
      'max_rate': 185,
    },
    'LEAD_ACID': {
      'rate_per_kg': 92,
      'min_rate': 75,
      'max_rate': 115,
    },
    'CRT_MONITOR': {
      'rate_per_kg': 20,
      'min_rate': 14,
      'max_rate': 28,
    },
    'LCD_PANEL_INTACT': {
      'rate_per_kg': 82,
      'min_rate': 64,
      'max_rate': 108,
    },
    'MIXED_EWASTE_CASING': {
      'rate_per_kg': 22,
      'min_rate': 15,
      'max_rate': 32,
    },
    'COPPER_HEAVY_INSULATED': {
      'rate_per_kg': 455,
      'min_rate': 390,
      'max_rate': 540,
    },
    'ALUMINIUM_WIRE': {
      'rate_per_kg': 124,
      'min_rate': 96,
      'max_rate': 158,
    },
  };

  static Map<String, dynamic> getAllBenchmarks() => benchmarks;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      OrtEnv.instance.init();
      final sessionOptions = OrtSessionOptions()
        ..setInterOpNumThreads(2)
        ..setIntraOpNumThreads(2)
        ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);

      final rawModel = await rootBundle.load('assets/model.onnx');
      final bytes = rawModel.buffer.asUint8List();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);

      final labelsStr = await rootBundle.loadString('assets/labels.txt');
      _labels = const LineSplitter()
          .convert(labelsStr)
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      _isInitialized = true;
      debugPrint('[LocalAiClassifier] ONNX model ready. Classes: ${_labels.length}');
    } catch (e, st) {
      debugPrint('[LocalAiClassifier] Initialization error: $e\n$st');
    }
  }

  static String getLocalizedMaterialName(String rawCode, AppLanguage language) {
    switch (rawCode) {
      case 'BATTERY_LITHIUM_PORTABLE':
        return language == AppLanguage.hindi
            ? 'लिथियम-आयन बैटरी'
            : language == AppLanguage.marathi
                ? 'लिथियम-आयन बॅटरी'
                : 'Lithium Batteries';
      case 'CABLES_AND_WIRING':
        return language == AppLanguage.hindi
            ? 'तार व केबल'
            : language == AppLanguage.marathi
                ? 'तारा आणि केबल'
                : 'Cables & Wiring';
      case 'CRT_MONITOR':
        return language == AppLanguage.hindi
            ? 'सीआरटी मॉनिटर'
            : language == AppLanguage.marathi
                ? 'सीआरटी मॉनिटर'
                : 'CRT Monitors';
      case 'LEAD_ACID':
        return language == AppLanguage.hindi
            ? 'लेड-एसिड बैटरी'
            : language == AppLanguage.marathi
                ? 'लेड-अ‍ॅसिड बॅटरी'
                : 'Lead Batteries';
      case 'MOTHERBOARD_HIGH_GRADE':
        return language == AppLanguage.hindi
            ? 'हाई-ग्रेड मदरबोर्ड (पीसीबी)'
            : language == AppLanguage.marathi
                ? 'हाय-ग्रेड मदरबोर्ड (पीसीबी)'
                : 'High Grade PCB';
      case 'POWER_SUPPLY_LOW_GRADE':
        return language == AppLanguage.hindi
            ? 'लो-ग्रेड पीसीबी (एसएमपीएस)'
            : language == AppLanguage.marathi
                ? 'लो-ग्रेड पीसीबी (एसएमपीएस)'
                : 'Low Grade PCB';
      case 'LCD_PANEL_INTACT':
      case 'FLAT_PANEL_DISPLAY':
        return language == AppLanguage.hindi
            ? 'एलसीडी/एलईडी डिस्प्ले'
            : language == AppLanguage.marathi
                ? 'एलसीडी/एलईडी डिस्प्ले'
                : 'LCD/LED Flat Panel';
      case 'MIXED_EWASTE_CASING':
      case 'MIXED_PLASTICS':
        return language == AppLanguage.hindi
            ? 'मिश्रित ई-कचरा प्लास्टिक'
            : language == AppLanguage.marathi
                ? 'मिश्र ई-कचरा प्लास्टिक'
                : 'Mixed Plastic';
      case 'COPPER_HEAVY_INSULATED':
        return language == AppLanguage.hindi
            ? 'तांबे का तार'
            : language == AppLanguage.marathi
                ? 'तांब्याची तार'
                : 'Copper Wire';
      case 'ALUMINIUM_WIRE':
        return language == AppLanguage.hindi
            ? 'एल्युमिनियम तार'
            : language == AppLanguage.marathi
                ? 'अ‍ॅल्युमिनियम तार'
                : 'Aluminium Wire';
      default:
        return rawCode;
    }
  }

  static IconData getMaterialIcon(String code) {
    switch (code) {
      case 'BATTERY_LITHIUM_PORTABLE':
      case 'LEAD_ACID':
        return Icons.battery_charging_full;
      case 'CABLES_AND_WIRING':
      case 'COPPER_HEAVY_INSULATED':
      case 'ALUMINIUM_WIRE':
        return Icons.cable;
      case 'CRT_MONITOR':
      case 'LCD_PANEL_INTACT':
      case 'FLAT_PANEL_DISPLAY':
        return Icons.tv;
      case 'MOTHERBOARD_HIGH_GRADE':
      case 'POWER_SUPPLY_LOW_GRADE':
        return Icons.developer_board;
      case 'MIXED_EWASTE_CASING':
      case 'MIXED_PLASTICS':
      default:
        return Icons.recycling;
    }
  }

  static Future<Map<String, dynamic>> classify(
    String imagePath, {
    bool bulk = false,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    String predictedCode = _labels.isNotEmpty ? _labels.first : 'MOTHERBOARD_HIGH_GRADE';
    double confidenceValue = 0.85;

    try {
      final rawBytes = await File(imagePath).readAsBytes();
      final inputList = await compute(_preprocessImageIsolate, rawBytes);

      if (inputList.isNotEmpty && _session != null) {
        final inputOrt = OrtValueTensor.createTensorWithDataList(
          inputList,
          [1, 3, 224, 224],
        );
        final runOptions = OrtRunOptions();

        final outputs = await _session!.runAsync(runOptions, {'input': inputOrt});

        inputOrt.release();
        runOptions.release();

        if (outputs != null && outputs.isNotEmpty && outputs.first != null) {
          final outputTensor = outputs.first!.value as List;
          final logits = (outputTensor.first as List).cast<double>();

          final maxLogit = logits.reduce(math.max);
          final expValues = logits.map((e) => math.exp(e - maxLogit)).toList();
          final sumExp = expValues.reduce((a, b) => a + b);
          final probs = expValues.map((e) => e / sumExp).toList();

          int bestIdx = 0;
          double maxProb = probs[0];
          for (int i = 1; i < probs.length; i++) {
            if (probs[i] > maxProb) {
              maxProb = probs[i];
              bestIdx = i;
            }
          }

          if (bestIdx < _labels.length) {
            predictedCode = _labels[bestIdx];
            confidenceValue = maxProb;
          }

          for (final o in outputs) {
            o?.release();
          }
        }
      }
    } catch (e, st) {
      debugPrint('[LocalAiClassifier] ONNX inference error: $e\n$st');
    }

    // Map labels if training output used alternate keys
    if (predictedCode == 'FLAT_PANEL_DISPLAY') predictedCode = 'LCD_PANEL_INTACT';
    if (predictedCode == 'MIXED_PLASTICS') predictedCode = 'MIXED_EWASTE_CASING';

    final benchmark = benchmarks[predictedCode] ?? {
      'rate_per_kg': 100,
      'min_rate': 80,
      'max_rate': 120,
    };

    final int ratePerKg = (benchmark['rate_per_kg'] as num? ?? 100).toInt();

    return {
      'materialCode': predictedCode,
      'material': predictedCode,
      'confidence': '${(confidenceValue * 100).toStringAsFixed(0)}%',
      'confidencePct': '${(confidenceValue * 100).toStringAsFixed(1)}%',
      'ratePerKg': ratePerKg,
      'price': '₹$ratePerKg/kg',
      'imagePath': imagePath,
      'date': DateTime.now().toIso8601String(),
    };
  }

  static void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }
}
