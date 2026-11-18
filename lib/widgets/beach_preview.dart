import 'package:flutter/material.dart';

import '../models/beach.dart';
import 'brand.dart';

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
        decoration: Brand.chunky(color: Brand.paper, shadow: 5),
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
                          decoration: BoxDecoration(
                            color: Brand.sand,
                            border: Border.all(color: Brand.ink, width: 2),
                          ),
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
                              Semantics(
                                header: true,
                                child: Text(
                                  b.name,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.15),
                                ),
                              ),
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
                        _Fact(Icons.pool_rounded, b.lifeguards.startsWith('Yes') ? 'Lifeguards' : 'No lifeguards'),
                        _Fact(Icons.waves_rounded, b.wave == 'Calm' ? 'Calm water' : 'Waves ${b.wave}'),
                        if (b.restrooms) const _Fact(Icons.wc_rounded, 'Restrooms'),
                        if (b.shacksFood) const _Fact(Icons.restaurant_rounded, 'Food'),
                      ],
                    ),
                    if (now != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Typical in $month: ${now.airF}°F air · ${now.waterF}°F water',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
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
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Brand.ink, width: 1.5),
    ),
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
        decoration: Brand.chunky(color: color, shadow: 3, border: 2.5),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}
