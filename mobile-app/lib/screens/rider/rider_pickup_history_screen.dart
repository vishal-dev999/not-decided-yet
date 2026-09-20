import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../constants/app_enums.dart';
import '../../services/storage_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';

class RiderPickupHistoryScreen extends StatefulWidget {
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final Future<void> Function(ReNovaThemeMode) onThemeChanged;
  final ReNovaStorage storage;

  const RiderPickupHistoryScreen({
    super.key,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
    required this.storage,
  });

  @override
  State<RiderPickupHistoryScreen> createState() =>
      _RiderPickupHistoryScreenState();
}

class _RiderPickupHistoryScreenState
    extends State<RiderPickupHistoryScreen> {
  List<Map<String, dynamic>> pickups = [];

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
    _loadHistory();
  }

  void _loadHistory() {
    final raw =
        widget.storage.prefs.getString(
      'rider_pickup_history',
    );

    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        setState(() {
          pickups = decoded
              .map(
                (item) =>
                    Map<String, dynamic>.from(
                  item as Map,
                ),
              )
              .toList();
        });
      }
    } catch (_) {
      setState(() {
        pickups = [];
      });
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return '';
    }

    final local = date.toLocal();

    final day =
        local.day.toString().padLeft(2, '0');
    final month =
        local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;

    final minute =
        local.minute.toString().padLeft(2, '0');

    final period =
        local.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year • $hour:$minute $period';
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
        : AppColors.lightText.withValues(
            alpha: 0.65,
          );

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        title: Text(
          _text(
            'Completed pickups',
            'पूर्ण किए गए पिकअप',
            'पूर्ण झालेले पिकअप',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: pickups.isEmpty
          ? Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color:
                            primaryColor.withValues(
                          alpha: 0.10,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: primaryColor,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _text(
                        'No completed pickups yet',
                        'अभी कोई पूर्ण पिकअप नहीं है',
                        'अजून कोणतेही पूर्ण पिकअप नाहीत',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _text(
                        'Your completed collections will appear here.',
                        'आपके पूर्ण किए गए कलेक्शन यहां दिखाई देंगे।',
                        'तुमचे पूर्ण झालेले संकलन येथे दिसतील.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                12,
                20,
                30,
              ),
              itemCount: pickups.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pickup = pickups[index];

                final weight =
                    pickup['weight'];

                final notes =
                    pickup['notes']
                        ?.toString()
                        .trim();

                final imagePath =
                    pickup['proofImagePath']
                        ?.toString();

                return Container(
                  padding:
                      const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration:
                                BoxDecoration(
                              color: primaryColor
                                  .withValues(
                                alpha: 0.10,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                            child: Icon(
                              Icons
                                  .check_circle_rounded,
                              color:
                                  primaryColor,
                              size: 25,
                            ),
                          ),

                          const SizedBox(width: 13),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  pickup[
                                          'collectionPoint'] ??
                                      'Collection point',
                                  style: TextStyle(
                                    color:
                                        textColor,
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  _formatDate(
                                    pickup[
                                        'completedAt'],
                                  ),
                                  style: TextStyle(
                                    color:
                                        secondaryTextColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration:
                                BoxDecoration(
                              color: primaryColor
                                  .withValues(
                                alpha: 0.10,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),
                            ),
                            child: Text(
                              _text(
                                'Completed',
                                'पूर्ण',
                                'पूर्ण',
                              ),
                              style: TextStyle(
                                color:
                                    primaryColor,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child:
                                _infoItem(
                              icon:
                                  Icons.scale_outlined,
                              label: _text(
                                'Weight',
                                'वजन',
                                'वजन',
                              ),
                              value:
                                  '${weight ?? '-'} kg',
                              textColor:
                                  textColor,
                              secondaryTextColor:
                                  secondaryTextColor,
                              primaryColor:
                                  primaryColor,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child:
                                _infoItem(
                              icon: Icons
                                  .location_on_outlined,
                              label: _text(
                                'Location',
                                'स्थान',
                                'स्थान',
                              ),
                              value:
                                  pickup['location'] ??
                                      'Bhubaneswar',
                              textColor:
                                  textColor,
                              secondaryTextColor:
                                  secondaryTextColor,
                              primaryColor:
                                  primaryColor,
                            ),
                          ),
                        ],
                      ),

                      if (notes != null &&
                          notes.isNotEmpty) ...[
                        const SizedBox(
                          height: 15,
                        ),
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(12),
                          decoration:
                              BoxDecoration(
                            color:
                                backgroundColor,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              13,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Icon(
                                Icons
                                    .notes_outlined,
                                size: 18,
                                color:
                                    secondaryTextColor,
                              ),
                              const SizedBox(
                                width: 9,
                              ),
                              Expanded(
                                child: Text(
                                  notes,
                                  style:
                                      TextStyle(
                                    color:
                                        secondaryTextColor,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (imagePath != null &&
                          imagePath.isNotEmpty &&
                          File(imagePath)
                              .existsSync()) ...[
                        const SizedBox(
                          height: 15,
                        ),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 150,
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
    required Color primaryColor,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color:
                        secondaryTextColor,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
