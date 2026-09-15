import 'package:flutter/material.dart';

import '../screens/login_page.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B5B)),
      ),
      home: const LoginPage(),
    );
  }
}

