import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../constants/app_enums.dart';
import '../../services/database_helper.dart';
import '../../services/local_ai_classifier.dart';
import '../../services/storage_service.dart';
import '../../services/sync_service.dart';
import '../../services/sync_worker.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';
import '../classify_bulk_screen.dart';

class PickupTab extends StatefulWidget {
  final ReNovaStorage? storage;
  final AppLanguage language;

  const PickupTab({super.key, this.storage, required this.language});

  @override
  State<PickupTab> createState() => _PickupTabState();
}

class _PickupTabState extends State<PickupTab> {
  List<Map<String, dynamic>> _lots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLots();

    // Listen to background sync updates from SyncWorker
    SyncWorker.latestLotsNotifier.addListener(_onSyncWorkerUpdate);
  }

  @override
  void dispose() {
    SyncWorker.latestLotsNotifier.removeListener(_onSyncWorkerUpdate);
    super.dispose();
  }

  void _onSyncWorkerUpdate() {
    final remote = SyncWorker.latestLotsNotifier.value;
    if (remote.isNotEmpty && mounted) {
      setState(() {
        _lots = remote;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCancelLot(Map<String, dynamic> lot) async {
    final status = (lot['status'] ?? 'PENDING').toString().toUpperCase();
    final clientUid = (lot['client_lot_id'] ?? lot['lot_uid'] ?? '').toString();
    final backendId = (lot['id'] ?? '').toString();
    final targetUid = clientUid.isNotEmpty ? clientUid : backendId;

    // Prevent cancellation once physical weighing begins
    if (status == 'SESSION_OPEN' || status == 'VERIFIED_COMPLETED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Cannot cancel lot during or after weigh-in',
              'तौल के दौरान या बाद में लॉट रद्द नहीं कर सकते',
              'वजन सुरू असताना किंवा नंतर लॉट रद्द करू शकत नाही',
            ),
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_t('Cancel Lot?', 'लॉट रद्द करें?', 'लॉट रद्द करायचा?')),
        content: Text(
          status == 'LOCKED'
              ? _t(
                  'A recycler has already accepted this lot. Are you sure you want to cancel the pickup?',
                  'एक रिसाइकिलर ने पहले ही यह लॉट स्वीकार कर लिया है। क्या आप वाकई पिकअप रद्द करना चाहते हैं?',
                  'एका रिसायकलरने हा लॉट आधीच स्वीकारला आहे. तुम्हाला खात्री आहे की तुम्ही पिकअप रद्द करू इच्छिता?',
                )
              : _t(
                  'Are you sure you want to cancel and remove this lot?',
                  'क्या आप वाकई इस लॉट को रद्द और हटाना चाहते हैं?',
                  'तुम्हाला खात्री आहे की तुम्ही हा लॉट रद्द आणि काढून टाकू इच्छिता?',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('Keep Lot', 'रखें', 'ठेवा')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('Yes, Cancel', 'हाँ, रद्द करें', 'होय, रद्द करा')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;

      if (status == 'PENDING') {
        // Offline lot: purge directly from local SQLite
        await db.delete(
          'sync_queue',
          where: 'lot_uid = ? OR lot_uid = ?',
          whereArgs: [clientUid, targetUid],
        );
      } else {
        // Online synced lot: notify backend
        final storage = widget.storage ?? getStorage(context);
        final cancelTarget = backendId.isNotEmpty ? backendId : targetUid;

        if (storage.accessToken != null && storage.accessToken!.isNotEmpty) {
          await SyncService.cancelLot(storage: storage, lotId: cancelTarget);
        }

        // Drop from local SQLite cache so it disappears immediately
        await db.delete(
          'sync_queue',
          where: 'lot_uid = ? OR lot_uid = ?',
          whereArgs: [clientUid, targetUid],
        );
      }
    } catch (e) {
      debugPrint('[PickupTab] Error canceling lot: $e');
    }

    await _loadLots();
  }

  Future<void> _loadLots() async {
    setState(() => _isLoading = true);

    // 1. Instant load from SQLite (Fast & offline-safe)
    List<Map<String, dynamic>> localQueued = [];
    try {
      localQueued = await DatabaseHelper.instance.getQueuedLots(limit: 50);
      if (mounted) {
        setState(() {
          _lots = localQueued.where((lot) {
            final s = (lot['status'] ?? '').toString().toUpperCase();
            return s != 'CANCELLED' && s != 'WITHDRAWN' && s != 'ARCHIVED';
          }).toList();
        });
      }
    } catch (_) {}

    // 2. Resolve storage instance safely
    final storage = widget.storage ?? getStorage(context);

    // 3. Fetch from backend and reconcile local view
    if (storage.accessToken != null && storage.accessToken!.isNotEmpty) {
      try {
        final remote = await SyncService.fetchCollectorLots(storage: storage);

        if (mounted) {
          // Keep local PENDING lots that haven't reached the server yet
          final unsyncedLocal = localQueued.where((lot) {
            final s = (lot['status'] ?? '').toString().toUpperCase();
            return s == 'PENDING';
          }).toList();

          // Filter out CANCELLED / ARCHIVED records from remote
          final activeRemote = remote.where((lot) {
            final s = (lot['status'] ?? '').toString().toUpperCase();
            return s != 'CANCELLED' && s != 'WITHDRAWN' && s != 'ARCHIVED';
          }).toList();

          // Merge without duplicates (favoring fresh remote data)
          final activeUids = activeRemote
              .map(
                (r) => (r['client_lot_id'] ?? r['lot_uid'] ?? r['id'] ?? '')
                    .toString(),
              )
              .toSet();

          final merged = [
            ...unsyncedLocal.where((l) {
              final uid = (l['client_lot_id'] ?? l['lot_uid'] ?? l['id'] ?? '')
                  .toString();
              return !activeUids.contains(uid);
            }),
            ...activeRemote,
          ];

          setState(() {
            _lots = merged;
          });
        }
      } catch (e) {
        debugPrint('[PickupTab] Manual refresh failed: $e');
      }
    }

    if (mounted) setState(() => _isLoading = false);
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

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  void _showQrDialog(BuildContext context, String qrToken, String lotUid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.qr_code_2, size: 40, color: AppColors.primaryGold),
            const SizedBox(height: 8),
            Text(
              _t(
                'Pickup Verification QR',
                'पिकअप सत्यापन क्यूआर',
                'पिकअप पडताळणी क्यूआर',
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t(
                'Show this QR to the recycler driver upon arrival to verify handshake.',
                'हैंडशेक सत्यापित करने के लिए आने पर रिसाइकिलर चालक को यह क्यूआर दिखाएं।',
                'हँडशेक पडताळण्यासाठी आल्यावर रिसायकल चालकाला हा क्यूआर दाखवा.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: qrToken,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              lotUid,
              style: TextStyle(
                fontSize: 11,
                color: AppThemeColors.muted(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('Close', 'बंद करें', 'बंद करा')),
          ),
        ],
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
        title: Text(_t('My Scrap Lots', 'मेरे कबाड़ लॉट', 'माझे भंगार लॉट')),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadLots,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: activeAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_t('New Lot', 'नया लॉट', 'नवीन लॉट')),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassifyBulkScreen(
                storage: widget.storage,
                language: widget.language,
              ),
            ),
          );
          _loadLots();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _loadLots,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _lots.isEmpty
            ? _emptyState(context, activeAccent)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _lots.length,
                itemBuilder: (context, index) {
                  return _lotCard(context, _lots[index], activeAccent);
                },
              ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, Color activeAccent) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: activeAccent.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _t(
                  'No Scrap Lots Recorded Yet',
                  'अभी तक कोई लॉट दर्ज नहीं है',
                  'अद्याप कोणताही लॉट नोंदवला नाही',
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _t(
                  'Tap "New Lot" to record and evaluate collected scrap.',
                  'कबाड़ दर्ज करने के लिए "नया लॉट" पर टैप करें।',
                  'भंगार नोंदवण्यासाठी "नवीन लॉट" वर टॅप करा.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppThemeColors.muted(context),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lotCard(
    BuildContext context,
    Map<String, dynamic> row,
    Color activeAccent,
  ) {
    final lotUid =
        (row['client_lot_id'] ?? row['lot_uid'] ?? row['id'] ?? 'N/A')
            .toString();
    final imagePath = (row['image_path'] ?? row['photo_path'] ?? '').toString();
    final status = (row['status'] ?? 'PENDING').toString().toUpperCase();
    final createdAt =
        (row['created_at_local'] ?? row['created_at'] ?? row['synced_at'] ?? '')
            .toString();
    final qrToken = (row['qr_token'] ?? '').toString();

    Map<String, dynamic> payload = {};
    if (row['json_payload'] is String) {
      try {
        payload =
            jsonDecode(row['json_payload'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    final rawCode =
        (row['material_category'] ??
                payload['material_category'] ??
                'MIXED_EWASTE_CASING')
            .toString();
    final weight =
        row['estimated_weight_kg'] ?? payload['approx_weight_kg'] ?? 0;

    final bench = LocalAiClassifier.benchmarks[rawCode] ?? {'rate_per_kg': 100};
    final rate = (bench['rate_per_kg'] as num? ?? 100).toDouble();
    final totalPayout =
        payload['estimated_total_payout'] ??
        ((weight as num).toDouble() * rate).round();

    final localizedMaterial = LocalAiClassifier.getLocalizedMaterialName(
      rawCode,
      widget.language,
    );

    final canCancel =
        status != 'SESSION_OPEN' && status != 'VERIFIED_COMPLETED';

    Color badgeColor;
    String badgeText;

    switch (status) {
      case 'LOCKED':
        badgeColor = Colors.orange;
        badgeText = _t('Offer Locked', 'ऑफ़र लॉक हुआ', 'ऑफर लॉक झाली');
        break;
      case 'SESSION_OPEN':
        badgeColor = AppColors.lightGreen;
        badgeText = _t('Weighing Active', 'तौल सक्रिय', 'वजन सुरू आहे');
        break;
      case 'VERIFIED_COMPLETED':
        badgeColor = AppColors.featherGreen;
        badgeText = _t('Completed', 'पूरा हुआ', 'पूर्ण झाले');
        break;
      case 'BROADCASTED':
        badgeColor = Colors.blue;
        badgeText = _t('Broadcasting...', 'प्रसारण जारी...', 'प्रसारण सुरू...');
        break;
      case 'SYNCED':
        badgeColor = AppColors.lightGreen;
        badgeText = _t('Synced', 'सिंक हुआ', 'सिंक झाले');
        break;
      case 'PENDING':
      default:
        badgeColor = AppColors.warning;
        badgeText = _t('Pending Sync', 'सिंक लंबित', 'सिंक प्रलंबित');
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: status == 'LOCKED' ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imagePath.isNotEmpty && File(imagePath).existsSync()
                      ? Image.file(
                          File(imagePath),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 72,
                          height: 72,
                          color: activeAccent.withValues(alpha: 0.12),
                          child: Icon(
                            LocalAiClassifier.getMaterialIcon(rawCode),
                            color: activeAccent,
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              localizedMaterial,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                              if (canCancel) ...[
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _handleCancelLot(row),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: AppThemeColors.muted(context),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_t("UID:", "आईडी:", "आयडी:")} ${lotUid.length > 18 ? lotUid.substring(0, 18) : lotUid}',
                        style: TextStyle(
                          color: AppThemeColors.muted(context),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.scale,
                            size: 14,
                            color: AppThemeColors.muted(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$weight kg',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₹$totalPayout',
                            style: TextStyle(
                              color: activeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action area depending on state
          if (status == 'LOCKED' && qrToken.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.qr_code_2, size: 18),
                      label: Text(
                        _t(
                          'Show QR Code for Pickup',
                          'पिकअप के लिए क्यूआर कोड दिखाएं',
                          'पिकअपसाठी क्यूआर कोड दाखवा',
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () => _showQrDialog(context, qrToken, lotUid),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Divider(
              height: 1,
              color: AppThemeColors.muted(context).withValues(alpha: 0.15),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: AppThemeColors.muted(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppThemeColors.muted(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    status == 'PENDING'
                        ? _t(
                            'Offline Stored',
                            'ऑफ़लाइन संग्रहीत',
                            'ऑफलाइन जतन केले',
                          )
                        : _t(
                            'Server Synced',
                            'सर्वर सिंक हुआ',
                            'सर्व्हर सिंक झाले',
                          ),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppThemeColors.muted(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
