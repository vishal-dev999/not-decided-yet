import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_enums.dart';

class RecyclerNearbyScreen extends StatefulWidget {
  final AppLanguage language;

  const RecyclerNearbyScreen({
    super.key,
    required this.language,
  });

  @override
  State<RecyclerNearbyScreen> createState() => _RecyclerNearbyScreenState();
}

class _RecyclerNearbyScreenState extends State<RecyclerNearbyScreen> {
  static const double searchRadiusKm = 6.0;

  bool _isLoading = true;
  String? _errorMessage;

  Position? _currentPosition;
  String _currentLocationName = 'Detecting location...';

  List<Recycler> _nearbyRecyclers = [];

  // Dummy recycler data.
  // Their coordinates are used for real distance calculations.
  final List<Recycler> _dummyRecyclers = const [
    Recycler(
      name: 'Green Earth Recycling',
      latitude: 20.2961,
      longitude: 85.8245,
      location: 'Bhubaneswar',
      materials: ['Plastic', 'Paper', 'Metal'],
    ),
    Recycler(
      name: 'Eco Waste Solutions',
      latitude: 20.2700,
      longitude: 85.8400,
      location: 'Bhubaneswar',
      materials: ['E-Waste', 'Plastic'],
    ),
    Recycler(
      name: 'Kalinga Scrap Recycling',
      latitude: 20.3050,
      longitude: 85.8100,
      location: 'Bhubaneswar',
      materials: ['Iron', 'Steel', 'Aluminium'],
    ),
    Recycler(
      name: 'Clean Odisha Recyclers',
      latitude: 20.2500,
      longitude: 85.8200,
      location: 'Bhubaneswar',
      materials: ['Glass', 'Plastic', 'Paper'],
    ),
    Recycler(
      name: 'Green Loop Recycling',
      latitude: 20.3300,
      longitude: 85.8500,
      location: 'Bhubaneswar',
      materials: ['Plastic', 'Metal', 'Cardboard'],
    ),
  ];

  // ------------------------------------------------------------
  // LOCALIZATION
  // ------------------------------------------------------------

  String _t(String english, String hindi, String marathi) {
    switch (widget.language) {
      case AppLanguage.hindi:
        return hindi;
      case AppLanguage.marathi:
        return marathi;
      case AppLanguage.english:
        return english;
    }
  }

  @override
  void initState() {
    super.initState();
    _findNearbyRecyclers();
  }

