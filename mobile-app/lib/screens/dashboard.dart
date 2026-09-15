import 'package:flutter/material.dart';

import '../constants/app_text.dart';
import 'profile_page.dart';
import 'earnings_page.dart';

class DashboardPage extends StatelessWidget {
  final String userName;

  const DashboardPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: const TextStyle(color: Colors.grey),
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
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
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
                  colors: [Color(0xFF176B5B), Color(0xFF258B77)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _pickupStat(AppText.get('today'), '4'),
                      _pickupStat(AppText.get('week'), '21'),
                      _pickupStat(AppText.get('month'), '83'),
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
                  MaterialPageRoute(builder: (_) => const EarningsPage()),
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
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF176B5B)),
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
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _pickupStat(String title, String value) {
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
        Text(title, style: const TextStyle(color: Colors.white70)),
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
        border: Border.all(color: const Color(0xFFE8EFEC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F5F1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFF176B5B)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
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
