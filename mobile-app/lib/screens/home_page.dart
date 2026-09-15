import 'package:flutter/material.dart';

import '../constants/app_text.dart';
import 'dashboard.dart';
import 'uploads_page.dart';
import 'earnings_page.dart';
import 'prices_page.dart';

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

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
            selectedIcon: const Icon(Icons.cloud_upload),
            label: AppText.get('upload'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.sell_outlined),
            selectedIcon: const Icon(Icons.sell),
            label: AppText.get('prices'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: AppText.get('earnings'),
          ),
        ],
      ),
    );
  }
}
