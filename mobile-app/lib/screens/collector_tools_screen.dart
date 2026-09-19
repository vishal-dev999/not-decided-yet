import 'package:flutter/material.dart';

import '../constants/app_enums.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';

class CollectorToolsScreen extends StatelessWidget {
  final AppLanguage language;

  const CollectorToolsScreen({super.key, required this.language});

  String _t(String en, String hi, String mr) {
    switch (language) {
      case AppLanguage.hindi:
        return hi;
      case AppLanguage.marathi:
        return mr;
      case AppLanguage.english:
      default:
        return en;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('Collector Tools', 'कलेक्टर टूल्स', 'कलेक्टर टूल्स')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _toolCard(
            context,
            Icons.location_on,
            _t('Recyclers Nearby', 'पास के रीसायकलर', 'जवळचे रीसायकलर'),
            _t(
              'View nearby recycler options for the prototype.',
              'प्रोटोटाइप में पास के रीसायकलर विकल्प देखें।',
              'प्रोटोटाइपमधील जवळचे रीसायकलर पर्याय पहा.',
            ),
            () => _showNearbyRecyclers(context, activeAccent),
          ),
        ],
      ),
    );
  }

  Widget _toolCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final activeAccent = AppThemeColors.isDark(context)
        ? AppColors.primaryGold
        : AppColors.featherGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppThemeColors.card(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 27,
          backgroundColor: activeAccent.withValues(alpha: 0.15),
          child: Icon(icon, color: activeAccent),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showNearbyRecyclers(BuildContext context, Color accent) {
    final recyclers = [
      ['EcoRecycle Ltd', '1.2 km', 'E-Waste • PCB • Batteries'],
      ['GreenLoop Recycling', '2.4 km', 'E-Waste • Metals • Plastics'],
      ['ReCircle Hub', '3.1 km', 'Electronics • Mixed Scrap'],
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeColors.card(context),
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _t('Recyclers Nearby', 'पास के रीसायकलर', 'जवळचे रीसायकलर'),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 12),
            ...recyclers.map(
              (r) => Card(
                child: ListTile(
                  leading: Icon(Icons.recycling, color: accent),
                  title: Text(r[0]),
                  subtitle: Text('${r[1]} • ${r[2]}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
