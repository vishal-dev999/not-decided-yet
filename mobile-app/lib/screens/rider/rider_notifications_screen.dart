import 'dart:convert';

import 'package:flutter/material.dart';

import '../../constants/app_enums.dart';
import '../../models/rider_pickup.dart';
import '../../services/storage_service.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';

class RiderNotificationsScreen extends StatefulWidget {
  final AppLanguage language;
  final ReNovaThemeMode themeMode;
  final ReNovaStorage storage;
  final List<RiderPickup> assignedPickups;

  const RiderNotificationsScreen({
    super.key,
    required this.language,
    required this.themeMode,
    required this.storage,
    required this.assignedPickups,
  });

  @override
  State<RiderNotificationsScreen> createState() =>
      _RiderNotificationsScreenState();
}

class _RiderNotificationsScreenState
    extends State<RiderNotificationsScreen> {
  List<Map<String, dynamic>> _history = [];

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
    final raw = widget.storage.prefs.getString(
      'rider_pickup_history',
    );

    final history = <Map<String, dynamic>>[];

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              history.add(
                Map<String, dynamic>.from(item),
              );
            }
          }
        }
      } catch (_) {
        // Keep notifications usable if stored history is invalid.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _history = history;
    });
  }

  bool _isCompleted(String pickupId) {
    return _history.any(
      (item) =>
          item['pickupId']?.toString() == pickupId &&
          (item['status']?.toString().toLowerCase() ==
                  'completed' ||
              item['status']?.toString().toLowerCase() ==
                  'complete'),
    );
  }

  Map<String, dynamic>? _historyForPickup(
    String pickupId,
  ) {
    for (final item in _history) {
      if (item['pickupId']?.toString() == pickupId) {
        return item;
      }
    }

    return null;
  }

  bool _isCancelled(RiderPickup pickup) {
    if (pickup.status.toLowerCase() == 'cancelled' ||
        pickup.status.toLowerCase() == 'canceled') {
      return true;
    }

    final historyItem = _historyForPickup(pickup.id);

    if (historyItem == null) {
      return false;
    }

    final status =
        historyItem['status']?.toString().toLowerCase() ?? '';

    return status == 'cancelled' || status == 'canceled';
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        foregroundColor: textColor,
        title: Text(
          _text(
            'Notifications',
            'सूचनाएं',
            'सूचना',
          ),
          style: TextStyle(
            color: textColor,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _buildNotificationList(
        cardColor,
        primaryColor,
        textColor,
        secondaryTextColor,
      ),
    );
  }

  Widget _buildNotificationList(
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final notifications = <_RiderNotification>[];

    // ----------------------------------------------------------
    // COMPLETED + CANCELLED + PENDING NOTIFICATIONS
    // ----------------------------------------------------------

    for (final pickup in widget.assignedPickups) {
      final cancelled = _isCancelled(pickup);

      if (cancelled) {
        notifications.add(
          _RiderNotification(
            type: _NotificationType.cancelled,
            pickup: pickup,
          ),
        );
      } else if (_isCompleted(pickup.id)) {
        notifications.add(
          _RiderNotification(
            type: _NotificationType.completed,
            pickup: pickup,
          ),
        );
      } else {
        notifications.add(
          _RiderNotification(
            type: _NotificationType.pending,
            pickup: pickup,
          ),
        );
      }
    }

    if (notifications.isEmpty) {
      return _buildEmptyState(
        primaryColor,
        textColor,
        secondaryTextColor,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadHistory();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          8,
          18,
          24,
        ),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];

          return Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ),
            child: _buildNotificationCard(
              notification,
              cardColor,
              primaryColor,
              textColor,
              secondaryTextColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    _RiderNotification notification,
    Color cardColor,
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final pickup = notification.pickup;

    late IconData icon;
    late Color iconColor;
    late String title;
    late String message;

    switch (notification.type) {
      case _NotificationType.completed:
        icon = Icons.check_circle_rounded;
        iconColor = primaryColor;

        title = _text(
          'Pickup completed',
          'पिकअप पूरा हुआ',
          'पिकअप पूर्ण झाले',
        );

        message = _text(
          '${pickup.name} has been successfully completed.',
          '${pickup.name} का पिकअप सफलतापूर्वक पूरा हुआ।',
          '${pickup.name} चे पिकअप यशस्वीरित्या पूर्ण झाले.',
        );
        break;

      case _NotificationType.pending:
        icon = Icons.schedule_rounded;
        iconColor = Colors.orange;

        title = _text(
          'Pickup pending',
          'पिकअप बाकी है',
          'पिकअप बाकी आहे',
        );

        message = _text(
          '${pickup.name} is still waiting to be completed.',
          '${pickup.name} का पिकअप अभी पूरा होना बाकी है।',
          '${pickup.name} चे पिकअप अजून पूर्ण व्हायचे आहे.',
        );
        break;

      case _NotificationType.cancelled:
        icon = Icons.cancel_rounded;
        iconColor = Colors.redAccent;

        title = _text(
          'Pickup cancelled',
          'पिकअप रद्द हुआ',
          'पिकअप रद्द झाले',
        );

        message = _text(
          '${pickup.name} pickup has been cancelled.',
          '${pickup.name} का पिकअप रद्द कर दिया गया है।',
          '${pickup.name} चे पिकअप रद्द करण्यात आले आहे.',
        );
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: iconColor.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.11,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 9),

                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pickup.location,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 10.5,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pickup.time,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    Color primaryColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primaryColor.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: primaryColor,
                size: 35,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              _text(
                'No notifications',
                'कोई सूचना नहीं',
                'कोणतीही सूचना नाही',
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              _text(
                'You are all caught up.',
                'आप सभी सूचनाओं से अपडेट हैं।',
                'तुम्ही सर्व सूचनांसह अपडेट आहात.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NotificationType {
  completed,
  pending,
  cancelled,
}

class _RiderNotification {
  final _NotificationType type;
  final RiderPickup pickup;

  const _RiderNotification({
    required this.type,
    required this.pickup,
  });
}
