import 'package:flutter/material.dart';

import '../constants/app_text.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppText.get('profile'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 45,
            backgroundColor: Color(0xFFE8F5F1),
            child: Icon(Icons.person, size: 45, color: Color(0xFF176B5B)),
          ),

          const SizedBox(height: 15),

          const Center(
            child: Text(
              'ReNova Collector',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 30),

          _option(
            Icons.language,
            'Language',
            selectedLanguage == AppLanguage.english
                ? 'English'
                : selectedLanguage == AppLanguage.hindi
                ? 'Hindi'
                : 'Marathi',
          ),

          _option(Icons.notifications_outlined, 'Notifications', 'Enabled'),

          _option(Icons.security_outlined, 'Privacy & Security', ''),

          _option(Icons.help_outline, 'Help & Support', ''),
        ],
      ),
    );
  }

  Widget _option(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        tileColor: const Color(0xFFF7F9F8),
        leading: Icon(icon, color: const Color(0xFF176B5B)),
        title: Text(title),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 15),
      ),
    );
  }
}
