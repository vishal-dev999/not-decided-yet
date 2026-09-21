import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/app_enums.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/storage_service.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

class RecyclerNearbyScreen extends StatefulWidget {
  final ReNovaStorage? storage;
  final AppLanguage language;

  const RecyclerNearbyScreen({super.key, this.storage, required this.language});

  @override
  State<RecyclerNearbyScreen> createState() => _RecyclerNearbyScreenState();
}

class _RecyclerNearbyScreenState extends State<RecyclerNearbyScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _userLots = [];
  String? _selectedLotId;
  List<Map<String, dynamic>> _matchedRecyclers = [];

  @override
  void initState() {
    super.initState();
    _loadLotsAndMatches();
  }

  String _t(String english, String hindi, String marathi) {
    switch (widget.language) {
      case AppLanguage.hindi:
        return hindi;
      case AppLanguage.marathi:
        return marathi;
      case AppLanguage.english:
      default:
        return english;
    }
  }

  /// 1. Load active broadcasted local lots (excluding completed/cancelled ones)
  Future<void> _loadLotsAndMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final localLots = await DatabaseHelper.instance.getQueuedLots(limit: 50);

      // 🛡️ STRICT FILTER: Only keep active/broadcasted lots, exclude completed & cancelled
      final activeLots = localLots.where((lot) {
        final status = (lot['status'] ?? '').toString().toUpperCase();
        final hasBackendId =
            lot['backend_id'] != null &&
            (lot['backend_id'] as String).isNotEmpty;

        return hasBackendId &&
            status != 'CANCELLED' &&
            status != 'WITHDRAWN' &&
            status != 'ARCHIVED' &&
            status != 'VERIFIED_COMPLETED' &&
            status != 'CONSENTED';
      }).toList();

      if (activeLots.isNotEmpty) {
        _userLots = activeLots;
        _selectedLotId = activeLots.first['backend_id']?.toString();

        if (_selectedLotId != null && _selectedLotId!.isNotEmpty) {
          await _fetchTopMatchesForLot(_selectedLotId!);
        }
      } else {
        setState(() {
          _isLoading = false;
          _userLots = [];
          _matchedRecyclers = [];
          _errorMessage = _t(
            'No broadcasted active lots found. Sync or create an active lot first!',
            'कोई सक्रिय प्रसारित लॉट नहीं मिला।',
            'कोणतेही सक्रिय प्रसारित लॉट सापडले नाही.',
          );
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// 2. Fetch live Top-3 matches from GET /api/v1/lots/{lot_id}/matches
  Future<void> _fetchTopMatchesForLot(String lotId) async {
    // 🛡️ Fallback: Get storage instance if widget.storage is null
    final storage = widget.storage ?? await ReNovaStorage.getInstance();
    final token = storage.accessToken;

    if (token == null || token.isEmpty) {
      debugPrint('[RecyclerNearby] ERROR: Token is missing!');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication token missing. Please log in again.';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final baseUrl = AuthService.getBaseUrl(storage);
      final url = Uri.parse('$baseUrl/api/v1/lots/$lotId/matches');

      debugPrint(
        '[RecyclerNearby] Fetching matches for lotId: $lotId from URL: $url',
      );

      final res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'ngrok-skip-browser-warning': 'true',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('[RecyclerNearby] Response Status: ${res.statusCode}');
      debugPrint('[RecyclerNearby] Response Body: ${res.body}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        List<dynamic> rawList = [];
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map) {
          rawList =
              decoded['data'] as List<dynamic>? ??
              decoded['matches'] as List<dynamic>? ??
              [];
        }

        debugPrint('[RecyclerNearby] Parsed match count: ${rawList.length}');

        setState(() {
          _matchedRecyclers = rawList
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          _isLoading = false;
        });
      } else {
        debugPrint(
          '[RecyclerNearby] Failed with status code ${res.statusCode}',
        );
        setState(() {
          _isLoading = false;
          _matchedRecyclers = [];
        });
      }
    } catch (e) {
      debugPrint('[RecyclerNearby] Exception caught: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch broadcast matches: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t(
            'Broadcasted Recyclers',
            'प्रसारित रीसायक्लर',
            'प्रसारित रिसायकलर',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _selectedLotId != null
                ? () => _fetchTopMatchesForLot(_selectedLotId!)
                : _loadLotsAndMatches,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Lot Selector Dropdown
                    Text(
                      _t(
                        'Select Scrap Lot to Inspect',
                        'जांच के लिए कबाड़ लॉट चुनें',
                        'तपासणीसाठी भंगार लॉट निवडा',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_userLots.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _errorMessage ??
                              _t(
                                'No active lots available.',
                                'कोई सक्रिय लॉट उपलब्ध नहीं है।',
                                'कोणतेही सक्रिय लॉट उपलब्ध नाही.',
                              ),
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppThemeColors.card(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLotId,
                            isExpanded: true,
                            items: _userLots.map((lot) {
                              final backendId =
                                  lot['backend_id']?.toString() ?? '';
                              final shortUid = backendId.length > 10
                                  ? backendId.substring(0, 10)
                                  : backendId;
                              final cat =
                                  lot['material_category'] ?? 'MIXED_EWASTE';
                              return DropdownMenuItem(
                                value: backendId,
                                child: Text(
                                  'Lot #$shortUid ($cat) • Status: ${lot['status'] ?? 'BROADCASTED'}',
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedLotId = val);
                                _fetchTopMatchesForLot(val);
                              }
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // 2. Status Banner explaining Top-3 Broadcast
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.podcasts, color: accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _t(
                                'This lot is actively broadcasted to the top 3 matching certified recyclers in your region.',
                                'यह लॉट आपके क्षेत्र के शीर्ष 3 प्रमाणित रीसायकलर को प्रसारित किया गया है।',
                                'हा लॉट तुमच्या क्षेत्रातील शीर्ष 3 प्रमाणित रिसायकलरना प्रसारित केला आहे.',
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Recycler List
                    Text(
                      _t(
                        'Top Matched Recyclers (Top 3)',
                        'शीर्ष मिलान रीसायक्लर (शीर्ष 3)',
                        'शीर्ष जुळणारे रिसायकलर (शीर्ष 3)',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_matchedRecyclers.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppThemeColors.card(context),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.hourglass_empty,
                              size: 36,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _t(
                                'No recycler bids received yet or lot is still syncing.',
                                'अभी तक कोई रीसायकलर बोली प्राप्त नहीं हुई है।',
                                'अजून कोणतीही रिसायकलर बोली प्राप्त झालेली नाही.',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppThemeColors.muted(context),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._matchedRecyclers.map((recycler) {
                        final name =
                            recycler['recycler_name']?.toString() ??
                            'Certified Recycler';
                        final city =
                            recycler['recycler_city']?.toString() ??
                            'Bhubaneswar';
                        final distance =
                            (recycler['distance_km'] as num?)?.toDouble() ??
                            0.0;
                        final rate =
                            (recycler['offered_price_per_kg'] as num?)
                                ?.toDouble() ??
                            0.0;
                        final rank = recycler['rank']?.toString() ?? '';
                        final status = (recycler['status'] ?? '')
                            .toString()
                            .toUpperCase();

                        Color statusColor = Colors.grey;
                        if (status == 'CLAIMED') statusColor = Colors.green;
                        if (status == 'WITHDRAWN')
                          statusColor = Colors.redAccent;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppThemeColors.card(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: status == 'CLAIMED'
                                  ? Colors.green.withValues(alpha: 0.5)
                                  : accent.withValues(alpha: 0.2),
                              width: status == 'CLAIMED' ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: accent.withValues(alpha: 0.15),
                                child: Icon(Icons.recycling, color: accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (rank.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Rank #$rank',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$city • ${distance.toStringAsFixed(1)} km away',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppThemeColors.muted(context),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Offer: ₹${rate.toStringAsFixed(1)} / kg',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: accent,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
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
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}
