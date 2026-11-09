import 'package:flutter/material.dart';

import '../models/month_conditions.dart';
import 'brand.dart';

/// "Best time to go": 12 month cards in a sideways-scrolling strip.
class BestTimeToGo extends StatelessWidget {
  const BestTimeToGo({super.key, required this.climate});
  final ({List<MonthConditions> months, bool placeholder, String? source}) climate;

  List<MonthConditions> get months => climate.months;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Text('Best time to go', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: Brand.chunky(color: Brand.yellow, shadow: 0, radius: 20, border: 2),
            child: Text(
              climate.placeholder ? 'TYPICAL, NOT LIVE · PLACEHOLDER NUMBERS' : 'TYPICAL, NOT LIVE · 10-YEAR AVERAGES',
              style: Brand.eyebrow,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        const Text('☀︎ Air high   ≈ Water   ↗︎ Waves   ☂︎ Rain per month', style: TextStyle(fontSize: 12)),
        if (climate.source != null) ...[
          const SizedBox(height: 4),
          Text(climate.source!, style: const TextStyle(fontSize: 11.5)),
        ],
        const SizedBox(height: 14),
        // Phones swipe through the months; wider screens show them all as a grid.
        if (Brand.isPhone(context))
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final m in months) Padding(padding: const EdgeInsets.only(right: 10), child: _MonthCard(m)),
            ]),
          )
        else
          Wrap(spacing: 10, runSpacing: 10, children: [for (final m in months) _MonthCard(m)]),
      ]);
}

class _MonthCard extends StatelessWidget {
  const _MonthCard(this.m);
  final MonthConditions m;

  @override
  Widget build(BuildContext context) {
    // Warm months get the yellow card so the beach season stands out.
    final warm = m.airF >= 75;
    return Container(
      // Grows with the phone's text size setting so nothing spills out.
      width: MediaQuery.textScalerOf(context).scale(104),
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 4, right: 4),
      decoration: Brand.chunky(color: warm ? Brand.yellow : Colors.white, shadow: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(m.month.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
        const SizedBox(height: 8),
        _row('☀︎', '${m.airF}°F', 'Air temperature'),
        _row('≈', '${m.waterF}°F', 'Water temperature'),
        _row('↗︎', '${m.waveFt} ft', 'Wave size'),
        _row('☂︎', '${m.rainIn.toStringAsFixed(1)} in', 'Rain'),
      ]),
    );
  }

  Widget _row(String icon, String value, String label) => Semantics(
        label: '$label $value',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            // Shrinks a little instead of spilling out if the phone's text is very large.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      );
}
