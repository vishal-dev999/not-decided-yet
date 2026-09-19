import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../constants/app_enums.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../widgets/language_text.dart';

class SafetyTab extends StatefulWidget {
  final AppLanguage language;

  const SafetyTab({
    super.key,
    this.language = AppLanguage.english,
  });

  @override
  State<SafetyTab> createState() => _SafetyTabState();
}

class _SafetyTabState extends State<SafetyTab> {
  final FlutterTts tts = FlutterTts();

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) return;
    switch (widget.language) {
      case AppLanguage.hindi:
        await tts.setLanguage('hi-IN');
        break;
      case AppLanguage.marathi:
        await tts.setLanguage('mr-IN');
        break;
      case AppLanguage.english:
      default:
        await tts.setLanguage('en-IN');
        break;
    }
    await tts.setSpeechRate(0.42);
    await tts.speak(text);
  }

  List<Map<String, dynamic>> get guidance {
    switch (widget.language) {
      case AppLanguage.hindi:
        return [
          {
            'title': 'ई-कचरा न जलाएं',
            'description': 'तार, प्लास्टिक या इलेक्ट्रॉनिक भागों को जलाने से जहरीला धुआं निकलता है। इसके बजाय अधिकृत रीसाइक्लिंग चैनलों का उपयोग करें।',
            'icon': Icons.local_fire_department,
            'danger': true,
            'audio': 'इलेक्ट्रॉनिक कचरा, तार, बैटरी या प्लास्टिक न जलाएं। जलाने से जहरीला धुआं निकल सकता है।',
          },
          {
            'title': 'बैटरी न खोलें',
            'description': 'बैटरियों को काटें, छेद न करें या खोलें नहीं। क्षतिग्रस्त बैटरियों को अलग रखें और अधिकृत रीसायकलर से संपर्क करें।',
            'icon': Icons.battery_alert,
            'danger': true,
            'audio': 'बैटरियों को न खोलें, काटें या छेदें। क्षतिग्रस्त बैटरियों को अलग रखें।',
          },
          {
            'title': 'CRT को सावधानी से संभालें',
            'description': 'CRT टीवी और मॉनिटर में खतरनाक सामग्री हो सकती है। कांच को तोड़ने से बचें और जलाएं नहीं।',
            'icon': Icons.tv,
            'danger': true,
            'audio': 'CRT टीवी और मॉनिटर को सावधानी से संभालें। कांच न तोड़ें।',
          },
          {
            'title': 'इलेक्ट्रॉनिक्स को सूखा रखें',
            'description': 'संग्रहण से पहले सर्किट बोर्ड और इलेक्ट्रॉनिक्स को सूखे स्थान पर रखें।',
            'icon': Icons.water_drop,
            'danger': false,
            'audio': 'सर्किट बोर्ड और इलेक्ट्रॉनिक घटकों को सूखा रखें।',
          },
          {
            'title': 'सुरक्षा उपकरणों का प्रयोग करें',
            'description': 'धारदार या क्षतिग्रस्त हिस्सों को संभालते समय दस्ताने और जूते पहनें।',
            'icon': Icons.health_and_safety,
            'danger': false,
            'audio': 'धारदार हिस्सों को संभालते समय दस्ताने और जूते पहनें।',
          },
        ];
      case AppLanguage.marathi:
        return [
          {
            'title': 'ई-कचरा जाळू नका',
            'description': 'इलेक्ट्रॉनिक भाग जाळल्याने विषारी वायू बाहेर पडतात. अधिकृत मार्गांचा वापर करा.',
            'icon': Icons.local_fire_department,
            'danger': true,
            'audio': 'इलेक्ट्रॉनिक कचरा किंवा प्लास्टिक जाळू नका.',
          },
          {
            'title': 'बॅटरी उघडू नका',
            'description': 'बॅटरी कापू किंवा फोडू नका. खराब झालेल्या बॅटरी वेगळ्या ठेवा.',
            'icon': Icons.battery_alert,
            'danger': true,
            'audio': 'बॅटरी उघडू नका किंवा कापू नका.',
          },
          {
            'title': 'CRT काळजीपूर्वक हाताळा',
            'description': 'CRT टीव्हीमधील काच फोडू नका किंवा जाळू नका.',
            'icon': Icons.tv,
            'danger': true,
            'audio': 'CRT टीव्ही आणि मॉनिटर काळजीपूर्वक हाताळा.',
          },
          {
            'title': 'इलेक्ट्रॉनिक्स कोरडे ठेवा',
            'description': 'सर्किट बोर्ड कोरड्या जागी ठेवा.',
            'icon': Icons.water_drop,
            'danger': false,
            'audio': 'इलेक्ट्रॉनिक वस्तू कोरड्या जागी ठेवा.',
          },
          {
            'title': 'सुरक्षिततेची साधने वापरा',
            'description': 'काम करताना हातमोजे आणि योग्य शूज वापरा.',
            'icon': Icons.health_and_safety,
            'danger': false,
            'audio': 'हातमोजे आणि शूज वापरणे गरजेचे आहे.',
          },
        ];
      case AppLanguage.english:
      default:
        return [
          {
            'title': 'Do not burn e-waste',
            'description':
                'Burning wires, plastic or electronic parts can release toxic fumes. Use authorized recycling channels instead.',
            'icon': Icons.local_fire_department,
            'danger': true,
            'audio':
                'Do not burn electronic waste, wires, batteries or plastic. Burning can release toxic fumes.',
          },
          {
            'title': 'Do not open batteries',
            'description':
                'Do not cut, puncture or dismantle batteries. Keep damaged batteries isolated and contact an authorized recycler.',
            'icon': Icons.battery_alert,
            'danger': true,
            'audio':
                'Do not open, cut or puncture batteries. Keep damaged batteries isolated and contact an authorized recycler.',
          },
          {
            'title': 'Handle CRTs carefully',
            'description':
                'CRT televisions and monitors can contain hazardous materials. Avoid breaking the glass and do not smash or burn CRTs.',
            'icon': Icons.tv,
            'danger': true,
            'audio':
                'Handle CRT televisions and monitors carefully. Do not smash, break or burn CRT glass.',
          },
          {
            'title': 'Keep electronics dry',
            'description':
                'Store circuit boards and electronics in a dry, covered place before collection.',
            'icon': Icons.water_drop,
            'danger': false,
            'audio':
                'Keep circuit boards and electronic components dry and covered before collection.',
          },
          {
            'title': 'Use basic protection',
            'description':
                'Use gloves, closed footwear and eye protection when handling sharp or damaged electronic parts.',
            'icon': Icons.health_and_safety,
            'danger': false,
            'audio':
                'Use gloves, closed footwear and eye protection when handling sharp or damaged electronic parts.',
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageText.t(
          widget.language,
          'Safety Guidance',
          'सुरक्षा मार्गदर्शन',
          'सुरक्षा मार्गदर्शन',
        )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LanguageText.t(
                widget.language,
                'Safety Guidance',
                'सुरक्षा मार्गदर्शन',
                'सुरक्षा मार्गदर्शन',
              ),
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: AppThemeColors.text(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              LanguageText.t(
                widget.language,
                'Simple picture-based and audio guidance for safer e-waste handling.',
                'सुरक्षित ई-कचरा संभालने के लिए सरल चित्र और ऑडियो मार्गदर्शन।',
                'सुरक्षित ई-कचरा हाताळणीसाठी सोपे चित्र आणि ऑडिओ मार्गदर्शन.',
              ),
              style: TextStyle(color: AppThemeColors.muted(context)),
            ),
            const SizedBox(height: 18),
            ...guidance.map((item) => _safetyCard(context, item)),
          ],
        ),
      ),
    );
  }

  Widget _safetyCard(BuildContext context, Map<String, dynamic> item) {
    final danger = item['danger'] as bool;
    final iconBoxSize = MediaQuery.of(context).size.width < 340 ? 46.0 : 58.0;
    final iconSize = MediaQuery.of(context).size.width < 340 ? 24.0 : 30.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: danger
              ? AppColors.danger.withValues(alpha: 0.45)
              : AppColors.lightGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: iconBoxSize,
                width: iconBoxSize,
                decoration: BoxDecoration(
                  color: danger
                      ? AppColors.danger.withValues(alpha: 0.13)
                      : AppColors.lightGreen.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  size: iconSize,
                  color: danger ? AppColors.danger : AppColors.lightGreen,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['description'] as String,
                      style: TextStyle(
                        color: AppThemeColors.muted(context),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 42,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: AppColors.mintGreen,
                  foregroundColor: AppColors.darkBackground,
                  shape: const CircleBorder(),
                ),
                onPressed: () => _speak(item['audio'] as String),
                child: const Icon(
                  Icons.volume_up,
                  color: AppColors.darkBackground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
