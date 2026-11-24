import 'dart:async';

import 'package:flutter/material.dart';

import '../models/beach.dart';
import '../models/forecast.dart';
import '../services/forecast_service.dart';
import 'brand.dart';
import 'brand_sheet.dart';

/// What the sky is doing, from Open-Meteo's WMO weather code.
({String label, IconData icon}) describeWeather(int code) => switch (code) {
  0 => (label: 'Sunny', icon: Icons.wb_sunny_rounded),
  1 => (label: 'Mostly sunny', icon: Icons.wb_sunny_outlined),
  2 => (label: 'Partly cloudy', icon: Icons.wb_cloudy_outlined),
  3 => (label: 'Cloudy', icon: Icons.cloud_rounded),
  45 || 48 => (label: 'Fog', icon: Icons.foggy),
  51 || 53 || 55 || 56 || 57 => (label: 'Drizzle', icon: Icons.grain_rounded),
  61 || 63 || 66 || 80 || 81 => (label: 'Rain', icon: Icons.water_drop_outlined),
  65 || 67 || 82 => (label: 'Heavy rain', icon: Icons.water_drop_outlined),
  71 || 73 || 75 || 77 || 85 || 86 => (label: 'Snow', icon: Icons.ac_unit_rounded),
  95 || 96 || 99 => (label: 'Thunderstorms', icon: Icons.thunderstorm_rounded),
  _ => (label: 'Mixed', icon: Icons.wb_cloudy_outlined),
};

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdaysLong = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _time(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
}

String _ft(double ft) => ft < 1 ? 'Under 1 ft' : '${ft.toStringAsFixed(ft < 10 ? 1 : 0)} ft';

/// "Next 7 days" on a beach page: the real forecast, one tappable card per day.
class ForecastStrip extends StatefulWidget {
  const ForecastStrip({super.key, required this.beach});
  final Beach beach;

  @override
  State<ForecastStrip> createState() => _ForecastStripState();
}

class _ForecastStripState extends State<ForecastStrip> {
  late Future<BeachForecast> _future = ForecastService.instance.forBeach(widget.beach);

