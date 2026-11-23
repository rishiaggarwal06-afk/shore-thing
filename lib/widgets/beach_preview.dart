import 'package:flutter/material.dart';

import '../models/beach.dart';
import '../models/forecast.dart';
import '../services/forecast_service.dart';
import 'brand.dart';
import 'forecast_strip.dart';

/// Mini card that pops up over the bottom of the map when a preview card is tapped:
/// photo, the basics, typical conditions this month, and Back / View full page.
/// It only covers part of the screen so the map stays visible above it.
class BeachPreview extends StatelessWidget {
  const BeachPreview({super.key, required this.beach, required this.onBack, required this.onOpen});

  final Beach beach;
  final VoidCallback onBack;
  final VoidCallback onOpen;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final b = beach;
    final thumb = MediaQuery.textScalerOf(context).scale(76);
    final month = _months[DateTime.now().month - 1];
    final now = b.monthly.where((m) => m.month == month).firstOrNull;
    final entry = b.entry == 'Free' ? 'Free entry' : '${b.entry} ${b.entryUnit ?? ''}'.trim();

    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Preview of ${b.name}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: Brand.card(color: Brand.paper, shadow: 6, radius: 24),
        // The info scrolls if it doesn't fit (big text sizes); the two buttons always stay in view.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: thumb,
                          height: thumb,
                          decoration: BoxDecoration(color: Brand.sand, borderRadius: BorderRadius.circular(14)),
                          clipBehavior: Clip.antiAlias,
                          child: b.photos.isEmpty
                              ? const Icon(Icons.beach_access_rounded, color: Brand.ink)
                              : Image.asset(
                                  b.photos.first.asset,
                                  fit: BoxFit.cover,
                                  cacheWidth: 300,
                                  excludeFromSemantics: true,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(header: true, child: Text(b.name, style: Brand.title(26))),
                              const SizedBox(height: 4),
                              Text(b.area, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      b.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Fact(Icons.confirmation_number_outlined, entry),
                        _Fact(Icons.pool_rounded, b.lifeguardsShort),
                        _Fact(Icons.waves_rounded, b.wave == 'Calm' ? 'Calm water' : 'Waves ${b.wave}'),
                        if (b.restrooms) const _Fact(Icons.wc_rounded, 'Restrooms'),
                        if (b.shacksFood) const _Fact(Icons.restaurant_rounded, 'Food'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Today's real forecast when it arrives; the typical numbers until then (or offline).
                    FutureBuilder<BeachForecast>(
                      future: ForecastService.instance.forBeach(b),
                      builder: (context, snap) {
                        final today = snap.data?.days.firstOrNull;
                        final text = today != null
                            ? 'Today: ${today.highF}°F, ${describeWeather(today.weatherCode).label.toLowerCase()}'
                                  '${today.waveFt != null ? ' · waves ${today.waveFt! < 1 ? 'under 1' : today.waveFt!.round()} ft' : ''}'
                            : now != null
                            ? 'Typical in $month: ${now.airF}°F air · ${now.waterF}°F water'
                            : '';
                        return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _Button('Back', Colors.white, onBack)),
                const SizedBox(width: 10),
                Expanded(child: _Button('View full page', Brand.yellow, onOpen)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill: icon + a few words.
class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Brand.lagoonTint, borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Brand.ink),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

class _Button extends StatelessWidget {
  const _Button(this.label, this.color, this.onTap);
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        alignment: Alignment.center,
        decoration: Brand.card(color: color, shadow: 2, radius: 999),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
