import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  bool _showCompleted = false; // 👈 Add this toggle state

  @override
  void initState() {
    super.initState();
    _loadLotsFromLocalDb();

    // Listen to background sync updates from SyncWorker (SSOT UI sync)
    SyncWorker.latestLotsNotifier.addListener(_onSyncWorkerUpdate);

    // Trigger an immediate background sync run on tab open if online
    final storage = widget.storage ?? getStorage(context);
    SyncWorker.triggerImmediate(storage);
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
        _lots = remote.where((lot) {
          final s = (lot['status'] ?? '').toString().toUpperCase();
          return s != 'CANCELLED' && s != 'WITHDRAWN' && s != 'ARCHIVED';
        }).toList();
        _isLoading = false;
      });
    }
  }

  /// 🛡️ SSOT Principle: Load directly and exclusively from local SQLite database
  Future<void> _loadLots() async {
    setState(() => _isLoading = true);

    try {
      // 🔥 Fetch all cached local lots instead of just pending queue items
      final allLocalLots = await DatabaseHelper.instance.getQueuedLots();
      if (mounted) {
        setState(() {
          _lots = allLocalLots.where((lot) {
            final s = (lot['status'] ?? '').toString().toUpperCase();
            return s != 'CANCELLED' && s != 'WITHDRAWN' && s != 'ARCHIVED';
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[PickupTab] Error loading local lots: $e');
      if (mounted) setState(() => _isLoading = false);
    }

    if (mounted) {
      final storage = widget.storage ?? getStorage(context);
      SyncWorker.triggerImmediate(storage);
    }
  }

  Future<void> _loadLotsFromLocalDb() async {
    await _loadLots();
  }

  Future<void> _handleCancelLot(Map<String, dynamic> lot) async {
    final status = (lot['status'] ?? 'PENDING').toString().toUpperCase();
    final clientUid = (lot['client_lot_id'] ?? lot['lot_uid'] ?? '').toString();
    final backendId = (lot['backend_id'] ?? lot['id'] ?? '').toString();
    final targetUid = clientUid.isNotEmpty ? clientUid : backendId;

    // 🛡️ OFFLINE & STATE RESTRICTION: Prevent cancelling if active/locked
    if (status == 'SESSION_OPEN' ||
        status == 'VERIFIED_COMPLETED' ||
        status == 'LOCKED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Cannot cancel a locked or active lot during pickup phase.',
              'पिकअप चरण के दौरान लॉक या सक्रिय लॉट को रद्द नहीं किया जा सकता।',
              'पिकअप दरम्यान लॉक किंवा सक्रिय लॉट रद्द केला जाऊ शकत नाही.',
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
          _t(
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
      if (status == 'PENDING') {
        // Purely local offline lot: safe to purge locally
        await DatabaseHelper.instance.deleteLot(targetUid);
      } else {
        // Synced lot: attempt backend cancellation
        final storage = widget.storage ?? getStorage(context);
        final cancelTarget = backendId.isNotEmpty ? backendId : targetUid;

        if (storage.accessToken != null && storage.accessToken!.isNotEmpty) {
          final success = await SyncService.cancelLot(
            storage: storage,
            lotId: cancelTarget,
          );
          if (!success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text(
                    _t(
                      'Offline: Cannot reach server to cancel synchronized lot.',
                      'ऑफ़लाइन: सिंक्रनाइज़ लॉट को रद्द करने के लिए सर्वर तक नहीं पहुँच सकते।',
                      'ऑफलाइन: सिंक केलेला लॉट रद्द करण्यासाठी सर्व्हरशी संपर्क साधता येत नाही.',
                    ),
                  ),
                ),
              );
            }
            setState(() => _isLoading = false);
            return;
          }
        }

        await DatabaseHelper.instance.deleteLot(targetUid);
      }
    } catch (e) {
      debugPrint('[PickupTab] Error canceling lot: $e');
    }

    await _loadLots();
  }

  Future<void> _showCashQrScanner({
    required BuildContext context,
    required String lotId,
    required double expectedAmount,
    required VoidCallback onVerified,
  }) async {
    bool isProcessing = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _t(
                        'Scan Driver Cash Receipt QR',
                        'ड्राइवर का नकद रसीद क्यूआर स्कैन करें',
                        'चालकाचा रोख पावती क्यूआर स्कॅन करा',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_t("Expected Amount:", "अपेक्षित राशि:", "अपेक्षित रक्कम:")} ₹${expectedAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.lightGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    onDetect: (capture) {
                      if (isProcessing) return;
                      final barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final rawValue = barcode.rawValue;
                        if (rawValue == null || rawValue.isEmpty) continue;

                        try {
                          final data =
                              jsonDecode(rawValue) as Map<String, dynamic>;
                          final scannedLotId = (data['lot_id'] ?? '')
                              .toString();
                          final scannedAmount =
                              (data['amount'] as num?)?.toDouble() ?? 0.0;

                          if (scannedLotId == lotId &&
                              (scannedAmount - expectedAmount).abs() < 1.0) {
                            isProcessing = true;
                            Navigator.pop(ctx);
                            onVerified();
                            return;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text(
                                  _t(
                                    'QR mismatch! Incorrect lot or amount.',
                                    'क्यूआर मेल नहीं खाता! अमान्य लॉट या राशि।',
                                    'क्यूआर जुळत नाही! अयोग्य लॉट किंवा रक्कम.',
                                  ),
                                ),
                              ),
                            );
                          }
                        } catch (_) {
                          if (rawValue.contains(lotId)) {
                            isProcessing = true;
                            Navigator.pop(ctx);
                            onVerified();
                            return;
                          }
                        }
                      }
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _t(
                    'Align driver screen inside frame',
                    'ड्राइवर की स्क्रीन को फ्रेम में रखें',
                    'चालकाचा स्क्रीन फ्रेममध्ये ठेवा',
                  ),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showConsentSheet(
    BuildContext context,
    Map<String, dynamic> row,
  ) async {
    final lotUid = (row['client_lot_id'] ?? row['lot_uid'] ?? row['id'] ?? '')
        .toString();
    final backendId = (row['backend_id'] ?? row['id'] ?? '').toString();
    final targetId = backendId.isNotEmpty ? backendId : lotUid;
    final storage = widget.storage ?? getStorage(context);

    Map<String, dynamic>? txn = row['transaction'] as Map<String, dynamic>?;
    if (txn == null && row['transaction_json'] != null) {
      try {
        txn = jsonDecode(
          row['transaction_json'] as String,
        ) as Map<String, dynamic>;
      } catch (_) {}
    }

    final certifiedWeight =
        (txn?['certified_weight_kg'] ??
                row['certified_weight_kg'] ??
                row['estimated_weight_kg'] ??
                5.0)
            .toDouble();

    final offeredRate =
        (txn?['offered_rate_per_kg'] ?? row['offered_rate_per_kg'] ?? 100.0)
            .toDouble();

    final totalAmount =
        (txn?['total_amount'] ?? (certifiedWeight * offeredRate)).toDouble();

    final recyclerName = 'Authorized Recycler';

    String selectedPaymentMode = 'UPI';
    final TextEditingController upiRefController = TextEditingController();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemeColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    color: AppColors.featherGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _t(
                        'Weighbridge & Payout Consent',
                        'तौल एवं भुगतान सहमति',
                        'वजन आणि पेमेंट संमती',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _t(
                  '$recyclerName entered certified weighbridge values. Verify before confirming.',
                  '$recyclerName ने प्रमाणित तौल दर्ज किया है। पुष्टि करने से पहले जांचें।',
                  '$recyclerName ने प्रमाणित वजन नोंदवले आहे. पुष्टी करण्यापूर्वी तपासा.',
                ),
                style: TextStyle(
                  color: AppThemeColors.muted(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // Breakdown Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.featherGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.featherGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _t(
                            'Certified Scale Weight:',
                            'प्रमाणित वजन:',
                            'प्रमाणित वजन:',
                          ),
                        ),
                        Text(
                          '$certifiedWeight kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _t(
                            'Offered Rate:',
                            'प्रस्तावित दर:',
                            'प्रस्तावित दर:',
                          ),
                        ),
                        Text(
                          '₹$offeredRate / kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _t(
                            'Total Final Payout:',
                            'कुल अंतिम भुगतान:',
                            'एकूण अंतिम देयक:',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: AppColors.featherGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                _t(
                  'Payment Method Received:',
                  'प्राप्त भुगतान माध्यम:',
                  'पेमेंट प्राप्त करण्याचे माध्यम:',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          _t('UPI (Instant)', 'यूपीआई (त्वरित)', 'युपीआय'),
                        ),
                      ),
                      selected: selectedPaymentMode == 'UPI',
                      onSelected: (val) {
                        if (val) {
                          setSheetState(() => selectedPaymentMode = 'UPI');
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Text(_t('Cash in Hand', 'नकद', 'रोख रक्कम')),
                      ),
                      selected: selectedPaymentMode == 'CASH',
                      onSelected: (val) {
                        if (val) {
                          setSheetState(() => selectedPaymentMode = 'CASH');
                        }
                      },
                    ),
                  ),
                ],
              ),

              if (selectedPaymentMode == 'UPI') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: upiRefController,
                  decoration: InputDecoration(
                    labelText: _t(
                      'UPI Ref / UTR (Optional)',
                      'यूपीआई संदर्भ / यूटीआर (वैकल्पिक)',
                      'युपीआय संदर्भ (पर्यायी)',
                    ),
                    hintText: 'e.g. 425612349871',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.receipt_long, size: 18),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() => _isLoading = true);
                        await SyncService.submitConsent(
                          storage: storage,
                          lotId: targetId,
                          accepted: false,
                        );
                        await _loadLots();
                      },
                      child: Text(_t('Dispute', 'अस्वीकार', 'नकार द्या')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.featherGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);

                        if (selectedPaymentMode == 'CASH') {
                          await _showCashQrScanner(
                            context: context,
                            lotId: targetId,
                            expectedAmount: totalAmount,
                            onVerified: () async {
                              setState(() => _isLoading = true);
                              final ok = await SyncService.submitConsent(
                                storage: storage,
                                lotId: targetId,
                                accepted: true,
                                paymentMode: 'CASH',
                              );

                              if (ok) {
                                await storage.savePayment({
                                  'mode': 'Cash',
                                  'details': 'Form-6 Lot $lotUid',
                                  'amount':
                                      '₹${totalAmount.toStringAsFixed(0)}',
                                  'date': DateTime.now().toIso8601String(),
                                });

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.featherGreen,
                                      content: Text(
                                        _t(
                                          'Cash payment verified! Form-6 receipt generated.',
                                          'नकद भुगतान सत्यापित! फॉर्म-6 रसीद जारी हुई।',
                                          'रोख व्यवहार पडताळला! फॉर्म-६ पावती तयार.',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              }
                              await _loadLots();
                            },
                          );
                        } else {
                          setState(() => _isLoading = true);
                          final enteredUpiRef = upiRefController.text.trim();
                          final ok = await SyncService.submitConsent(
                            storage: storage,
                            lotId: targetId,
                            accepted: true,
                            paymentMode: 'UPI',
                            upiReference: enteredUpiRef.isNotEmpty
                                ? enteredUpiRef
                                : null,
                          );

                          if (ok) {
                            await storage.savePayment({
                              'mode': 'UPI',
                              'details': enteredUpiRef.isNotEmpty
                                  ? 'Ref: $enteredUpiRef'
                                  : 'UPI Lot $lotUid',
                              'amount': '₹${totalAmount.toStringAsFixed(0)}',
                              'date': DateTime.now().toIso8601String(),
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.featherGreen,
                                  content: Text(
                                    _t(
                                      'UPI payout confirmed! Transaction completed.',
                                      'यूपीआई भुगतान स्वीकृत! लेनदेन पूरा हुआ।',
                                      'युपीआय पेमेंट मंजूर झाले! व्यवहार पूर्ण झाला.',
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                          await _loadLots();
                        }
                      },
                      child: Text(
                        selectedPaymentMode == 'CASH'
                            ? _t(
                                'Scan Cash QR & Accept',
                                'नकद क्यूआर स्कैन कर स्वीकारें',
                                'रोख क्यूआर स्कॅन करा व स्वीकारा',
                              )
                            : _t(
                                'Accept & Complete',
                                'स्वीकारें एवं पूरा करें',
                                'स्वीकारा आणि पूर्ण करा',
                              ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
          mainAxisSize: MainAxisSize.min,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
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
                  width: 210,
                  height: 210,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: qrToken.isNotEmpty
                      ? SizedBox(
                          width: 190,
                          height: 190,
                          child: QrImageView(
                            data: qrToken,
                            version: QrVersions.auto,
                            size: 190.0,
                          ),
                        )
                      : Icon(
                          Icons.qr_code,
                          size: 120,
                          color: Colors.grey.shade400,
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  lotUid,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppThemeColors.muted(context),
                  ),
                ),
              ],
            ),
          ),
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

    // Split lots into Active (Current) and Completed categories
    final activeLots = _lots.where((lot) {
      final status = (lot['status'] ?? '').toString().toUpperCase();
      return status != 'VERIFIED_COMPLETED' &&
          status != 'CANCELLED' &&
          status != 'WITHDRAWN';
    }).toList();

    final completedLots = _lots.where((lot) {
      final status = (lot['status'] ?? '').toString().toUpperCase();
      return status == 'VERIFIED_COMPLETED';
    }).toList();

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
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  // SECTION 1: ACTIVE / CURRENT LOTS
                  if (activeLots.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _t(
                            'Current Pickups & Active Lots',
                            'वर्तमान पिकअप और सक्रिय लॉट',
                            'सध्याचे पिकअप आणि सक्रिय लॉट',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...activeLots.map(
                      (lot) => _lotCard(context, lot, activeAccent),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // SECTION 2: COMPLETED LOTS (COLLAPSIBLE / CLOSED BY DEFAULT)
                  if (completedLots.isNotEmpty) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: AppThemeColors.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.featherGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: false, // 👈 Closed by default
                        onExpansionChanged: (expanded) {
                          setState(() => _showCompleted = expanded);
                        },
                        leading: const Icon(
                          Icons.verified_rounded,
                          color: AppColors.featherGreen,
                        ),
                        title: Text(
                          _t(
                            'Completed & Sealed Lots (${completedLots.length})',
                            'पूर्ण और सील किए गए लॉट (${completedLots.length})',
                            'पूर्ण आणि सील केलेले लॉट (${completedLots.length})',
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          _t(
                            'Tap to view history & Form-6 receipts',
                            'इतिहास और फॉर्म-6 रसीदें देखने के लिए टैप करें',
                            'इतिहास आणि पावत्या पाहण्यासाठी टॅप करा',
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppThemeColors.muted(context),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Column(
                              children: completedLots
                                  .map(
                                    (lot) =>
                                        _lotCard(context, lot, activeAccent),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (activeLots.isEmpty && completedLots.isEmpty)
                    _emptyState(context, activeAccent),
                ],
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

    Map<String, dynamic>? txn = row['transaction'] as Map<String, dynamic>?;
    if (txn == null && row['transaction_json'] != null) {
      try {
        txn = jsonDecode(
          row['transaction_json'] as String,
        ) as Map<String, dynamic>;
      } catch (_) {}
    }

    final double? certifiedWeight = (txn?['certified_weight_kg'] as num?)
        ?.toDouble();
    final double estWeight =
        ((row['estimated_weight_kg'] as num?) ??
                (payload['approx_weight_kg'] as num?) ??
                1.0)
            .toDouble();

    final weight = certifiedWeight ?? estWeight;

    final bench = LocalAiClassifier.benchmarks[rawCode] ?? {'rate_per_kg': 100};
    final double rate =
        ((txn?['offered_rate_per_kg'] as num?) ??
                (bench['rate_per_kg'] as num?) ??
                100.0)
            .toDouble();

    final totalPayout =
        txn?['total_amount'] ??
        payload['estimated_total_payout'] ??
        (weight * rate).round();

    final localizedMaterial = LocalAiClassifier.getLocalizedMaterialName(
      rawCode,
      widget.language,
    );

    final canCancel =
        status != 'SESSION_OPEN' &&
        status != 'WEIGHED' &&
        status != 'VERIFIED_COMPLETED';

    Color badgeColor;
    String badgeText;

    switch (status) {
      case 'WEIGHED':
        badgeColor = AppColors.featherGreen;
        badgeText = _t('Awaiting Consent', 'सहमति लंबित', 'संमती प्रलंबित');
        break;
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
          width: (status == 'LOCKED' || status == 'WEIGHED') ? 1.8 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: status == 'WEIGHED'
            ? () => _showConsentSheet(context, row)
            : null,
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

                        // Weight & Payout row
                        if (status == 'WEIGHED' && txn != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.scale,
                                size: 14,
                                color: AppColors.featherGreen,
                              ),
                              const SizedBox(width: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$certifiedWeight kg',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${_t("Est:", "अनुमानित:", "अंदाजे:")} $estWeight kg',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppThemeColors.muted(context),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹$totalPayout',
                                    style: const TextStyle(
                                      color: AppColors.featherGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '₹${rate.toStringAsFixed(0)}/kg',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppThemeColors.muted(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ] else ...[
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
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action Area
            if (status == 'LOCKED' && qrToken.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(15),
                  ),
                ),
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
            ] else if (status == 'WEIGHED') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.featherGreen.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(15),
                  ),
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.featherGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.verified, size: 18),
                  label: Text(
                    _t(
                      'Review & Confirm Payout',
                      'भुगतान की समीक्षा एवं पुष्टि करें',
                      'पेमेंट तपासा आणि संमती द्या',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  onPressed: () => _showConsentSheet(context, row),
                ),
              ),
            ] else ...[
              Divider(
                height: 1,
                color: AppThemeColors.muted(context).withValues(alpha: 0.15),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
      ),
    );
  }
}