  void _retry() => setState(() => _future = ForecastService.instance.forBeach(widget.beach, refresh: true));

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Next 7 days', style: Brand.title(24)),
      const SizedBox(height: 4),
      const Text('Live forecast · tap a day for details', style: TextStyle(fontSize: 14)),
      const SizedBox(height: 12),
      FutureBuilder<BeachForecast>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const _Waiting();
          }
          final days = snap.data?.days ?? const <DayForecast>[];
          if (snap.hasError || days.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: Brand.chunky(shadow: 3),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Couldn’t load the forecast. Check your connection.'),
                      // The technical reason, small, so a screenshot says what went wrong.
                      if (snap.hasError)
                        TextSpan(
                          text: '\n${_reason(snap.error!)}',
                          style: const TextStyle(fontSize: 12, color: Brand.inkSoft),
                        ),
                    ]),
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                  OutlinedButton(
                    onPressed: _retry,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Brand.ink,
                      side: const BorderSide(color: Brand.ink, width: 1.5),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Try again', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < days.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _DayCard(days[i], today: i == 0, onTap: () => _showDay(context, days[i], i == 0)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Forecast by Open-Meteo.com (CC BY 4.0) · updated ${_time(snap.data!.fetched)}',
                style: const TextStyle(fontSize: 11.5),
              ),
            ],
          );
        },
      ),
    ],
  );

  void _showDay(BuildContext context, DayForecast d, bool today) {
    final w = describeWeather(d.weatherCode);
    showBrandSheet(
      context,
      title: today ? 'Today at ${widget.beach.name}' : '${_weekdaysLong[d.date.weekday - 1]} at ${widget.beach.name}',
      subtitle: '${_weekdaysLong[d.date.weekday - 1]}, ${_months[d.date.month - 1]} ${d.date.day} · ${w.label}',
      child: Column(
        children: [
          SheetRow(w.icon, 'Sky', w.label),
          SheetRow(Icons.thermostat_rounded, 'High / low', '${d.highF}°F / ${d.lowF}°F'),
          if (d.rainChance != null) SheetRow(Icons.water_drop_outlined, 'Chance of rain', '${d.rainChance}%'),
          if (d.rainIn != null && d.rainIn! > 0)
            SheetRow(Icons.water_drop_outlined, 'Rain', '${d.rainIn!.toStringAsFixed(2)} in'),
          if (d.windMph != null) SheetRow(Icons.air_rounded, 'Wind (strongest)', '${d.windMph} mph'),
          if (d.uvIndex != null) SheetRow(Icons.wb_sunny_outlined, 'UV index', _uv(d.uvIndex!)),
          if (d.waveFt != null) SheetRow(Icons.waves_rounded, 'Biggest waves', _ft(d.waveFt!)),
          if (d.waterF != null) SheetRow(Icons.pool_rounded, 'Water temperature', '${d.waterF}°F'),
          if (d.sunrise != null) SheetRow(Icons.wb_twilight_rounded, 'Sunrise', _time(d.sunrise!)),
          if (d.sunset != null) SheetRow(Icons.nights_stay_outlined, 'Sunset', _time(d.sunset!)),
          const SizedBox(height: 12),
          const Text(
            'Forecasts change. Always check with lifeguards and posted flags before you swim.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  static String _uv(double uv) {
    final n = uv.round();
    final level = n <= 2
        ? 'low'
        : n <= 5
        ? 'moderate'
        : n <= 7
        ? 'high'
        : n <= 10
        ? 'very high'
        : 'extreme';
    return '$n ($level)';
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard(this.d, {required this.today, required this.onTap});
  final DayForecast d;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = describeWeather(d.weatherCode);
    final day = today ? 'Today' : _weekdays[d.date.weekday - 1];
    return Semantics(
      button: true,
      label:
          '$day: ${w.label}, high ${d.highF}, low ${d.lowF}'
          '${d.rainChance != null ? ', ${d.rainChance}% chance of rain' : ''}'
          '${d.waveFt != null ? ', waves ${_ft(d.waveFt!)}' : ''}. Show details',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          // Grows with the phone's text size so nothing spills out.
          width: MediaQuery.textScalerOf(context).scale(96),
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 4, right: 4),
          decoration: today ? Brand.card(color: Brand.sunTint, shadow: 0, radius: 16) : const BoxDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(day, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 6),
              Icon(w.icon, size: 30, color: Brand.ink),
              const SizedBox(height: 6),
              Text('${d.highF}°', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text('Low ${d.lowF}°', style: const TextStyle(fontSize: 13)),
              if (d.rainChance != null) ...[
                const SizedBox(height: 6),
                _mini(Icons.water_drop_outlined, '${d.rainChance}%'),
              ],
              if (d.waveFt != null) _mini(Icons.waves_rounded, d.waveFt! < 1 ? '<1 ft' : '${d.waveFt!.round()} ft'),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _mini(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(
      children: [
        Icon(icon, size: 15, color: Brand.ink),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

/// Short description of why the forecast failed (shown in small print).
String _reason(Object e) {
  final text = e.toString().replaceAll('\n', ' ');
  return text.length > 120 ? '${text.substring(0, 120)}…' : text;
}

/// Spinner while the forecast loads; after a few seconds it says it's still trying.
class _Waiting extends StatefulWidget {
  const _Waiting();

  @override
  State<_Waiting> createState() => _WaitingState();
}

class _WaitingState extends State<_Waiting> {
  bool _slow = false;
  late final Timer _timer = Timer(const Duration(seconds: 6), () => setState(() => _slow = true));

  @override
  void initState() {
    super.initState();
    _timer; // start the timer
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(children: [
          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: Brand.ink)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _slow ? 'Still waiting for the forecast… (slow connection?)' : 'Getting the forecast…',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ]),
      );
}
