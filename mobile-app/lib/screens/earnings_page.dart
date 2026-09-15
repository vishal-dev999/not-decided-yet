import 'package:flutter/material.dart';

import '../constants/app_text.dart';

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            _earningCard('Today', '₹1,850', Icons.today),

            _earningCard('This Week', '₹8,420', Icons.date_range),

            _earningCard('This Month', '₹12,850', Icons.calendar_month),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8F7),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
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

  Widget _earningCard(String title, String amount, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: const Color(0xFF176B5B)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _bar(String day, double height) {
    return Column(
      children: [
        Container(
          height: 130 * height,
          width: 25,
          decoration: BoxDecoration(
            color: const Color(0xFF176B5B),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 7),
        Text(day, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