  Future<void> _findNearbyRecyclers() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check whether location services are enabled.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          _t(
            'Location services are turned off. Please turn on GPS and try again.',
            'लोकेशन सेवा बंद है। कृपया GPS चालू करें और फिर से प्रयास करें।',
            'लोकेशन सेवा बंद आहे. कृपया GPS सुरू करा आणि पुन्हा प्रयत्न करा.',
          ),
        );
      }

      // Check current permission.
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          _t(
            'Location permission was denied. Please allow location access.',
            'लोकेशन की अनुमति अस्वीकार कर दी गई। कृपया लोकेशन की अनुमति दें।',
            'लोकेशनची परवानगी नाकारण्यात आली. कृपया लोकेशनची परवानगी द्या.',
          ),
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          _t(
            'Location permission is permanently denied. Please enable it from app settings.',
            'लोकेशन की अनुमति स्थायी रूप से बंद है। कृपया ऐप सेटिंग्स से इसे सक्षम करें।',
            'लोकेशनची परवानगी कायमची नाकारली आहे. कृपया ॲप सेटिंग्जमधून ती सक्षम करा.',
          ),
        );
      }

      // Get the real device location.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String locationName = _t(
        'Current Location',
        'वर्तमान स्थान',
        'सध्याचे स्थान',
      );

      // Convert GPS coordinates into a readable location name.
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          final parts = <String>[];

          if ((place.subLocality ?? '').trim().isNotEmpty) {
            parts.add(place.subLocality!.trim());
          } else if ((place.locality ?? '').trim().isNotEmpty) {
            parts.add(place.locality!.trim());
          }

          if ((place.locality ?? '').trim().isNotEmpty &&
              !parts.contains(place.locality!.trim())) {
            parts.add(place.locality!.trim());
          }

          if ((place.administrativeArea ?? '').trim().isNotEmpty &&
              !parts.contains(place.administrativeArea!.trim())) {
            parts.add(place.administrativeArea!.trim());
          }

          if (parts.isNotEmpty) {
            locationName = parts.join(', ');
          } else if ((place.name ?? '').trim().isNotEmpty) {
            locationName = place.name!.trim();
          }
        }
      } catch (_) {
        // GPS still works even if reverse geocoding fails.
        locationName =
            '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';
      }

      // Calculate distances from actual user location to dummy recyclers.
      final recyclers = _dummyRecyclers
          .map(
            (recycler) {
              final distanceMeters = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                recycler.latitude,
                recycler.longitude,
              );

              return recycler.copyWith(
                distanceKm: distanceMeters / 1000,
              );
            },
          )
          .where(
            (recycler) =>
                recycler.distanceKm != null &&
                recycler.distanceKm! <= searchRadiusKm,
          )
          .toList();

      // Nearest recycler first.
      recyclers.sort(
        (a, b) => (a.distanceKm ?? double.infinity).compareTo(
          b.distanceKm ?? double.infinity,
        ),
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _currentLocationName = locationName;
        _nearbyRecyclers = recyclers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t(
            'Recycler Nearby',
            'पास के रीसायक्लर',
            'जवळचे रिसायकलर',
          ),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _t(
              'Refresh',
              'रिफ्रेश',
              'रिफ्रेश',
            ),
            onPressed: _isLoading ? null : _findNearbyRecyclers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _t(
                        'Detecting your location...',
                        'आपका स्थान पता लगाया जा रहा है...',
                        'तुमचे स्थान शोधले जात आहे...',
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _findNearbyRecyclers,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationCard(theme, isDark),
                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        _buildErrorCard(theme, isDark)
                      else ...[
                        _buildRadiusVisualization(theme, isDark),
                        const SizedBox(height: 20),
                        _buildNearbyHeader(theme),
                        const SizedBox(height: 10),
                        _buildRecyclerList(theme, isDark),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLocationCard(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: theme.colorScheme.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(
                    'Your Location',
                    'आपका स्थान',
                    'तुमचे स्थान',
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentLocationName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _t(
                    'GPS location detected • Searching within 6 km',
                    'GPS स्थान मिल गया • 6 किमी के अंदर खोजा जा रहा है',
                    'GPS स्थान शोधले • 6 किमीच्या आत शोध सुरू आहे',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, bool isDark) {
    final isPermissionError =
        _errorMessage?.toLowerCase().contains('permission') ?? false;

    final isLocationError =
        _errorMessage?.toLowerCase().contains('location services') ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.location_off,
            color: Colors.red,
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            _t(
              'Unable to detect location',
              'स्थान का पता लगाने में असमर्थ',
              'स्थान शोधता आले नाही',
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ??
                _t(
                  'Something went wrong while getting your location.',
                  'आपका स्थान प्राप्त करते समय कुछ गलत हो गया।',
                  'तुमचे स्थान मिळवताना काहीतरी चूक झाली.',
                ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (isLocationError)
                OutlinedButton.icon(
                  onPressed: _openLocationSettings,
                  icon: const Icon(Icons.gps_fixed),
                  label: Text(
                    _t(
                      'Turn On GPS',
                      'GPS चालू करें',
                      'GPS सुरू करा',
                    ),
                  ),
                ),
              if (isPermissionError)
                OutlinedButton.icon(
                  onPressed: _openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: Text(
                    _t(
                      'App Settings',
                      'ऐप सेटिंग्स',
                      'ॲप सेटिंग्ज',
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: _findNearbyRecyclers,
                icon: const Icon(Icons.refresh),
                label: Text(
                  _t(
                    'Try Again',
                    'फिर से प्रयास करें',
                    'पुन्हा प्रयत्न करा',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusVisualization(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radar,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t(
                    'Recycler Search Radius',
                    'रीसायक्लर खोज क्षेत्र',
                    'रिसायकलर शोध क्षेत्र',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '6 km',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 260,
            width: double.infinity,
            child: CustomPaint(
              painter: RecyclerRadiusPainter(
                userLatitude: _currentPosition?.latitude ?? 0,
                userLongitude: _currentPosition?.longitude ?? 0,
                recyclers: _nearbyRecyclers,
                isDark: isDark,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(
                color: Colors.red,
                label: _t(
                  'You',
                  'आप',
                  'तुम्ही',
                ),
              ),
              const SizedBox(width: 22),
              _buildLegendDot(
                color: Colors.green,
                label: _t(
                  'Recycler',
                  'रीसायक्लर',
                  'रिसायकलर',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyHeader(ThemeData theme) {
    return Row(
      children: [
        Text(
          _t(
            'Nearby Recyclers',
            'पास के रीसायक्लर',
            'जवळचे रिसायकलर',
          ),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          _nearbyRecyclers.isEmpty
              ? _t(
                  '0 found',
                  '0 मिले',
                  '0 सापडले',
                )
              : _t(
                  '${_nearbyRecyclers.length} found',
                  '${_nearbyRecyclers.length} मिले',
                  '${_nearbyRecyclers.length} सापडले',
                ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecyclerList(ThemeData theme, bool isDark) {
    if (_nearbyRecyclers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 42,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              _t(
                'No recyclers found within 6 km',
                '6 किमी के अंदर कोई रीसायक्लर नहीं मिला',
                '6 किमीच्या आत कोणताही रिसायकलर सापडला नाही',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _t(
                'Try refreshing your location or expanding the search radius later.',
                'अपना स्थान रिफ्रेश करने या बाद में खोज क्षेत्र बढ़ाने का प्रयास करें।',
                'तुमचे स्थान रिफ्रेश करा किंवा नंतर शोध क्षेत्र वाढवून पहा.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _nearbyRecyclers.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final recycler = _nearbyRecyclers[index];

        return _buildRecyclerCard(
          recycler,
          theme,
          isDark,
          index,
        );
      },
    );
  }

  Widget _buildRecyclerCard(
    Recycler recycler,
    ThemeData theme,
    bool isDark,
    int index,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.recycling,
                  color: Colors.green,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recycler.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            recycler.location,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatDistance(recycler.distanceKm),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: recycler.materials.map((material) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  material,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) {
      return '--';
    }

    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }

    return '${distanceKm.toStringAsFixed(1)} km';
  }
}

class Recycler {
  final String name;
  final double latitude;
  final double longitude;
  final String location;
  final List<String> materials;
  final double? distanceKm;

  const Recycler({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.materials,
    this.distanceKm,
  });

  Recycler copyWith({
    String? name,
    double? latitude,
    double? longitude,
    String? location,
    List<String>? materials,
    double? distanceKm,
  }) {
    return Recycler(
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      materials: materials ?? this.materials,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}

class RecyclerRadiusPainter extends CustomPainter {
  final double userLatitude;
  final double userLongitude;
  final List<Recycler> recyclers;
  final bool isDark;

  const RecyclerRadiusPainter({
    required this.userLatitude,
    required this.userLongitude,
    required this.recyclers,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    // Keep the circle comfortably inside the card.
    final radius = math.min(size.width, size.height) * 0.38;

    // Background.
    final backgroundPaint = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.12)
          : Colors.grey.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Offset.zero & size,
      backgroundPaint,
    );

    // Radius fill.
    final radiusFillPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      radius,
      radiusFillPaint,
    );

    // Radius border.
    final radiusBorderPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      center,
      radius,
      radiusBorderPaint,
    );

    // Small distance rings.
    final ringPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      center,
      radius * 0.66,
      ringPaint,
    );

    canvas.drawCircle(
      center,
      radius * 0.33,
      ringPaint,
    );

    // Convert recycler coordinates into positions relative to user.
    for (final recycler in recyclers) {
      final distanceKm = recycler.distanceKm ?? 0;

      if (distanceKm > 6) {
        continue;
      }

      final bearing = _calculateBearing(
        userLatitude,
        userLongitude,
        recycler.latitude,
        recycler.longitude,
      );

      final distanceRatio = distanceKm / 6.0;

      // Slightly reduce the ratio so dots stay inside the radius.
      final visualDistance = radius * distanceRatio * 0.88;

      final angle = bearing * math.pi / 180;

      final dx = math.sin(angle) * visualDistance;
      final dy = -math.cos(angle) * visualDistance;

      final point = Offset(
        center.dx + dx,
        center.dy + dy,
      );

      // Green outer circle.
      final recyclerOuterPaint = Paint()
        ..color = Colors.green.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        point,
        11,
        recyclerOuterPaint,
      );

      // Green recycler dot.
      final recyclerPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        point,
        6,
        recyclerPaint,
      );
    }

    // User location outer circle.
    final userOuterPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      14,
      userOuterPaint,
    );

    // User location dot.
    final userPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      7,
      userPaint,
    );

    // "YOU" label.
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'YOU',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + 18,
      ),
    );

    // 6 km label.
    final radiusTextPainter = TextPainter(
      text: const TextSpan(
        text: '6 km radius',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    radiusTextPainter.paint(
      canvas,
      Offset(
        center.dx - radiusTextPainter.width / 2,
        center.dy - radius - 18,
      ),
    );
  }

  double _calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final startLat = _toRadians(startLatitude);
    final endLat = _toRadians(endLatitude);

    final deltaLongitude = _toRadians(
      endLongitude - startLongitude,
    );

    final y = math.sin(deltaLongitude) * math.cos(endLat);

    final x =
        math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) *
            math.cos(endLat) *
            math.cos(deltaLongitude);

    final bearing = math.atan2(y, x) * 180 / math.pi;

    return (bearing + 360) % 360;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  @override
  bool shouldRepaint(covariant RecyclerRadiusPainter oldDelegate) {
    return oldDelegate.userLatitude != userLatitude ||
        oldDelegate.userLongitude != userLongitude ||
        oldDelegate.recyclers != recyclers ||
        oldDelegate.isDark != isDark;
  }
}
