import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_enums.dart';
import '../../models/rider_pickup.dart';
import '../../services/storage_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';
import 'rider_dashboard_screen.dart';

class RiderPickupProofScreen extends StatefulWidget {
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final Future<void> Function(ReNovaThemeMode) onThemeChanged;
  final ReNovaStorage storage;
  final RiderPickup pickup;

  const RiderPickupProofScreen({
    super.key,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
    required this.storage,
    required this.pickup,
  });

  @override
  State<RiderPickupProofScreen> createState() =>
      _RiderPickupProofScreenState();
}

class _RiderPickupProofScreenState
    extends State<RiderPickupProofScreen> {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _weightController =
      TextEditingController();

  final TextEditingController _notesController =
      TextEditingController();

  File? proofImage;
  bool confirmationChecked = false;
  bool isSubmitting = false;

  String _text(
    String english,
    String hindi,
    String marathi,
  ) {
    switch (widget.language) {
      case AppLanguage.hindi:
        return hindi;
      case AppLanguage.marathi:
        return marathi;
      case AppLanguage.english:
        return english;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) {
        return;
      }

      setState(() {
        proofImage = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Unable to open camera.',
              'कैमरा खोलने में असमर्थ।',
              'कॅमेरा उघडता आला नाही.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _chooseFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        return;
      }

      setState(() {
        proofImage = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Unable to open gallery.',
              'गैलरी खोलने में असमर्थ।',
              'गॅलरी उघडता आली नाही.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _completePickup() async {
    final weightText = _weightController.text.trim();
    final weight = double.tryParse(weightText);

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Please enter a valid collected weight.',
              'कृपया सही एकत्रित वजन दर्ज करें।',
              'कृपया योग्य संकलित वजन प्रविष्ट करा.',
            ),
          ),
        ),
      );
      return;
    }

    if (proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Please add a pickup photo.',
              'कृपया पिकअप फोटो जोड़ें।',
              'कृपया पिकअप फोटो जोडा.',
            ),
          ),
        ),
      );
      return;
    }

    if (!confirmationChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Please confirm the collection first.',
              'कृपया पहले कलेक्शन की पुष्टि करें।',
              'कृपया प्रथम संकलनाची पुष्टी करा.',
            ),
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final existingRaw =
          widget.storage.prefs.getString('rider_pickup_history');

      List<Map<String, dynamic>> history = [];

      if (existingRaw != null && existingRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(existingRaw);

          if (decoded is List) {
            history = decoded
                .whereType<Map>()
                .map(
                  (item) => Map<String, dynamic>.from(item),
                )
                .toList();
          }
        } catch (_) {
          history = [];
        }
      }

      // ------------------------------------------------------------
      // SAVE THE EXACT PICKUP THAT THE RIDER COMPLETED
      // ------------------------------------------------------------

      final completedPickup = <String, dynamic>{
        'pickupId': widget.pickup.id,
        'collectionPoint': widget.pickup.name,
        'location': widget.pickup.location,
        'address': widget.pickup.address,
        'contactPerson': widget.pickup.person,
        'phone': widget.pickup.phone,
        'distance': widget.pickup.distance,
        'scheduledTime': widget.pickup.time,
        'expectedMaterial': widget.pickup.expectedMaterial,
        'expectedMaterials': widget.pickup.expectedMaterials
            .map((item) => item.toMap())
            .toList(),
        'weight': weight,
        'notes': _notesController.text.trim(),
        'proofImagePath': proofImage!.path,
        'completedAt': DateTime.now().toIso8601String(),
        'status': 'Completed',
      };

      // ------------------------------------------------------------
      // PREVENT DUPLICATE HISTORY ENTRY FOR THE SAME PICKUP
      // ------------------------------------------------------------

      history.removeWhere(
        (item) =>
            item['pickupId']?.toString() == widget.pickup.id,
      );

      history.insert(0, completedPickup);

      await widget.storage.prefs.setString(
        'rider_pickup_history',
        jsonEncode(history),
      );

      // ------------------------------------------------------------
      // SAVE COMPLETION STATE PER PICKUP
      //
      // This is intentionally NOT a single global completion flag.
      // Sharma, Kumar and Verma each get their own completion state.
      // ------------------------------------------------------------

      await widget.storage.prefs.setBool(
        'rider_pickup_completed_${widget.pickup.id}',
        true,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Pickup completed successfully.',
              'पिकअप सफलतापूर्वक पूरा हुआ।',
              'पिकअप यशस्वीरित्या पूर्ण झाला.',
            ),
          ),
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RiderDashboardScreen(
            language: widget.language,
            themeMode: widget.themeMode,
            onThemeChanged: widget.onThemeChanged,
            storage: widget.storage,
            riderName: 'Rider',
          ),
        ),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        widget.themeMode == ReNovaThemeMode.dark;

    final backgroundColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    final cardColor = isDark
        ? AppColors.cardBg
        : AppColors.lightCard;

    final primaryColor = isDark
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    final textColor = isDark
        ? Colors.white
        : AppColors.lightText;

    final secondaryTextColor = isDark
        ? Colors.white70
        : AppColors.lightText.withValues(alpha: 0.65);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(
          _text(
            'Pickup proof',
            'पिकअप प्रमाण',
            'पिकअप पुरावा',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          8,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // CURRENT STATUS
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.16,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text(
                            'Collection completed',
                            'संग्रह पूरा हो गया',
                            'संकलन पूर्ण झाले',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _text(
                            'Add final pickup details',
                            'अंतिम पिकअप विवरण जोड़ें',
                            'अंतिम पिकअप तपशील जोडा',
                          ),
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: 0.82,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // SELECTED PICKUP
            // --------------------------------------------------

            Text(
              _text(
                'Collection summary',
                'कलेक्शन सारांश',
                'कलेक्शन सारांश',
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    icon: Icons.storefront_outlined,
                    title: _text(
                      'Collection point',
                      'कलेक्शन पॉइंट',
                      'कलेक्शन पॉइंट',
                    ),
                    value: widget.pickup.name,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    primaryColor: primaryColor,
                  ),

                  const Divider(height: 26),

                  _summaryRow(
                    icon: Icons.person_outline_rounded,
                    title: _text(
                      'Contact person',
                      'संपर्क व्यक्ति',
                      'संपर्क व्यक्ती',
                    ),
                    value: widget.pickup.person,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    primaryColor: primaryColor,
                  ),

                  const Divider(height: 26),

                  _summaryRow(
                    icon: Icons.location_on_outlined,
                    title: _text(
                      'Location',
                      'स्थान',
                      'स्थान',
                    ),
                    value: widget.pickup.address,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    primaryColor: primaryColor,
                  ),

                  const Divider(height: 26),

                  _summaryRow(
                    icon: Icons.devices_other_outlined,
                    title: _text(
                      'Expected material',
                      'अपेक्षित सामग्री',
                      'अपेक्षित सामग्री',
                    ),
                    value: widget.pickup.expectedMaterial,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    primaryColor: primaryColor,
                  ),

                  const Divider(height: 26),

                  _summaryRow(
                    icon: Icons.badge_outlined,
                    title: _text(
                      'Pickup ID',
                      'पिकअप आईडी',
                      'पिकअप आयडी',
                    ),
                    value: widget.pickup.id,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // COLLECTED WEIGHT
            // --------------------------------------------------

            Text(
              _text(
                'Collected weight',
                'एकत्रित वजन',
                'संकलित वजन',
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: _text(
                  'Enter total weight',
                  'कुल वजन दर्ज करें',
                  'एकूण वजन प्रविष्ट करा',
                ),
                hintStyle: TextStyle(
                  color: secondaryTextColor,
                ),
                suffixText: 'kg',
                suffixStyle: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w800,
                ),
                prefixIcon: Icon(
                  Icons.scale_outlined,
                  color: primaryColor,
                ),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // PICKUP PHOTO
            // --------------------------------------------------

            Text(
              _text(
                'Pickup photo',
                'पिकअप फोटो',
                'पिकअप फोटो',
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: _capturePhoto,
              child: Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryColor.withValues(
                      alpha: 0.25,
                    ),
                    width: 1.2,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: proofImage == null
                    ? Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color:
                                  primaryColor.withValues(
                                alpha: 0.10,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: primaryColor,
                              size: 25,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _text(
                              'Take pickup photo',
                              'पिकअप फोटो लें',
                              'पिकअप फोटो घ्या',
                            ),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _text(
                              'Photo helps verify the collection',
                              'फोटो कलेक्शन की पुष्टि में मदद करता है',
                              'फोटो संकलनाची पुष्टी करण्यास मदत करतो',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            proofImage!,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(
                                  alpha: 0.65,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: _capturePhoto,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 10),

            if (proofImage == null)
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: _chooseFromGallery,
                  icon: Icon(
                    Icons.photo_library_outlined,
                    color: primaryColor,
                  ),
                  label: Text(
                    _text(
                      'Choose from gallery',
                      'गैलरी से चुनें',
                      'गॅलरीमधून निवडा',
                    ),
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // NOTES
            // --------------------------------------------------

            Text(
              _text(
                'Notes',
                'नोट्स',
                'नोंदी',
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _notesController,
              maxLines: 4,
              style: TextStyle(
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText: _text(
                  'Add any important pickup notes...',
                  'कोई महत्वपूर्ण पिकअप नोट जोड़ें...',
                  'महत्त्वाच्या पिकअप नोंदी जोडा...',
                ),
                hintStyle: TextStyle(
                  color: secondaryTextColor,
                ),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // --------------------------------------------------
            // CONFIRMATION
            // --------------------------------------------------

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CheckboxListTile(
                value: confirmationChecked,
                onChanged: (value) {
                  setState(() {
                    confirmationChecked =
                        value ?? false;
                  });
                },
                activeColor: primaryColor,
                title: Text(
                  _text(
                    'I confirm that the e-waste has been collected.',
                    'मैं पुष्टि करता हूं कि ई-वेस्ट एकत्र कर लिया गया है।',
                    'मी पुष्टी करतो की ई-वेस्ट संकलित केला आहे.',
                  ),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                controlAffinity:
                    ListTileControlAffinity.leading,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // COMPLETE PICKUP
            // --------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: confirmationChecked &&
                        !isSubmitting
                    ? _completePickup
                    : null,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.check_circle_outline_rounded,
                      ),
                label: Text(
                  isSubmitting
                      ? _text(
                          'Saving pickup...',
                          'पिकअप सेव हो रहा है...',
                          'पिकअप सेव होत आहे...',
                        )
                      : _text(
                          'Complete pickup',
                          'पिकअप पूरा करें',
                          'पिकअप पूर्ण करा',
                        ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor:
                      primaryColor.withValues(alpha: 0.25),
                  foregroundColor: isDark
                      ? Colors.black
                      : Colors.white,
                  disabledForegroundColor:
                      isDark
                          ? Colors.white38
                          : Colors.black38,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
    required Color primaryColor,
  }) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 21,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
