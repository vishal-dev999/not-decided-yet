import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_enums.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../widgets/language_text.dart';

class RecyclerNearbyMapScreen extends StatelessWidget {
  final AppLanguage language;

  const RecyclerNearbyMapScreen({super.key, required this.language});

  static const double _maxRadiusKm = 8;

  List<Map<String, dynamic>> get _recyclers => [
    {
      'name': 'EcoRecycle Ltd',
      'distance': 1.2,
      'angle': 40.0,
      'tag': LanguageText.t(
        language,
        'E-Waste • PCB • Batteries',
        'ई-कचरा • पीसीबी • बैटरी',
        'ई-कचरा • पीसीबी • बॅटरी',
      ),
    },
    {
      'name': 'GreenLoop Recycling',
      'distance': 2.4,
      'angle': 120.0,
      'tag': LanguageText.t(
        language,
        'E-Waste • Metals • Plastics',
        'ई-कचरा • धातु • प्लास्टिक',
        'ई-कचरा • धातू • प्लास्टिक',
      ),
    },
    {
      'name': 'ReCircle Hub',
      'distance': 3.1,
      'angle': 200.0,
      'tag': LanguageText.t(
        language,
        'Electronics • Mixed Scrap',
        'इलेक्ट्रॉनिक्स • मिश्रित कबाड़',
        'इलेक्ट्रॉनिक्स • मिश्रित भंगार',
      ),
    },
    {
      'name': 'Metro Metal Works',
      'distance': 5.6,
      'angle': 280.0,
      'tag': LanguageText.t(
        language,
        'Copper • Aluminium',
        'तांबा • एल्युमीनियम',
        'तांबे • ॲल्युमिनियम',
      ),
    },
    {
      'name': 'UrbanScrap Recyclers',
      'distance': 7.4,
      'angle': 330.0,
      'tag': LanguageText.t(
        language,
        'Mixed Scrap',
        'मिश्रित कबाड़',
        'मिश्रित भंगार',
      ),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;
    final double mapSize = math.min(
      300.0,
      MediaQuery.of(context).size.width - 32,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageText.t(
            language,
            'Recycler Nearby',
            'पास के रीसायकलर',
            'जवळचे रीसायकलर',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LanguageText.t(
                language,
                'Recyclers within 8 km',
                '8 किमी के दायरे में रीसायकलर',
                '8 किमी परिसरातील रीसायकलर',
              ),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppThemeColors.text(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              LanguageText.t(
                language,
                'Prototype map using sample locations. This will use live location and Google Maps in a future version.',
                'यह प्रोटोटाइप नमूना स्थानों का उपयोग करता है। भविष्य के संस्करण में इसमें लाइव लोकेशन और गूगल मैप्स होंगे।',
                'हे प्रोटोटाइप नमुना ठिकाणे वापरते. भविष्यातील आवृत्तीत यात थेट लोकेशन आणि गूगल नकाशे असतील.',
              ),
              style: TextStyle(
                color: AppThemeColors.muted(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: mapSize,
                height: mapSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final ring in [1.0, 0.75, 0.5, 0.25])
                      Container(
                        width: mapSize * ring,
                        height: mapSize * ring,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activeAccent.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    for (final r in _recyclers)
                      Positioned(
                        left:
                            mapSize / 2 +
                            ((mapSize / 2) *
                                    ((r['distance'] as double) /
                                        _maxRadiusKm)) *
                                math.cos(
                                  (r['angle'] as double) * math.pi / 180,
                                ) -
                            16,
                        top:
                            mapSize / 2 +
                            ((mapSize / 2) *
                                    ((r['distance'] as double) /
                                        _maxRadiusKm)) *
                                math.sin(
                                  (r['angle'] as double) * math.pi / 180,
                                ) -
                            16,
                        child: GestureDetector(
                          onTap: () =>
                              _showRecyclerInfo(context, r, activeAccent),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: activeAccent,
                            child: const Icon(
                              Icons.recycling,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.danger,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                LanguageText.t(
                  language,
                  'You are at the center',
                  'आप केंद्र में हैं',
                  'तुम्ही मध्यभागी आहात',
                ),
                style: TextStyle(
                  color: AppThemeColors.faint(context),
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              LanguageText.t(
                language,
                'Nearby Recyclers',
                'पास के रीसायकलर',
                'जवळचे रीसायकलर',
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppThemeColors.text(context),
              ),
            ),
            const SizedBox(height: 10),
            ..._recyclers.map(
              (r) => Card(
                child: ListTile(
                  leading: Icon(Icons.recycling, color: activeAccent),
                  title: Text(r['name'] as String),
                  subtitle: Text('${r['distance']} km • ${r['tag']}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecyclerInfo(
    BuildContext context,
    Map<String, dynamic> r,
    Color accent,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppThemeColors.card(context),
        title: Text(r['name'] as String),
        content: Text('${r['distance']} km • ${r['tag']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              LanguageText.t(language, 'Close', 'बंद करें', 'बंद करा'),
            ),
          ),
        ],
      ),
    );
  }
}
