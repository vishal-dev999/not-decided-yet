import 'dart:convert';

import 'package:flutter/material.dart';

import 'rider_notifications_screen.dart';
import 'rider_profile_screen.dart';
import '../../constants/app_enums.dart';
import '../../models/rider_pickup.dart';
import '../../services/storage_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';
import '../../screens/rider/rider_dashboard_header.dart';
import 'rider_pickup_details_screen.dart';
import 'rider_pickup_history_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final Future<void> Function(ReNovaThemeMode) onThemeChanged;
  final ReNovaStorage storage;
  final String riderName;

  const RiderDashboardScreen({
    super.key,
    required this.language,
    required this.themeMode,
    required this.onThemeChanged,
    required this.storage,
    required this.riderName,
  });

  @override
  State<RiderDashboardScreen> createState() =>
      _RiderDashboardScreenState();
}

class _RiderDashboardScreenState
    extends State<RiderDashboardScreen> {
  int completedPickups = 0;
  int selectedTab = 0;

  late String _currentRiderName;
  String? _currentProfileImagePath;

  final List<RiderPickup> _assignedPickups =
      RiderPickup.assignedPickups;

  final Set<String> _completedPickupIds = <String>{};

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

    _currentRiderName =
        widget.storage.prefs.getString(
              'rider_profile_name',
            )?.trim().isNotEmpty ==
            true
        ? widget.storage.prefs
              .getString('rider_profile_name')!
              .trim()
        : widget.riderName;

    _currentProfileImagePath =
        widget.storage.prefs.getString(
          'rider_profile_image',
        );

    _loadPickupStatus();
  }

  void _loadPickupStatus() {
    final historyRaw = widget.storage.prefs.getString(
      'rider_pickup_history',
    );

    final completedIds = <String>{};

    if (historyRaw != null && historyRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(historyRaw);

        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final pickupId =
                  item['pickupId']?.toString().trim() ?? '';

              if (pickupId.isNotEmpty) {
                completedIds.add(pickupId);
              }
            }
          }
        }
      } catch (_) {
        // Keep the dashboard usable if stored history is invalid.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _completedPickupIds
        ..clear()
        ..addAll(completedIds);

      completedPickups = _completedPickupIds.length;
    });
  }

  List<RiderPickup> get _activePickups {
    return _assignedPickups
        .where(
          (pickup) =>
              !_completedPickupIds.contains(pickup.id),
        )
        .toList();
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiderPickupHistoryScreen(
          language: widget.language,
          themeMode: widget.themeMode,
          onThemeChanged: widget.onThemeChanged,
          storage: widget.storage,
        ),
      ),
    );

    _loadPickupStatus();
  }

  Future<void> _openPickup(
    RiderPickup pickup,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiderPickupDetailsScreen(
          language: widget.language,
          themeMode: widget.themeMode,
          onThemeChanged: widget.onThemeChanged,
          storage: widget.storage,
          pickup: pickup,
        ),
      ),
    );

    _loadPickupStatus();
  }

  void _selectTab(int index) {
    setState(() {
      selectedTab = index;
    });

    if (index == 2) {
      _openHistory();
    }
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiderNotificationsScreen(
          language: widget.language,
          themeMode: widget.themeMode,
          storage: widget.storage,
          assignedPickups: _assignedPickups,
        ),
      ),
    );
  }

  void _openProfileFromHeader() {
    setState(() {
      selectedTab = 3;
    });
  }

  // ------------------------------------------------------------
  // PROFILE UPDATE CALLBACKS
  // ------------------------------------------------------------

  void _handleRiderNameChanged(String newName) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentRiderName = newName;
    });
  }

  void _handleProfileImageChanged(String? imagePath) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentProfileImagePath = imagePath;
    });
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
            alpha: 0.62,
          );

    final activePickups = _activePickups;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: selectedTab == 2 ? 0 : selectedTab,
          children: [
            _buildHome(
              backgroundColor,
              cardColor,
              primaryColor,
              textColor,
              secondaryTextColor,
              activePickups,
            ),
            _buildPickupList(
              cardColor,
              primaryColor,
              textColor,
              secondaryTextColor,
            ),
            const SizedBox(),

            RiderProfileScreen(
              language: widget.language,
              themeMode: widget.themeMode,
              storage: widget.storage,
              riderName: _currentRiderName,
              completedPickups: completedPickups,
              onRiderNameChanged:
                  _handleRiderNameChanged,
              onProfileImageChanged:
                  _handleProfileImageChanged,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(
        cardColor,
        primaryColor,
        textColor,
        secondaryTextColor,
      ),
    );
  }

  Widget _buildHome(
    Color backgroundColor,
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
    List<RiderPickup> activePickups,
  ) {
    final nextPickup =
        activePickups.isNotEmpty ? activePickups.first : null;

    return RefreshIndicator(
      onRefresh: () async {
        _loadPickupStatus();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          14,
          18,
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RiderDashboardHeader(
              riderName: _currentRiderName,
              profileImagePath: _currentProfileImagePath,
              language: widget.language,
              themeMode: widget.themeMode,
              onProfileTap: _openProfileFromHeader,
              onNotificationTap: _openNotifications,
            ),

            const SizedBox(height: 18),

            _buildTodayStatusCard(
              cardColor,
              primaryColor,
              textColor,
              secondaryTextColor,
              activePickups.length,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's pickups",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedTab = 1;
                    });
                  },
                  child: Text(
                    _text(
                      'View all',
                      'सभी देखें',
                      'सर्व पहा',
                    ),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (nextPickup != null)
              _buildPickupCard(
                pickup: nextPickup,
                cardColor: cardColor,
                primaryColor: primaryColor,
                textColor: textColor,
                secondaryTextColor:
                    secondaryTextColor,
                isNext: true,
              )
            else
              _buildEmptyPickupCard(
                cardColor,
                primaryColor,
                textColor,
                secondaryTextColor,
              ),

            if (activePickups.length > 1) ...[
              const SizedBox(height: 12),
              _buildMiniPickupPreview(
                activePickups
                    .skip(1)
                    .take(2)
                    .toList(),
                cardColor,
                primaryColor,
                textColor,
                secondaryTextColor,
              ),
            ],

            const SizedBox(height: 22),

            Text(
              _text(
                "Today's overview",
                'आज का अवलोकन',
                'आजचा आढावा',
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    cardColor: cardColor,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    icon: Icons.assignment_outlined,
                    value: activePickups.length
                        .toString()
                        .padLeft(2, '0'),
                    label: _text(
                      'Assigned',
                      'निर्धारित',
                      'नियुक्त',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    cardColor: cardColor,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    icon:
                        Icons.check_circle_outline_rounded,
                    value: completedPickups
                        .toString()
                        .padLeft(2, '0'),
                    label: _text(
                      'Completed',
                      'पूर्ण',
                      'पूर्ण',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _summaryCard(
                    cardColor: cardColor,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    icon: Icons.route_rounded,
                    value: activePickups.length
                        .toString()
                        .padLeft(2, '0'),
                    label: _text(
                      'Remaining',
                      'शेष',
                      'उर्वरित',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Text(
              _text(
                'Quick actions',
                'त्वरित कार्य',
                'जलद कृती',
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 10),

            _actionTile(
              cardColor: cardColor,
              textColor: textColor,
              secondaryTextColor:
                  secondaryTextColor,
              primaryColor: primaryColor,
              icon: Icons.route_rounded,
              title: _text(
                'Pickup route',
                'पिकअप मार्ग',
                'पिकअप मार्ग',
              ),
              subtitle: _text(
                'View your route and pickup locations',
                'अपना मार्ग और पिकअप स्थान देखें',
                'तुमचा मार्ग आणि पिकअप ठिकाणे पहा',
              ),
              onTap: () {
                setState(() {
                  selectedTab = 1;
                });
              },
            ),

            const SizedBox(height: 8),

            _actionTile(
              cardColor: cardColor,
              textColor: textColor,
              secondaryTextColor:
                  secondaryTextColor,
              primaryColor: primaryColor,
              icon: Icons.history_rounded,
              title: _text(
                'Completed pickups',
                'पूर्ण किए गए पिकअप',
                'पूर्ण झालेले पिकअप',
              ),
              subtitle: _text(
                'View your completed collection history',
                'अपने पूर्ण पिकअप का इतिहास देखें',
                'तुमचा पूर्ण पिकअप इतिहास पहा',
              ),
              onTap: _openHistory,
            ),

            const SizedBox(height: 8),

            _actionTile(
              cardColor: cardColor,
              textColor: textColor,
              secondaryTextColor:
                  secondaryTextColor,
              primaryColor: primaryColor,
              icon: Icons.support_agent_rounded,
              title: _text(
                'Need help?',
                'मदद चाहिए?',
                'मदत हवी आहे?',
              ),
              subtitle: _text(
                'Contact your recycler company',
                'अपनी रीसायक्लर कंपनी से संपर्क करें',
                'तुमच्या रीसायक्लर कंपनीशी संपर्क करा',
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard(
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
    int remaining,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(
              alpha: 0.18,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              remaining > 0
                  ? Icons.local_shipping_outlined
                  : Icons.check_circle_outline,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  remaining > 0
                      ? _text(
                          'You have $remaining pickups today',
                          'आज आपके पास $remaining पिकअप हैं',
                          'आज तुमच्याकडे $remaining पिकअप आहेत',
                        )
                      : _text(
                          'All pickups completed',
                          'सभी पिकअप पूरे हुए',
                          'सर्व पिकअप पूर्ण झाले',
                        ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining > 0
                      ? _text(
                          'Stay on schedule and collect responsibly.',
                          'समय पर रहें और जिम्मेदारी से संग्रह करें।',
                          'वेळापत्रकानुसार जबाबदारीने संकलन करा.',
                        )
                      : _text(
                          'Great work for today.',
                          'आज का काम बहुत अच्छा रहा।',
                          'आजचे काम छान झाले.',
                        ),
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.82,
                    ),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupList(
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final activePickups = _activePickups;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        18,
        6,
        18,
        20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            _text(
              'Assigned pickups',
              'निर्धारित पिकअप',
              'नियुक्त पिकअप',
            ),
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _text(
              '${activePickups.length} collection points assigned for today',
              'आज के लिए ${activePickups.length} संग्रह स्थान निर्धारित हैं',
              'आज ${activePickups.length} संकलन ठिकाणे नियुक्त आहेत',
            ),
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          if (activePickups.isEmpty)
            _buildEmptyPickupCard(
              cardColor,
              primaryColor,
              textColor,
              secondaryTextColor,
            )
          else
            ...activePickups.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final pickup = entry.value;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index ==
                            activePickups.length - 1
                        ? 0
                        : 12,
                  ),
                  child: _buildPickupCard(
                    pickup: pickup,
                    cardColor: cardColor,
                    primaryColor: primaryColor,
                    textColor: textColor,
                    secondaryTextColor:
                        secondaryTextColor,
                    isNext: index == 0,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPickupCard({
    required RiderPickup pickup,
    required Color cardColor,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryTextColor,
    required bool isNext,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isNext
            ? Border.all(
                color: primaryColor.withValues(
                  alpha: 0.35,
                ),
                width: 1.2,
              )
            : null,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: primaryColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pickup.name,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isNext)
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor
                                  .withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                            child: Text(
                              _text(
                                'NEXT',
                                'अगला',
                                'पुढील',
                              ),
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 8,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pickup.person,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: primaryColor.withValues(
                alpha: 0.055,
              ),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 17,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    pickup.address,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11.5,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              _pickupInfo(
                Icons.schedule_rounded,
                pickup.time,
                textColor,
                secondaryTextColor,
              ),
              const SizedBox(width: 17),
              _pickupInfo(
                Icons.directions_car_outlined,
                pickup.distance,
                textColor,
                secondaryTextColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton(
              onPressed: () => _openPickup(pickup),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    _text(
                      'View pickup',
                      'पिकअप देखें',
                      'पिकअप पहा',
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPickupPreview(
    List<RiderPickup> pickups,
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Column(
      children: pickups.map((pickup) {
        return Padding(
          padding: const EdgeInsets.only(
            bottom: 8,
          ),
          child: InkWell(
            borderRadius:
                BorderRadius.circular(16),
            onTap: () {
              _openPickup(pickup);
            },
            child: Container(
              padding:
                  const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primaryColor
                          .withValues(
                        alpha: 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: primaryColor,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickup.name,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12.5,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pickup.location} • ${pickup.distance}',
                          style: TextStyle(
                            color:
                                secondaryTextColor,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    pickup.time,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 10.5,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: secondaryTextColor,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyPickupCard(
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.task_alt_rounded,
            color: primaryColor,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            _text(
              'All pickups completed',
              'सभी पिकअप पूरे हुए',
              'सर्व पिकअप पूर्ण झाले',
            ),
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _text(
              'You are all done for today.',
              'आज का आपका काम पूरा हो गया।',
              'आजचे तुमचे काम पूर्ण झाले.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickupInfo(
    IconData icon,
    String value,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: secondaryTextColor,
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: secondaryTextColor,
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color primaryColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(17),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius:
              BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: primaryColor.withValues(
                  alpha: 0.11,
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
                      color: textColor,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          secondaryTextColor,
                      fontSize: 10.5,
                    ),
                  ),
                ],
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

  Widget _buildBottomNavigationBar(
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          10,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius:
              BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.07,
              ),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            _bottomNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: _text(
                'Home',
                'होम',
                'होम',
              ),
              primaryColor: primaryColor,
              textColor: textColor,
              secondaryTextColor:
                  secondaryTextColor,
            ),
            _bottomNavItem(
              index: 1,
              icon: Icons.location_on_outlined,
              activeIcon:
                  Icons.location_on_rounded,
              label: _text(
                'Pickups',
                'पिकअप',
                'पिकअप',
              ),
              primaryColor: primaryColor,
              textColor: textColor,
              secondaryTextColor:
                  secondaryTextColor,
            ),
            _bottomNavItem(
              index: 2,
              icon: Icons.history_outlined,
              activeIcon: Icons.history_rounded,
              label: _text(
                'History',
                'इतिहास',
                'इतिहास',
              ),
              primaryColor: primaryColor,
              textColor: textColor,
              secondaryTextColor:
                  secondaryTextColor,
            ),
            _bottomNavItem(
              index: 3,
              icon:
                  Icons.person_outline_rounded,
              activeIcon:
                  Icons.person_rounded,
              label: _text(
                'Profile',
                'प्रोफ़ाइल',
                'प्रोफाइल',
              ),
              primaryColor: primaryColor,
              textColor: textColor,
              secondaryTextColor:
                  secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color primaryColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectTab(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding:
              const EdgeInsets.symmetric(
            vertical: 7,
            horizontal: 5,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(
                    alpha: 0.12,
                  )
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 180,
                ),
                child: Icon(
                  isSelected
                      ? activeIcon
                      : icon,
                  key: ValueKey(
                    isSelected,
                  ),
                  size: 21,
                  color: isSelected
                      ? primaryColor
                      : secondaryTextColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? primaryColor
                      : secondaryTextColor,
                  fontSize: 9.5,
                  fontWeight: isSelected
                      ? FontWeight.w800
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
