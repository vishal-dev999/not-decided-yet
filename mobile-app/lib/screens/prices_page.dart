import 'package:flutter/material.dart';

import '../constants/app_text.dart';

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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF176B5B), Color(0xFF2D907A)],
                ),
                borderRadius: BorderRadius.circular(23),
              ),
              child: const Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.white, size: 35),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Prices',
                          style: TextStyle(color: Colors.white70),
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
                margin: const EdgeInsets.only(bottom: 11),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE6EEEB)),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5F1),
                        borderRadius: BorderRadius.circular(13),
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
                      crossAxisAlignment: CrossAxisAlignment.end,
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
                            color: item[2].startsWith('+')
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
