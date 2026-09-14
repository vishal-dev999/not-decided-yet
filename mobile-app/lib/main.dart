import 'package:flutter/material.dart';

void main() {
  runApp(const ReNovaApp());
}

// ============================================================
// APP
// ============================================================

class ReNovaApp extends StatelessWidget {
  const ReNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReNova',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF7F9F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B5B),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

// ============================================================
// LANGUAGE
// ============================================================

enum AppLanguage {
  english,
  hindi,
  marathi,
}

AppLanguage selectedLanguage = AppLanguage.english;

class AppText {
  static final Map<String, Map<AppLanguage, String>> translations = {
    'welcome': {
      AppLanguage.english: 'WELCOME TO ReNova',
      AppLanguage.hindi: 'ReNova में आपका स्वागत है',
      AppLanguage.marathi: 'ReNova मध्ये आपले स्वागत आहे',
    },
    'enter_name': {
      AppLanguage.english: 'Enter your name',
      AppLanguage.hindi: 'अपना नाम दर्ज करें',
      AppLanguage.marathi: 'तुमचे नाव लिहा',
    },
    'continue': {
      AppLanguage.english: 'Continue',
      AppLanguage.hindi: 'आगे बढ़ें',
      AppLanguage.marathi: 'पुढे चला',
    },
    'dashboard': {
      AppLanguage.english: 'Dashboard',
      AppLanguage.hindi: 'डैशबोर्ड',
      AppLanguage.marathi: 'डॅशबोर्ड',
    },
    'earnings': {
      AppLanguage.english: 'Total Earnings',
      AppLanguage.hindi: 'कुल कमाई',
      AppLanguage.marathi: 'एकूण कमाई',
    },
    'kg_collected': {
      AppLanguage.english: 'KG Collected',
      AppLanguage.hindi: 'एकत्रित KG',
      AppLanguage.marathi: 'गोळा केलेले KG',
    },
    'pickups': {
      AppLanguage.english: 'Pickups',
      AppLanguage.hindi: 'पिकअप',
      AppLanguage.marathi: 'पिकअप',
    },
    'recent_activity': {
      AppLanguage.english: 'Recent Activity',
      AppLanguage.hindi: 'हाल की गतिविधि',
      AppLanguage.marathi: 'अलीकडील व्यवहार',
    },
    'my_earnings': {
      AppLanguage.english: 'My Earnings',
      AppLanguage.hindi: 'मेरी कमाई',
      AppLanguage.marathi: 'माझी कमाई',
    },
    'upload': {
      AppLanguage.english: 'Upload',
      AppLanguage.hindi: 'अपलोड',
      AppLanguage.marathi: 'अपलोड',
    },
    'prices': {
      AppLanguage.english: 'Prices',
      AppLanguage.hindi: 'कीमतें',
      AppLanguage.marathi: 'किंमती',
    },
    'profile': {
      AppLanguage.english: 'Profile',
      AppLanguage.hindi: 'प्रोफ़ाइल',
      AppLanguage.marathi: 'प्रोफाइल',
    },
    'choose_language': {
      AppLanguage.english: 'Choose Language',
      AppLanguage.hindi: 'भाषा चुनें',
      AppLanguage.marathi: 'भाषा निवडा',
    },
    'today': {
      AppLanguage.english: 'Today',
      AppLanguage.hindi: 'आज',
      AppLanguage.marathi: 'आज',
    },
    'week': {
      AppLanguage.english: 'Week',
      AppLanguage.hindi: 'सप्ताह',
      AppLanguage.marathi: 'आठवडा',
    },
    'month': {
      AppLanguage.english: 'Month',
      AppLanguage.hindi: 'महीना',
      AppLanguage.marathi: 'महिना',
    },
    'upload_title': {
      AppLanguage.english: 'Upload Material',
      AppLanguage.hindi: 'सामग्री अपलोड करें',
      AppLanguage.marathi: 'साहित्य अपलोड करा',
    },
    'upload_message': {
      AppLanguage.english:
          'Material upload will be available soon.',
      AppLanguage.hindi:
          'सामग्री अपलोड सुविधा जल्द उपलब्ध होगी।',
      AppLanguage.marathi:
          'साहित्य अपलोड करण्याची सुविधा लवकरच उपलब्ध होईल.',
    },
    'material_prices': {
      AppLanguage.english: 'Material Prices',
      AppLanguage.hindi: 'सामग्री की कीमतें',
      AppLanguage.marathi: 'साहित्याच्या किंमती',
    },
  };

