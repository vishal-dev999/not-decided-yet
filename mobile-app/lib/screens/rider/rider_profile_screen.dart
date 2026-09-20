import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_enums.dart';
import '../../services/storage_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';

class RiderProfileScreen extends StatefulWidget {
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final ReNovaStorage storage;
  final String riderName;
  final int completedPickups;

  // Sends the updated name back to the dashboard.
  final ValueChanged<String>? onRiderNameChanged;

  // Sends the updated profile image path back to the dashboard.
  final ValueChanged<String?>? onProfileImageChanged;

  const RiderProfileScreen({
    super.key,
    required this.language,
    required this.themeMode,
    required this.storage,
    required this.riderName,
    required this.completedPickups,
    this.onRiderNameChanged,
    this.onProfileImageChanged,
  });

  @override
  State<RiderProfileScreen> createState() =>
      _RiderProfileScreenState();
}

class _RiderProfileScreenState
    extends State<RiderProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _areaController;

  bool _isEditing = false;
  bool _isSaving = false;

  String? _profileImagePath;

  String _savedName = '';
  String _savedPhone = '';
  String _savedEmail = '';
  String _savedArea = '';

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
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _areaController = TextEditingController();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // SECTION C
  // Persistent profile storage.
  // ------------------------------------------------------------

  void _loadProfile() {
    final prefs = widget.storage.prefs;

    final storedName =
        prefs.getString('rider_profile_name');

    final storedPhone =
        prefs.getString('rider_profile_phone');

    final storedEmail =
        prefs.getString('rider_profile_email');

    final storedArea =
        prefs.getString('rider_profile_area');

    final storedImage =
        prefs.getString('rider_profile_image');

    _savedName =
        storedName?.trim().isNotEmpty == true
            ? storedName!.trim()
            : widget.riderName.trim();

    _savedPhone =
        storedPhone?.trim().isNotEmpty == true
            ? storedPhone!.trim()
            : '+91 98765 43210';

    _savedEmail =
        storedEmail?.trim().isNotEmpty == true
            ? storedEmail!.trim()
            : 'rider@renova.com';

    _savedArea =
        storedArea?.trim().isNotEmpty == true
            ? storedArea!.trim()
            : 'Bhubaneswar';

    _profileImagePath =
        storedImage?.trim().isNotEmpty == true
            ? storedImage!.trim()
            : null;

    _setControllersFromSavedData();
  }

  void _setControllersFromSavedData() {
    _nameController.text = _savedName;
    _phoneController.text = _savedPhone;
    _emailController.text = _savedEmail;
    _areaController.text = _savedArea;
  }

  // ------------------------------------------------------------
  // Enter edit mode.
  // ------------------------------------------------------------

  void _startEditing() {
    _setControllersFromSavedData();

    setState(() {
      _isEditing = true;
    });
  }

  // ------------------------------------------------------------
  // Cancel editing.
  // ------------------------------------------------------------

  void _cancelEditing() {
    _setControllersFromSavedData();

    setState(() {
      _isEditing = false;
    });
  }

  // ------------------------------------------------------------
  // Save profile.
  // ------------------------------------------------------------

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final area = _areaController.text.trim();

    if (name.isEmpty) {
      _showMessage(
        _text(
          'Please enter your name.',
          'कृपया अपना नाम दर्ज करें।',
          'कृपया तुमचे नाव टाका.',
        ),
      );
      return;
    }

    if (phone.isEmpty) {
      _showMessage(
        _text(
          'Please enter your phone number.',
          'कृपया अपना फोन नंबर दर्ज करें।',
          'कृपया तुमचा फोन नंबर टाका.',
        ),
      );
      return;
    }

    if (email.isEmpty) {
      _showMessage(
        _text(
          'Please enter your email.',
          'कृपया अपना ईमेल दर्ज करें।',
          'कृपया तुमचा ईमेल टाका.',
        ),
      );
      return;
    }

    if (area.isEmpty) {
      _showMessage(
        _text(
          'Please enter your assigned area.',
          'कृपया अपना निर्धारित क्षेत्र दर्ज करें।',
          'कृपया तुमचे नियुक्त क्षेत्र टाका.',
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.storage.prefs.setString(
        'rider_profile_name',
        name,
      );

      await widget.storage.prefs.setString(
        'rider_profile_phone',
        phone,
      );

      await widget.storage.prefs.setString(
        'rider_profile_email',
        email,
      );

      await widget.storage.prefs.setString(
        'rider_profile_area',
        area,
      );

      _savedName = name;
      _savedPhone = phone;
      _savedEmail = email;
      _savedArea = area;

      // Update dashboard name immediately.
      widget.onRiderNameChanged?.call(name);

      // Also send the current image path so the dashboard
      // remains synchronized with the profile.
      widget.onProfileImageChanged?.call(
        _profileImagePath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      _showMessage(
        _text(
          'Profile updated successfully.',
          'प्रोफ़ाइल सफलतापूर्वक अपडेट हो गई।',
          'प्रोफाइल यशस्वीरित्या अपडेट झाले.',
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        _text(
          'Unable to save profile. Please try again.',
          'प्रोफ़ाइल सेव नहीं हो सकी। कृपया फिर कोशिश करें।',
          'प्रोफाइल सेव करता आले नाही. कृपया पुन्हा प्रयत्न करा.',
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // PROFILE PHOTO
  // ------------------------------------------------------------

  Future<void> _pickProfilePhoto() async {
    if (_isSaving) {
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile == null) {
        return;
      }

      await widget.storage.prefs.setString(
        'rider_profile_image',
        pickedFile.path,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profileImagePath = pickedFile.path;
      });

      // Immediately notify dashboard.
      widget.onProfileImageChanged?.call(
        pickedFile.path,
      );

      _showMessage(
        _text(
          'Profile photo updated.',
          'प्रोफ़ाइल फोटो अपडेट हो गई।',
          'प्रोफाइल फोटो अपडेट झाला.',
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _text(
          'Unable to update profile photo.',
          'प्रोफ़ाइल फोटो अपडेट नहीं हो सकी।',
          'प्रोफाइल फोटो अपडेट करता आली नाही.',
        ),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    await widget.storage.prefs.remove(
      'rider_profile_image',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _profileImagePath = null;
    });

    // Immediately notify dashboard that the photo was removed.
    widget.onProfileImageChanged?.call(null);

    _showMessage(
      _text(
        'Profile photo removed.',
        'प्रोफ़ाइल फोटो हटा दी गई।',
        'प्रोफाइल फोटो काढून टाकला.',
      ),
    );
  }

  void _showPhotoOptions() {
    if (_isSaving) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark =
            widget.themeMode == ReNovaThemeMode.dark;

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
            : AppColors.lightText.withValues(
                alpha: 0.62,
              );

        return Container(
          padding: const EdgeInsets.fromLTRB(
            18,
            14,
            18,
            24,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: secondaryTextColor
                        .withValues(alpha: 0.25),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _text(
                    'Profile photo',
                    'प्रोफ़ाइल फोटो',
                    'प्रोफाइल फोटो',
                  ),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _text(
                    'Choose how you want to update your photo.',
                    'चुनें कि आप फोटो कैसे अपडेट करना चाहते हैं।',
                    'तुमचा फोटो कसा अपडेट करायचा ते निवडा.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 17),
                _photoOption(
                  icon: Icons.photo_library_outlined,
                  title: _text(
                    'Choose from gallery',
                    'गैलरी से चुनें',
                    'गॅलरीमधून निवडा',
                  ),
                  primaryColor: primaryColor,
                  textColor: textColor,
                  secondaryTextColor:
                      secondaryTextColor,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickProfilePhoto();
                  },
                ),
                if (_profileImagePath != null) ...[
                  const SizedBox(height: 8),
                  _photoOption(
                    icon: Icons.delete_outline_rounded,
                    title: _text(
                      'Remove photo',
                      'फोटो हटाएं',
                      'फोटो काढा',
                    ),
                    primaryColor: Colors.redAccent,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _removeProfilePhoto();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _photoOption({
    required IconData icon,
    required String title,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withValues(
              alpha: 0.12,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryColor.withValues(
                  alpha: 0.10,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: secondaryTextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

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
        : AppColors.lightText.withValues(
            alpha: 0.62,
          );

    final displayName =
        _savedName.trim().isEmpty
            ? _text(
                'Rider',
                'राइडर',
                'राइडर',
              )
            : _savedName.trim();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: textColor,
        title: Text(
          _text(
            'My Profile',
            'मेरी प्रोफ़ाइल',
            'माझे प्रोफाइल',
          ),
          style: TextStyle(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (!_isEditing)
            Padding(
              padding: const EdgeInsets.only(
                right: 8,
              ),
              child: IconButton(
                onPressed: _startEditing,
                tooltip: _text(
                  'Edit profile',
                  'प्रोफ़ाइल संपादित करें',
                  'प्रोफाइल संपादित करा',
                ),
                icon: Icon(
                  Icons.edit_outlined,
                  color: primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          30,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                22,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius:
                    BorderRadius.circular(24),
                border: Border.all(
                  color: primaryColor.withValues(
                    alpha: 0.12,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.10 : 0.04,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 98,
                          height: 98,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor
                                .withValues(
                              alpha: 0.12,
                            ),
                            border: Border.all(
                              color: primaryColor
                                  .withValues(
                                alpha: 0.22,
                              ),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: _profileImagePath !=
                                        null &&
                                    File(
                                      _profileImagePath!,
                                    ).existsSync()
                                ? Image.file(
                                    File(
                                      _profileImagePath!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    color: primaryColor,
                                    size: 50,
                                  ),
                          ),
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cardColor,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (_isEditing)
                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        hintText: _text(
                          'Rider name',
                          'राइडर का नाम',
                          'रायडरचे नाव',
                        ),
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                      ),
                    )
                  else
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                  const SizedBox(height: 4),

                  Text(
                    _text(
                      'Pickup Rider',
                      'पिकअप राइडर',
                      'पिकअप रायडर',
                    ),
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_isEditing)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isSaving
                                    ? null
                                    : _cancelEditing,
                            style:
                                OutlinedButton.styleFrom(
                              foregroundColor:
                                  secondaryTextColor,
                              side: BorderSide(
                                color:
                                    secondaryTextColor
                                        .withValues(
                                  alpha: 0.25,
                                ),
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(13),
                              ),
                            ),
                            child: Text(
                              _text(
                                'Cancel',
                                'रद्द करें',
                                'रद्द करा',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isSaving
                                    ? null
                                    : _saveProfile,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .check_rounded,
                                    size: 17,
                                  ),
                            label: Text(
                              _isSaving
                                  ? _text(
                                      'Saving',
                                      'सेव हो रहा है',
                                      'सेव होत आहे',
                                    )
                                  : _text(
                                      'Save',
                                      'सेव करें',
                                      'सेव करा',
                                    ),
                            ),
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  primaryColor,
                              foregroundColor:
                                  Colors.white,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: _startEditing,
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 17,
                        ),
                        label: Text(
                          _text(
                            'Edit Profile',
                            'प्रोफ़ाइल संपादित करें',
                            'प्रोफाइल संपादित करा',
                          ),
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              primaryColor,
                          side: BorderSide(
                            color:
                                primaryColor
                                    .withValues(
                              alpha: 0.35,
                            ),
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              13,
                            ),
                          ),
                          textStyle:
                              const TextStyle(
                            fontSize: 12.5,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _sectionTitle(
              _text(
                'Account details',
                'खाता विवरण',
                'खाते तपशील',
              ),
              textColor,
            ),

            const SizedBox(height: 9),

            if (_isEditing) ...[
              _editableTile(
                cardColor: cardColor,
                primaryColor: primaryColor,
                textColor: textColor,
                secondaryTextColor:
                    secondaryTextColor,
                icon: Icons.phone_outlined,
                title: _text(
                  'Phone number',
                  'फ़ोन नंबर',
                  'फोन नंबर',
                ),
                controller: _phoneController,
                keyboardType:
                    TextInputType.phone,
              ),
              const SizedBox(height: 8),
              _editableTile(
                cardColor: cardColor,
                primaryColor: primaryColor,
                textColor: textColor,
                secondaryTextColor:
                    secondaryTextColor,
                icon: Icons.email_outlined,
                title: _text(
                  'Email',
                  'ईमेल',
                  'ईमेल',
                ),
                controller: _emailController,
                keyboardType:
                    TextInputType.emailAddress,
              ),
            ] else ...[
              _detailTile(
                cardColor: cardColor,
                primaryColor: primaryColor,
                textColor: textColor,
                secondaryTextColor:
                    secondaryTextColor,
                icon: Icons.badge_outlined,
                title: _text(
                  'Rider ID',
                  'राइडर आईडी',
                  'राइडर आयडी',
                ),
                value: 'RIDER-001',
              ),
              const SizedBox(height: 8),
              _detailTile(
                cardColor: cardColor,
                primaryColor: primaryColor,
                textColor: textColor,
                secondaryTextColor:
                    secondaryTextColor,
                icon: Icons.phone_outlined,
                title: _text(
                  'Phone number',
                  'फ़ोन नंबर',
                  'फोन नंबर',
                ),
                value: _savedPhone,
              ),
              const SizedBox(height: 8),
              _detailTile(
                cardColor: cardColor,
                primaryColor: primaryColor,
                textColor: textColor,
                secondaryTextColor:
                    secondaryTextColor,
                icon: Icons.email_outlined,
                title: _text(
                  'Email',
                  'ईमेल',
                  'ईमेल',
                ),
                value: _savedEmail,
              ),
            ],

            const SizedBox(height: 14),

            _sectionTitle(
              _text(
                'Work details',
                'कार्य विवरण',
                'कामाचे तपशील',
              ),
              textColor,
            ),

            const SizedBox(height: 9),

            _detailTile(
              cardColor: cardColor,
              primaryColor: primaryColor,
              textColor: textColor,
              secondaryTextColor:
                  secondaryTextColor,
              icon: Icons.business_outlined,
              title: _text(
                'Recycler company',
                'रीसायक्लर कंपनी',
                'रीसायक्लर कंपनी',
              ),
              value: 'ReNova Recycling',
            ),

            const SizedBox(height: 8),

            if (_isEditing)
              _editableTile(
                cardColor: cardColor,
                primaryColor: primaryColor,
                textColor: textColor,
                secondaryTextColor:
                    secondaryTextColor,
                icon: Icons.location_on_outlined,
                title: _text(
                  'Assigned area',
                  'निर्धारित क्षेत्र',
                  'नियुक्त क्षेत्र',
                ),
                controller: _areaController,
              )
            else
              _detailTile(
                cardColor: cardColor,
                primaryColor: primaryColor,
                textColor: textColor,
                secondaryTextColor:
                    secondaryTextColor,
                icon: Icons.location_on_outlined,
                title: _text(
                  'Assigned area',
                  'निर्धारित क्षेत्र',
                  'नियुक्त क्षेत्र',
                ),
                value: _savedArea,
              ),

            const SizedBox(height: 8),

            _detailTile(
              cardColor: cardColor,
              primaryColor: primaryColor,
              textColor: textColor,
              secondaryTextColor:
                  secondaryTextColor,
              icon:
                  Icons.check_circle_outline_rounded,
              title: _text(
                'Completed pickups',
                'पूर्ण किए गए पिकअप',
                'पूर्ण झालेले पिकअप',
              ),
              value:
                  widget.completedPickups.toString(),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: primaryColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: primaryColor.withValues(
                    alpha: 0.13,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text(
                            'Account active',
                            'खाता सक्रिय है',
                            'खाते सक्रिय आहे',
                          ),
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12.5,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _text(
                            'You are currently assigned as a pickup rider.',
                            'आप वर्तमान में पिकअप राइडर के रूप में नियुक्त हैं।',
                            'तुम्ही सध्या पिकअप रायडर म्हणून नियुक्त आहात.',
                          ),
                          style: TextStyle(
                            color:
                                secondaryTextColor,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    Color textColor,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _detailTile({
    required Color cardColor,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryTextColor,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableTile({
    required Color cardColor,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryTextColor,
    required IconData icon,
    required String title,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        11,
        14,
        11,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(
                color: textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                labelText: title,
                labelStyle: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 10.5,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
