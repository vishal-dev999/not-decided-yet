import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';

class ClassificationResult {
  final String label;
  final double confidence;

  ClassificationResult({required this.label, required this.confidence});
}

class ClassifierService {
  static OrtSession? _session;
  static List<String>? _labels;

  /// Initializes the ONNX environment and loads model bytes from assets
  static Future<void> init() async {
    if (_session != null && _labels != null) return;

    // 1. Initialize ONNX runtime environment
    OrtEnv.instance.init();

    // 2. Load model bytes from Flutter bundle
    final rawAssetFile = await rootBundle.load('assets/models/model.onnx');
    final bytes = rawAssetFile.buffer.asUint8List();
    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromBuffer(bytes, sessionOptions);
    sessionOptions.release();

    // 3. Load labels
    final labelData = await rootBundle.loadString('assets/models/labels.txt');
    _labels = labelData
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static Future<ClassificationResult> predict(File imageFile) async {
    await init();

    // 1. Decode image from file
    final bytes = await imageFile.readAsBytes();
    final img.Image? rawImage = img.decodeImage(bytes);
    if (rawImage == null) {
      throw Exception("Could not decode image");
    }

    // 2. Resize to 224x224 (matching PyTorch input)
    final img.Image resized = img.copyResize(rawImage, width: 224, height: 224);

    // 3. Flatten into Float32List with PyTorch normalization: (val / 255.0 - mean) / std
    // Expected Shape: [1, 3, 224, 224] (NCHW)
    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    final Float32List inputData = Float32List(1 * 3 * 224 * 224);

    for (int c = 0; c < 3; c++) {
      final double m = mean[c];
      final double s = std[c];
      final int channelOffset = c * 224 * 224;

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          final pixel = resized.getPixel(x, y);
          double channelVal;
          if (c == 0) {
            channelVal = pixel.r / 255.0;
          } else if (c == 1) {
            channelVal = pixel.g / 255.0;
          } else {
            channelVal = pixel.b / 255.0;
          }

          inputData[channelOffset + (y * 224 + x)] = (channelVal - m) / s;
        }
      }
    }

    // 4. Create ONNX input tensor
    final shape = [1, 3, 224, 224];
    final inputOrt = OrtValueTensor.createTensorWithDataList(inputData, shape);
    final inputs = {'input': inputOrt};
    final runOptions = OrtRunOptions();

    // 5. Run inference
    final outputs = await _session?.runAsync(runOptions, inputs);

    // Release native memory for input and options
    inputOrt.release();
    runOptions.release();

    if (outputs == null || outputs.isEmpty || outputs[0] == null) {
      throw Exception("Failed to get prediction from ONNX session");
    }

    // 6. Extract output logits & release output tensors
    final List<dynamic> rawList = outputs[0]!.value as List<dynamic>;
    final List<double> logits = List<double>.from(
      rawList[0].map((e) => (e as num).toDouble()),
    );

    for (final element in outputs) {
      element?.release();
    }

    // 7. Compute Softmax probabilities
    final probs = _softmax(logits);

    int bestIndex = 0;
    double maxProb = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        bestIndex = i;
      }
    }

    return ClassificationResult(
      label: _labels![bestIndex],
      confidence: maxProb,
    );
  }

  static List<double> _softmax(List<double> logits) {
    double maxLogit = logits.reduce(max);
    List<double> expValues = logits.map((l) => exp(l - maxLogit)).toList();
    double sumExp = expValues.reduce((a, b) => a + b);
    return expValues.map((e) => e / sumExp).toList();
  }
}