  static String get(String key) {
    return translations[key]?[selectedLanguage] ??
        translations[key]?[AppLanguage.english] ??
        key;
  }
}

// ============================================================
// LOGIN PAGE
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nameController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF092B2A),
              Color(0xFF124E4A),
              Color(0xFF176B5B),
              Color(0xFFB9877E),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: _circle(
                  230,
                  Colors.white.withOpacity(0.07),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -70,
                child: _circle(
                  260,
                  Colors.white.withOpacity(0.06),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // LOGO
                      Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.recycling_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'ReNova',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        AppText.get('welcome'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // LOGIN CARD
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppText.get('enter_name'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF174A43),
                              ),
                            ),

                            const SizedBox(height: 10),

                            TextField(
                              controller: nameController,
                              textCapitalization:
                                  TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: 'Your name',
                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                ),
                                filled: true,
                                fillColor:
                                    const Color(0xFFF2F7F5),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(17),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            Text(
                              AppText.get('choose_language'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF174A43),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                _languageButton(
                                  'English',
                                  AppLanguage.english,
                                ),
                                const SizedBox(width: 7),
                                _languageButton(
                                  'हिन्दी',
                                  AppLanguage.hindi,
                                ),
                                const SizedBox(width: 7),
                                _languageButton(
                                  'मराठी',
                                  AppLanguage.marathi,
                                ),
                              ],
                            ),

                            const SizedBox(height: 26),

                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: _continue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF176B5B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(17),
                                  ),
                                ),
                                child: Text(
                                  AppText.get('continue'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Recycle • Earn • Renew',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 1,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continue() {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          userName: nameController.text.trim(),
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _languageButton(
    String text,
    AppLanguage language,
  ) {
    final bool selected = selectedLanguage == language;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedLanguage = language;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF176B5B)
                : const Color(0xFFEAF2EF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected
                    ? Colors.white
                    : const Color(0xFF176B5B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME PAGE + BOTTOM NAVIGATION
// ============================================================

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({
    super.key,
    required this.userName,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(userName: widget.userName),
      const UploadPage(),
      const PricesPage(),
      const EarningsPage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFD8EEE8),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: AppText.get('dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.cloud_upload_outlined),
            selectedIcon:
                const Icon(Icons.cloud_upload),
            label: AppText.get('upload'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.sell_outlined),
            selectedIcon: const Icon(Icons.sell),
            label: AppText.get('prices'),
          ),
          NavigationDestination(
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
            ),
            selectedIcon: const Icon(
              Icons.account_balance_wallet,
            ),
            label: AppText.get('earnings'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage extends StatelessWidget {
  final String userName;

  const DashboardPage({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $userName 👋',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF173C37),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        AppText.get('dashboard'),
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5F1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ProfilePage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF176B5B),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // EARNINGS + KG
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: AppText.get('earnings'),
                    value: '₹12,850',
                    icon: Icons.currency_rupee,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    title: AppText.get('kg_collected'),
                    value: '486 KG',
                    icon: Icons.scale_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // PICKUPS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF176B5B),
                    Color(0xFF258B77),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppText.get('pickups'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: [
                      _pickupStat(
                        AppText.get('today'),
                        '4',
                      ),
                      _pickupStat(
                        AppText.get('week'),
                        '21',
                      ),
                      _pickupStat(
                        AppText.get('month'),
                        '83',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // RECENT ACTIVITY
            Text(
              AppText.get('recent_activity'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF173C37),
              ),
            ),

            const SizedBox(height: 12),

            _activity(
              Icons.phone_android,
              'E-waste pickup',
              '12.5 KG • Today',
              '₹1,250',
            ),

            _activity(
              Icons.computer,
              'Computer parts',
              '8 KG • Yesterday',
              '₹720',
            ),

            _activity(
              Icons.recycling,
              'Mixed scrap',
              '22 KG • 10 Sep',
              '₹1,480',
            ),

            const SizedBox(height: 20),

            // MY EARNINGS
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const EarningsPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7EFEC),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB36B5D),
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppText.get('my_earnings'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'View daily, weekly & monthly earnings',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF176B5B),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF173C37),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickupStat(
    String title,
    String value,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _activity(
    IconData icon,
    String title,
    String subtitle,
    String amount,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8EFEC),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F5F1),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF176B5B),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF176B5B),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// UPLOAD PAGE - UI ONLY
// ============================================================

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            Text(
              AppText.get('upload_title'),
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: Color(0xFF173C37),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              AppText.get('upload_message'),
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFE3EBE8),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 120,
                        width: 120,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5F1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          size: 65,
                          color: Color(0xFF176B5B),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Text(
                        AppText.get('upload_title'),
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        AppText.get('upload_message'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Upload feature will be added later.',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF176B5B),
                            foregroundColor: Colors.white,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppText.get('upload'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PRICES PAGE
// ============================================================

class PricesPage extends StatelessWidget {
  const PricesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prices = [
      ['Copper', '₹720/kg', '+4.5%'],
      ['Aluminium', '₹185/kg', '+2.1%'],
      ['Iron', '₹38/kg', '-1.2%'],
      ['E-waste', '₹210/kg', '+5.8%'],
      ['Brass', '₹480/kg', '+3.2%'],
      ['Lead', '₹145/kg', '-0.8%'],
      ['Plastic', '₹42/kg', '+1.5%'],
      ['PCB', '₹650/kg', '+7.2%'],
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              AppText.get('material_prices'),
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: Color(0xFF173C37),
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Current demonstration prices',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF176B5B),
                    Color(0xFF2D907A),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(23),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 35,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Prices',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Market rates',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ...prices.map(
              (item) => Container(
                margin: const EdgeInsets.only(
                  bottom: 11,
                ),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE6EEEB),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F1),
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.recycling,
                        color: Color(0xFF176B5B),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text(
                          item[1],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item[2],
                          style: TextStyle(
                            color: item[2]
                                    .startsWith('+')
                                ? Colors.green
                                : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EARNINGS PAGE
// ============================================================

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              AppText.get('my_earnings'),
              style: const TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: Color(0xFF173C37),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Track your earnings over time',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            _earningCard(
              'Today',
              '₹1,850',
              Icons.today,
            ),

            _earningCard(
              'This Week',
              '₹8,420',
              Icons.date_range,
            ),

            _earningCard(
              'This Month',
              '₹12,850',
              Icons.calendar_month,
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8F7),
                borderRadius:
                    BorderRadius.circular(23),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: [
                      _bar('M', 0.55),
                      _bar('T', 0.75),
                      _bar('W', 0.45),
                      _bar('T', 0.90),
                      _bar('F', 0.70),
                      _bar('S', 0.95),
                      _bar('S', 0.65),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _earningCard(
    String title,
    String amount,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F1),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF176B5B),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF176B5B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(
    String day,
    double height,
  ) {
    return Column(
      children: [
        Container(
          height: 130 * height,
          width: 25,
          decoration: BoxDecoration(
            color: const Color(0xFF176B5B),
            borderRadius:
                BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          day,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROFILE PAGE
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppText.get('profile')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 45,
            backgroundColor: Color(0xFFE8F5F1),
            child: Icon(
              Icons.person,
              size: 45,
              color: Color(0xFF176B5B),
            ),
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              'ReNova Collector',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 30),

          _option(
            Icons.language,
            'Language',
            selectedLanguage ==
                    AppLanguage.english
                ? 'English'
                : selectedLanguage ==
                        AppLanguage.hindi
                    ? 'Hindi'
                    : 'Marathi',
          ),

          _option(
            Icons.notifications_outlined,
            'Notifications',
            'Enabled',
          ),

          _option(
            Icons.security_outlined,
            'Privacy & Security',
            '',
          ),

          _option(
            Icons.help_outline,
            'Help & Support',
            '',
          ),
        ],
      ),
    );
  }

  Widget _option(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
        tileColor: const Color(0xFFF7F9F8),
        leading: Icon(
          icon,
          color: const Color(0xFF176B5B),
        ),
        title: Text(title),
        subtitle: subtitle.isEmpty
            ? null
            : Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 15,
        ),
      ),
    );
  }
}
