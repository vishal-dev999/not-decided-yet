import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_text.dart';
import '../services/database_helper.dart';
import '../services/classifier_service.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _capturedImage;
  File? _bulkImage; // <--- ADD THIS
  bool _isProcessing = false;
  String? _detectedMaterial;
  double? _confidence;
  bool _isCategoryConfirmed = false; // <--- ADD THIS
  final TextEditingController _weightController =
      TextEditingController(); // <--- ADD THIS

  List<Map<String, dynamic>> _queuedLots = [];

  @override
  void initState() {
    super.initState();
    _refreshQueue();
  }

  Future<void> _refreshQueue() async {
    final lots = await DatabaseHelper.instance.getQueuedLots();
    setState(() {
      _queuedLots = lots;
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (photo == null) return;

      setState(() {
        _isProcessing = true;
      });

      // 1. Move to permanent storage so Android never purges it from cache
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'lot_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = 'lot_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentFile = await File(photo.path)
          .copy(p.join(imagesDir.path, fileName));

      // 2. RUN TFLITE INFERENCE HERE (Via ClassifierService)
      // e.g.: final result = await ClassifierService.predict(permanentFile);
      // For now, placeholder prediction before plugging in tflite_flutter:
      // Run real PyTorch-derived MobileNetV3 inference
      final result = await ClassifierService.predict(permanentFile);

      setState(() {
        _capturedImage = permanentFile;
        _detectedMaterial = result.label;
        _confidence = result.confidence;
        _isCategoryConfirmed = false; // Reset confirmation for new photo
        _bulkImage = null; // Clear previous scale photo
        _weightController.clear(); // Clear previous weight
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final File imageFile = File(pickedFile.path);
      final result = await ClassifierService.predict(imageFile);

      setState(() {
        _capturedImage = imageFile;
        _detectedMaterial = result.label;
        _confidence = result.confidence;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Classification failed: $e')));
    }
  }

  Future<void> _pickBulkImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (photo == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'lot_images'));
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

      final fileName = 'bulk_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permanentFile = await File(photo.path)
          .copy(p.join(imagesDir.path, fileName));

      setState(() {
        _bulkImage = permanentFile;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get bulk photo: $e')));
      }
    }
  }

  void _showLotPayloadDetails(String lotUid, Map<String, dynamic> payload) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Lot #$lotUid',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(payload),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueSection() {
    if (_queuedLots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Lots (${_queuedLots.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF173C37),
              ),
            ),
            TextButton.icon(
              onPressed: _refreshQueue,
              icon: const Icon(
                Icons.refresh,
                size: 16,
                color: Color(0xFF176B5B),
              ),
              label: const Text(
                'Refresh',
                style: TextStyle(color: Color(0xFF176B5B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _queuedLots.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _queuedLots[index];
            final Map<String, dynamic> payload = jsonDecode(
              item['json_payload'] ?? '{}',
            );
            final String material = payload['material_category'] ?? 'UNKNOWN';
            final double weight =
                (payload['weight_kg'] as num?)?.toDouble() ?? 0.0;
            final double estValue =
                (payload['offline_estimated_value_inr'] as num?)?.toDouble() ??
                0.0;
            final String status = item['status'] ?? 'PENDING';
            final String imagePath = item['image_path'] ?? '';

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3EBE8)),
              ),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imagePath.isNotEmpty && File(imagePath).existsSync()
                        ? Image.file(
                            File(imagePath),
                            width: 55,
                            height: 55,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 55,
                            height: 55,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 24,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Main Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.replaceAll('_', ' '),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Weight: ${weight.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.amber.shade300,
                                ),
                              ),
                              child: const Text(
                                'Offline Est.',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '₹${estValue.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF176B5B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status & Details Button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'SYNCED'
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: status == 'SYNCED'
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            _showLotPayloadDetails(item['lot_uid'], payload),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConfirmationSection() {
    if (_capturedImage == null || _detectedMaterial == null) {
      return const SizedBox.shrink();
    }

    final bool isConfident = (_confidence ?? 0.0) >= 0.75;
    final List<String> categories = [
      'BATTERY_LITHIUM_PORTABLE',
      'COPPER_HEAVY_INSULATED',
      'LEAD_ACID',
      'MOTHERBOARD_HIGH_GRADE',
      'NON_RECYCLABLE',
      'POWER_SUPPLY_LOW_GRADE',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isConfident
              ? const Color(0xFF176B5B).withOpacity(0.3)
              : Colors.amber.shade400,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Identified Material',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConfident
                      ? Colors.green.shade50
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConfident
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      size: 14,
                      color: isConfident
                          ? Colors.green.shade700
                          : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${((_confidence ?? 0.0) * 100).toStringAsFixed(1)}% match',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isConfident
                            ? Colors.green.shade700
                            : Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Collector Override Dropdown
          DropdownButtonFormField<String>(
            value: categories.contains(_detectedMaterial)
                ? _detectedMaterial
                : null,
            decoration: InputDecoration(
              labelText: 'Grade / Material Type',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: categories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(
                  cat.replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _detectedMaterial = val;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          // IF NOT CONFIRMED: Show the confirmation button
          if (!_isCategoryConfirmed)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF176B5B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isCategoryConfirmed = true;
                  });
                },
                child: const Text('Confirm Category & Add Scale Proof'),
              ),
            )
          // IF CONFIRMED: Reveal Bulk/Scale Photo and Weight Fields
          else ...[
            const Divider(height: 28),
            const Text(
              'Step 2: Scale & Bulk Proof',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: _bulkImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(_bulkImage!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.scale, color: Colors.grey, size: 36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickBulkImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: Text(
                          _bulkImage == null
                              ? 'Scale Photo'
                              : 'Retake Scale Photo',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF176B5B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(
                        onPressed: () => _pickBulkImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: const Text('From Gallery'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Lot Weight',
                hintText: 'e.g. 14.5',
                suffixText: 'kg',
                suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveLotToOfflineQueue() async {
    if (_capturedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final lotUid = 'LOT-${DateTime.now().millisecondsSinceEpoch}';

      // JSON metadata to accompany the image
      final payload = jsonEncode({
        'lot_uid': lotUid,
        'classified_material': _detectedMaterial,
        'confidence': _confidence,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'PENDING',
      });

      // Save to SQLite
      await DatabaseHelper.instance.enqueueLot(
        lotUid: lotUid,
        imagePath: _capturedImage!.path,
        jsonPayload: payload,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lot classified and saved to offline queue!'),
          backgroundColor: Color(0xFF176B5B),
        ),
      );

      // Reset for next picture
      setState(() {
        _capturedImage = null;
        _bulkImage = null;
        _detectedMaterial = null;
        _confidence = null;
        _isCategoryConfirmed = false;
        _weightController.clear();
        _isProcessing = false;
      });

      // === CALL IT RIGHT HERE ===
      await _refreshQueue();
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save lot: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              AppText.get('upload_title'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF173C37),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppText.get('upload_message'),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE3EBE8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Preview or Icon
                  if (_capturedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        _capturedImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 110,
                      width: 110,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        size: 55,
                        color: Color(0xFF176B5B),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Classification Result / Instructions
                  if (_detectedMaterial != null) ...[
                    Text(
                      _detectedMaterial!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF176B5B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confidence: ${(_confidence! * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'AI Material Scanner',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Take a photo of scrap to identify material and estimate price.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Capture/Recapture and Gallery buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _takePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: Text(
                              _capturedImage == null ? 'Camera' : 'Retake',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF176B5B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _pickFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: Text(
                              _capturedImage == null ? 'Gallery' : 'Replace',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF176B5B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  _buildConfirmationSection(),

                  // Queue Button (Active once photo is classified)
                  if (_capturedImage != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : _saveLotToOfflineQueue,
                        icon: const Icon(Icons.archive_outlined),
                        label: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Save Directly to Queue'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF176B5B),
                          side: const BorderSide(
                            color: Color(0xFF176B5B),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24), // Bottom breathing room
            _buildQueueSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
