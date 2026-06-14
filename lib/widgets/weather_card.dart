import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

/// Maps a Google Weather API conditionType enum value to a CupertinoIcons icon.
/// Falls back to fuzzy description matching when conditionType is empty.
IconData _iconForCondition(String conditionType, {String description = ''}) {
  switch (conditionType) {
    case 'CLEAR':
    case 'MOSTLY_CLEAR':
      return CupertinoIcons.sun_max_fill;
    case 'PARTLY_CLOUDY':
      return CupertinoIcons.cloud_sun_fill;
    case 'MOSTLY_CLOUDY':
    case 'CLOUDY':
      return CupertinoIcons.cloud_fill;
    case 'WINDY':
      return CupertinoIcons.wind;
    case 'FOGGY':
      return CupertinoIcons.cloud_fog_fill;
    case 'RAINY':
    case 'SHOWERS':
      return CupertinoIcons.cloud_rain_fill;
    case 'DRIZZLE':
      return CupertinoIcons.cloud_drizzle_fill;
    case 'HEAVY_RAIN':
      return CupertinoIcons.cloud_heavyrain_fill;
    case 'SNOWY':
      return CupertinoIcons.cloud_snow_fill;
    case 'THUNDERSTORM':
      return CupertinoIcons.cloud_bolt_rain_fill;
    default:
      // Fallback: fuzzy match on description text
      final c = description.toLowerCase();
      if (c.contains('thunder') || c.contains('storm')) return CupertinoIcons.cloud_bolt_rain_fill;
      if (c.contains('snow') || c.contains('blizzard')) return CupertinoIcons.cloud_snow_fill;
      if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) return CupertinoIcons.cloud_rain_fill;
      if (c.contains('fog') || c.contains('mist')) return CupertinoIcons.cloud_fog_fill;
      if (c.contains('wind')) return CupertinoIcons.wind;
      if (c.contains('cloud') || c.contains('overcast')) return CupertinoIcons.cloud_fill;
      if (c.contains('partly')) return CupertinoIcons.cloud_sun_fill;
      return CupertinoIcons.sun_max_fill;
  }
}

/// A compact weather card for the home screen.
///
/// Shows city, temperature, condition icon, condition text, humidity and wind.
/// Renders a shimmer-style placeholder while [isLoading] is true.
/// Renders a friendly "Weather unavailable" message when [weather] is null
/// and [isLoading] is false.
class WeatherCard extends StatelessWidget {
  final WeatherData? weather;
  final bool isLoading;

  const WeatherCard({
    super.key,
    required this.weather,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkSurface : AppColors.bone25;
    final border = isDark ? AppColors.darkBorderSubtle : AppColors.bone200;

    if (isLoading) {
      return _WeatherShimmer(bg: bg, border: border);
    }

    if (weather == null) {
      return _WeatherUnavailable(bg: bg, border: border);
    }

    final w = weather!;
    final tempC = w.temperatureCelsius.round();
    final showHumidity = w.humidity > 0;
    // Icon resolved from conditionType enum; falls back to description text
    final conditionIcon = _iconForCondition(w.conditionType, description: w.description);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: city+temp on left, icon+condition on right ──────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: city name + temperature
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.cityName.isNotEmpty ? w.cityName : 'Current Location',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.bone500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$tempC°C',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest700,
                      ),
                    ),
                  ],
                ),
              ),
              // Right: condition icon + condition text
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(conditionIcon, color: AppColors.forest500, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    w.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.bone500,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ],
          ),
          if (showHumidity) ...[  
            const SizedBox(height: 12),
            // ── Row 2: humidity + wind (only shown when API returns values) ──
            Row(
              children: [
                const Icon(CupertinoIcons.drop_fill, size: 14, color: AppColors.bone400),
                const SizedBox(width: 4),
                Text(
                  '${w.humidity.round()}%',
                  style: const TextStyle(fontSize: 12, color: AppColors.bone400),
                ),
                const SizedBox(width: 16),
                const Icon(CupertinoIcons.wind, size: 14, color: AppColors.bone400),
                const SizedBox(width: 4),
                const Text(
                  '—',
                  style: TextStyle(fontSize: 12, color: AppColors.bone400),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer-style loading placeholder — no third-party package required.
class _WeatherShimmer extends StatefulWidget {
  final Color bg;
  final Color border;
  const _WeatherShimmer({required this.bg, required this.border});

  @override
  State<_WeatherShimmer> createState() => _WeatherShimmerState();
}

class _WeatherShimmerState extends State<_WeatherShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmerColor = Color.lerp(
          widget.bg,
          AppColors.bone200,
          _anim.value,
        )!;
        return Container(
          height: 88,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.border),
          ),
        );
      },
    );
  }
}

/// Shown when weather data failed to load.
class _WeatherUnavailable extends StatelessWidget {
  final Color bg;
  final Color border;
  const _WeatherUnavailable({required this.bg, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: const Center(
        child: Text(
          'Weather unavailable',
          style: TextStyle(fontSize: 13, color: AppColors.bone400),
        ),
      ),
    );
  }
}
