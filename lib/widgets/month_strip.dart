import 'package:flutter/material.dart';

import '../models/month_conditions.dart';
import 'brand.dart';
import 'brand_sheet.dart';

/// "Best time to go": 12 month cards in a sideways-scrolling strip.
class BestTimeToGo extends StatelessWidget {
  const BestTimeToGo({super.key, required this.climate, this.beachName});
  final ({List<MonthConditions> months, bool placeholder, String? source}) climate;
  final String? beachName; // for the details panel's title

  List<MonthConditions> get months => climate.months;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Best time to go', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(height: 4),
      Text(
        climate.placeholder
            ? 'Rough estimates until this beach’s averages are added · tap a month'
            : 'Typical conditions from 10-year averages · tap a month',
        style: const TextStyle(fontSize: 14),
      ),
      const SizedBox(height: 14),
      // Phones swipe through the months; wider screens show them all as a grid.
      if (Brand.isPhone(context))
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final m in months) Padding(padding: const EdgeInsets.only(right: 10), child: _card(context, m)),
            ],
          ),
        )
      else
        Wrap(spacing: 10, runSpacing: 10, children: [for (final m in months) _card(context, m)]),
      if (climate.source != null) ...[
        const SizedBox(height: 8),
        Text(climate.source!, style: const TextStyle(fontSize: 11.5)),
      ],
    ],
  );

  Widget _card(BuildContext context, MonthConditions m) => _MonthCard(m, onTap: () => _showMonth(context, m));

  static const _monthNames = {
    'Jan': 'January',
    'Feb': 'February',
    'Mar': 'March',
    'Apr': 'April',
    'May': 'May',
    'Jun': 'June',
    'Jul': 'July',
    'Aug': 'August',
    'Sep': 'September',
    'Oct': 'October',
    'Nov': 'November',
    'Dec': 'December',
  };

  void _showMonth(BuildContext context, MonthConditions m) {
    final name = _monthNames[m.month] ?? m.month;
    // A simple plain-language verdict from the averages.
    final verdict = m.airF >= 80 && m.waterF >= 75
        ? 'Peak beach weather: hot days and warm water.'
        : m.airF >= 72 && m.waterF >= 68
        ? 'Good beach weather for most people.'
        : m.airF >= 65
        ? 'Mild. Fine for walks and sun; the water may feel cool.'
        : 'Off-season: better for quiet walks than swimming.';
    showBrandSheet(
      context,
      title: beachName == null ? name : '$name at $beachName',
      subtitle: climate.placeholder ? 'Rough estimates' : 'Typical for $name (10-year averages)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(verdict, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.4)),
          const SizedBox(height: 8),
          SheetRow(Icons.wb_sunny_outlined, 'Daytime high', '${m.airF}°F'),
          SheetRow(Icons.pool_rounded, 'Water temperature', '${m.waterF}°F'),
          SheetRow(Icons.waves_rounded, 'Typical waves', '${m.waveFt} ft'),
          SheetRow(Icons.water_drop_outlined, 'Rain in the month', '${m.rainIn.toStringAsFixed(1)} in'),
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard(this.m, {required this.onTap});
  final MonthConditions m;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Warm months get the yellow card so the beach season stands out.
    final warm = m.airF >= 75;
    return InkWell(
      onTap: onTap,
      child: Container(
        // Grows with the phone's text size setting so nothing spills out.
        width: MediaQuery.textScalerOf(context).scale(104),
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 4, right: 4),
        decoration: Brand.chunky(color: warm ? Brand.yellow : Colors.white, shadow: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.month.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            _row(Icons.wb_sunny_outlined, '${m.airF}°F', 'Air temperature'),
            _row(Icons.pool_rounded, '${m.waterF}°F', 'Water temperature'),
            _row(Icons.waves_rounded, '${m.waveFt} ft', 'Wave size'),
            _row(Icons.water_drop_outlined, '${m.rainIn.toStringAsFixed(1)} in', 'Rain'),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String value, String label) => Semantics(
    label: '$label $value',
    excludeSemantics: true,
    child: Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Brand.ink),
          const SizedBox(width: 6),
          // Shrinks a little instead of spilling out if the phone's text is very large.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ),
  );
}
