
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../constants/app_enums.dart';
import '../../themes/app_colors.dart';
import '../../themes/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? audioText;

  ChatMessage({required this.text, required this.isUser, this.audioText});
}

class RecyChatbotSheet extends StatefulWidget {
  final AppLanguage language;

  const RecyChatbotSheet({super.key, required this.language});

  @override
  State<RecyChatbotSheet> createState() => _RecyChatbotSheetState();
}

class _RecyChatbotSheetState extends State<RecyChatbotSheet> {
  final FlutterTts tts = FlutterTts();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(text: welcomeMsg, isUser: false, audioText: welcomeMsg),
    );
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  String get welcomeMsg {
    switch (widget.language) {
      case AppLanguage.hindi:
        return 'नमस्ते! मैं Recy हूँ, आपका रीसाइक्लिंग AI सहायक! 🤖✨ आज मैं आपकी क्या मदद कर सकता हूँ? नीचे दिए गए प्रश्नों में से चुनें!';
      case AppLanguage.marathi:
        return 'नमस्कार! मी Recy आहे, तुमचा रीसायकलिंग AI मित्र! 🤖✨ आज मी तुम्हाला कशी मदत करू शकतो? खालील प्रश्नांमधून निवडा!';
      case AppLanguage.english:
      default:
        return 'Hello! I am Recy, your friendly recycling AI buddy! 🤖✨ How can I help you today? Pick a question below!';
    }
  }

  List<Map<String, String>> get questionsAndAnswers {
    switch (widget.language) {
      case AppLanguage.hindi:
        return [
          {
            'q': 'कबाड़ का सही मूल्य कैसे प्राप्त करें?',
            'a': 'अपने कबाड़ को धातु, प्लास्टिक और ई-कचरे में अलग करें। वर्गीकृत सामग्री पर अधिक मूल्य मिलता है!',
          },
          {
            'q': 'ई-कचरा (E-Waste) कैसे बेचें?',
            'a': 'ऐप में \'Classify\' विकल्प पर जाएं, ई-कचरे की फोटो लें और आपको तुरंत अनुमानित मूल्य और रीसाइक्लिंग सुझाव मिल जाएंगे।',
          },
          {
            'q': 'पिकअप कैसे शेड्यूल करें?',
            'a': 'Pick-Up टैब पर जाएं और अपने नजदीकी संग्रहण स्थल की जांच करके पिकअप स्वीकार करें।',
          },
          {
            'q': 'प्लास्टिक कचरे का क्या करें?',
            'a': 'प्लास्टिक को बोतल, हार्ड प्लास्टिक और थैलियों में छांट लें। साफ और सूखी प्लास्टिक का बेहतर दाम मिलता है।',
          },
          {
            'q': 'पुराने इलेक्ट्रॉनिक्स की जांच कैसे करें?',
            'a': 'मशीनों से बैटरी निकालें और सर्किट्स को अलग रखें। बैटरी का सुरक्षित निपटान जरूरी है।',
          },
          {
            'q': 'तांबा और पीतल की कीमत ज्यादा क्यों है?',
            'a': 'ये कीमती धातुएं हैं जिनका पुनर्चक्रण आसान है और उद्योग में इनकी बहुत मांग है।',
          },
          {
            'q': 'डिजिटल भुगतान कैसे प्राप्त करें?',
            'a': 'Payment टैब में जाकर अपना UPI या बैंक विवरण अपडेट करें। भुगतान सीधा आपके खाते में आएगा।',
          },
          {
            'q': 'कबाड़ का वजन कैसे मापा जाता है?',
            'a': 'हमारे सत्यापित रीसायकलर डिजिटल कांटे का उपयोग करते हैं जिससे सटीक वजन मिलता है।',
          },
          {
            'q': 'सुरक्षा के लिए क्या उपाय करें?',
            'a': 'कबाड़ उठाते समय दस्ताने और मजबूत जूते पहनें। खतरनाक रसायनों और कांच से बचें।',
          },
          {
            'q': 'क्या घर बैठे पिकअप हो सकता है?',
            'a': 'हाँ, ऐप में Pick-Up विकल्प का उपयोग करके आप निकटतम पिकअप अनुरोध चुन सकते हैं।',
          },
          {
            'q': 'रीसाइक्लिंग से पर्यावरण को क्या फायदा है?',
            'a':
                'इससे प्राकृतिक संसाधनों की बचत होती है और प्रदूषण कम होता है।',
          },
          {
            'q': 'नया रीसायकलर कैसे खोजें?',
            'a': 'डैशबोर्ड और Pick-Up टैब में आपके पास के सभी प्रमाणित रीसायकलर्स की सूची दिखती है।',
          },
          {
            'q': 'लोहे का कबाड़ कैसे बेचें?',
            'a': 'लोहे को जंग और गंदगी से साफ रखें। भारी लोहे की कीमत सामान्य कबाड़ से बेहतर मिलती है।',
          },
          {
            'q': 'ऐप में भाषा कैसे बदलें?',
            'a': 'सेटिंग्स विकल्प में जाकर आप हिंदी, अंग्रेजी या मराठी चुन सकते हैं।',
          },
        ];
      case AppLanguage.marathi:
        return [
          {
            'q': 'भंगाराचा योग्य दर कसा मिळवावा?',
            'a': 'तुमचे भंगार प्लास्टिक, धातू आणि ई-कचऱ्यामध्ये वेगळे करा. वर्गीकरण केलेल्या भंगाराला जास्त दर मिळतो!',
          },
          {
            'q': 'ई-कचरा कसा विकावा?',
            'a': '\'Classify\' पर्यायावर जा, फोटो काढा आणि तुम्हाला लगेचच अंदाजित किंमत आणि रीसायकलिंग पर्याय मिळतील.',
          },
          {
            'q': 'पिकअप कसा बुक करावा?',
            'a': 'Pick-Up टॅबवर जा आणि तुमच्या जवळच्या ठिकाणी पिकअप शेड्युल करा.',
          },
          {
            'q': 'प्लास्टिक कचऱ्याचे काय करावे?',
            'a': 'प्लास्टिकच्या बाटल्या आणि इतर प्लास्टिक वेगळे करा. स्वच्छ प्लास्टिकला चांगला भाव मिळतो.',
          },
          {
            'q': 'जुने इलेक्ट्रॉनिक्स कसे तपासावे?',
            'a': 'इलेक्ट्रॉनिक वस्तूंमधून बॅटरी वेगळी करा. सर्किट बोर्ड कोरडे ठेवा.',
          },
          {
            'q': 'तांबे आणि पितळाला जास्त दर का मिळतो?',
            'a': 'ह्या मौल्यवान धातू आहेत आणि उद्योगांमध्ये यांची मागणी जास्त असते.',
          },
          {
            'q': 'डिजिटल पेमेंट कसे मिळवावे?',
            'a': 'Payment टॅबवर जाऊन तुमची UPI माहिती सेट करा. पैसे थेट खात्यात जमा होतील.',
          },
          {
            'q': 'भंगाराचे वजन कसे केले जाते?',
            'a': 'डिजिटल काट्याचा वापर करून अचूक वजन केले जाते.',
          },
          {
            'q': 'सुरक्षतेसाठी काय काळजी घ्यावी?',
            'a': 'काम करताना हातमोजे आणि योग्य शूज वापरा. काच व रसायनांपासून सावध राहा.',
          },
          {
            'q': 'घरपोच पिकअप सुविधा उपलब्ध आहे का?',
            'a': 'होय, Pick-Up पर्यायातून तुम्ही जवळची पिकअप मागणी स्वीकारू शकता.',
          },
          {
            'q': 'पुनर्वापराचा पर्यावरणाला काय फायदा होतो?',
            'a': 'यामुळे प्रदूषण कमी होते आणि नैसर्गिक संसाधनांची बचत होते.',
          },
          {
            'q': 'नवीन रीसायकलर कसा शोधावा?',
            'a': 'डॅशबोर्डवर तुम्हाला परिसरातील नोंदणीकृत रीसायकलर दिसतील.',
          },
          {
            'q': 'खंडी लोखंड कसे विकावे?',
            'a': 'लोखंड स्वच्छ आणि कोरडे ठेवा. जाड लोखंडाला चांगला दर मिळतो.',
          },
          {
            'q': 'अ‍ॅपची भाषा कशी बदलावी?',
            'a': 'सेटिंग्ज मध्ये जाऊन तुम्ही तुमची आवडती भाषा निवडू शकता.',
          },
        ];
      case AppLanguage.english:
      default:
        return [
          {
            'q': 'How do I get the best scrap prices?',
            'a': 'Separate your scrap into copper, PCB, and plastics beforehand. Clean and sorted scrap earns a higher value!',
          },
          {
            'q': 'How to classify and sell E-Waste?',
            'a': 'Go to the Classify tab, take a photo of your electronic item, and Recy AI will estimate its weight and fair price.',
          },
          {
            'q': 'How do I check pickup schedules?',
            'a': 'Check the Pick-Up tab from the bottom navigation bar to view all designated pickup locations and details.',
          },
          {
            'q': 'What is the best way to handle plastic scrap?',
            'a': 'Segregate PET bottles, hard plastics, and flexible films. Clean and dry plastics get better market rates.',
          },
          {
            'q': 'How to process old circuit boards (PCBs)?',
            'a': 'Remove batteries and bulky casings. Keep PCBs dry to maintain highest recovery grade value.',
          },
          {
            'q': 'Why do copper and brass have higher rates?',
            'a': 'They are high-demand non-ferrous metals that can be recycled infinitely without quality loss.',
          },
          {
            'q': 'How do I receive digital payments?',
            'a': 'Go to the Payment tab and choose UPI/Digital Wallet as your preference for instant settlements.',
          },
          {
            'q': 'How is scrap weight verified?',
            'a': 'Partnered recyclers use certified digital weighing scales to ensure accurate and transparent measurement.',
          },
          {
            'q': 'What safety gear should scrap collectors use?',
            'a': 'Always wear heavy-duty gloves, safety shoes, and protective goggles when handling broken glass or sharp metals.',
          },
          {
            'q': 'Can I schedule doorstep scrap collection?',
            'a': 'Yes, use the Pick-Up tab to view nearby collection requests and schedule a convenient pickup time.',
          },
          {
            'q': 'What are the environmental benefits of recycling?',
            'a': 'Recycling reduces landfill waste, conserves raw natural resources, and lowers industrial carbon emissions.',
          },
          {
            'q': 'How to find verified recyclers nearby?',
            'a': 'The Dashboard map and Pick-Up list highlight verified regional recycling units close to your location.',
          },
          {
            'q': 'How to maximize earnings from iron scrap?',
            'a': 'Remove heavy rust, soil, and non-metal attachments. Heavy structural iron commands higher pricing.',
          },
          {
            'q': 'How do I change the app language?',
            'a': 'Open Settings from the top bar to switch seamlessly between English, Hindi, and Marathi.',
          },
        ];
    }
  }

  Future<void> _speak(String text) async {
    await tts.stop();
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

  void _onQuestionSelected(String question, String answer) {
    setState(() {
      _messages.add(ChatMessage(text: question, isUser: true));
      _messages.add(
        ChatMessage(text: answer, isUser: false, audioText: answer),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppThemeColors.faint(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activeAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    size: 36,
                    color: AppColors.mintGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recy AI Assistant',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppThemeColors.text(context),
                        ),
                      ),
                      Text(
                        'Your Recycling Guide',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppThemeColors.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),
            // Chat message area
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isUser
                            ? activeAccent
                            : activeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(14),
                          topRight: const Radius.circular(14),
                          bottomLeft: Radius.circular(msg.isUser ? 14 : 2),
                          bottomRight: Radius.circular(msg.isUser ? 2 : 14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: msg.isUser
                                    ? AppColors.darkBackground
                                    : AppThemeColors.text(context),
                                fontWeight: msg.isUser
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (!msg.isUser && msg.audioText != null) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _speak(msg.audioText!),
                              child: const Icon(
                                Icons.volume_up,
                                size: 18,
                                color: AppColors.mintGreen,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 16),
            Text(
              'Select a question:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppThemeColors.text(context),
              ),
            ),
            const SizedBox(height: 8),
            // Options list
            SizedBox(
              height: 140,
              child: ListView.builder(
                itemCount: questionsAndAnswers.length,
                itemBuilder: (context, index) {
                  final item = questionsAndAnswers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _onQuestionSelected(item['q']!, item['a']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppThemeColors.background(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: activeAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              size: 16,
                              color: activeAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item['q']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppThemeColors.text(context),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: AppThemeColors.faint(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
