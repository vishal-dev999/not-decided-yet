import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_text.dart';

class MiniSparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;

  MiniSparklinePainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    final dx = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * dx;
      final normalizedY = (points[i] - minVal) / range;
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PricesPage extends StatefulWidget {
  const PricesPage({super.key});

  @override
  State<PricesPage> createState() => _PricesPageState();
}

class _PricesPageState extends State<PricesPage> {
  bool _isLoading = true;
  String _lastUpdated = 'Loading...';
  String _cluster = 'Bhubaneswar-Cuttack Cluster';
  List<Map<String, dynamic>> _materials = [];

  @override
  void initState() {
    super.initState();
    _loadBenchmarks();
  }

  Future<void> _loadBenchmarks() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/price_benchmarks.json',
      );
      final Map<String, dynamic> data = jsonDecode(jsonString);

      setState(() {
        _lastUpdated = data['last_updated'] ?? 'Recent';
        _cluster = data['cluster_reference'] ?? 'Bhubaneswar-Cuttack Cluster';
        _materials = List<Map<String, dynamic>>.from(data['materials'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'PCB':
        return Icons.memory;
      case 'CABLE':
        return Icons.cable;
      case 'BATTERY':
        return Icons.battery_charging_full;
      case 'DISPLAY':
        return Icons.tv;
      case 'PLASTIC':
        return Icons.layers_outlined;
      default:
        return Icons.recycling;
    }
  }

  void _showPriceBreakdownSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final double recyclerPrice = (item['recycler_price'] as num).toDouble();
        final double mandiPrice = (item['mandi_price'] as num).toDouble();
        final double directBenefit = (item['direct_benefit_inr'] as num)
            .toDouble();
        final double benefitPct = (item['direct_benefit_pct'] as num)
            .toDouble();
        final double minRange = (item['market_range_min'] as num).toDouble();
        final double maxRange = (item['market_range_max'] as num).toDouble();
        final double trend30d = (item['trend_30d_pct'] as num).toDouble();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['display_name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF173C37),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Unit: ${item['unit']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF176B5B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Benefit card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.green.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Formal Recycler Direct Gain',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '+₹${directBenefit.toStringAsFixed(2)} / ${item['unit']} (+${benefitPct.toStringAsFixed(1)}% vs. Middleman)',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Detail Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailStatBox(
                      'Formal Recycler',
                      '₹${recyclerPrice.toStringAsFixed(2)}',
                      const Color(0xFF176B5B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailStatBox(
                      'Informal Mandi',
                      '₹${mandiPrice.toStringAsFixed(2)}',
                      Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDetailStatBox(
                      'Fair Market Corridor',
                      '₹${minRange.toStringAsFixed(0)} - ₹${maxRange.toStringAsFixed(0)}',
                      Colors.blueGrey.shade800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailStatBox(
                      '30-Day Momentum',
                      '${trend30d >= 0 ? '+' : ''}${trend30d.toStringAsFixed(1)}%',
                      trend30d >= 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailStatBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF176B5B)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppText.get('material_prices'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF173C37),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _cluster,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Header Banner Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF176B5B), Color(0xFF2D907A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF176B5B).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insights,
                          color: Colors.white,
                          size: 36,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Formal Recycler Benchmark',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Verified rates vs. informal middlemen • Updated $_lastUpdated',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Material Price List
                  ..._materials.map((item) {
                    final double recyclerPrice = (item['recycler_price'] as num)
                        .toDouble();
                    final double mandiPrice = (item['mandi_price'] as num)
                        .toDouble();
                    final double trend7d = (item['trend_7d_pct'] as num)
                        .toDouble();
                    final double directBenefit =
                        (item['direct_benefit_inr'] as num).toDouble();
                    final List<double> sparkline =
                        (item['sparkline_7d'] as List<dynamic>)
                            .map((e) => (e as num).toDouble())
                            .toList();

                    final isUp = trend7d >= 0;

                    return InkWell(
                      onTap: () => _showPriceBreakdownSheet(item),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE6EEEB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Category Icon
                            Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5F1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getCategoryIcon(
                                  item['material_category'] ?? '',
                                ),
                                color: const Color(0xFF176B5B),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Material Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['display_name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF173C37),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Mandi: ₹${mandiPrice.toStringAsFixed(0)}/${item['unit']}',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '+₹${directBenefit.toStringAsFixed(0)} direct gain',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Mini Sparkline Graph
                            SizedBox(
                              width: 55,
                              height: 28,
                              child: CustomPaint(
                                painter: MiniSparklinePainter(
                                  points: sparkline,
                                  lineColor: isUp
                                      ? Colors.green
                                      : Colors.redAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Pricing & Trend Chip
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${recyclerPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF176B5B),
                                  ),
                                ),
                                Text(
                                  'per ${item['unit']}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUp
                                        ? Colors.green.shade50
                                        : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isUp
                                            ? Icons.arrow_drop_up
                                            : Icons.arrow_drop_down,
                                        size: 14,
                                        color: isUp
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                      Text(
                                        '${trend7d >= 0 ? '+' : ''}${trend7d.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isUp
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
