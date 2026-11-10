import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'brand.dart';

/// "shore thing ✳︎" wordmark. Tapping it goes home.
class Logo extends StatelessWidget {
  const Logo({super.key, this.color = Brand.ink});
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Shore Thing home',
        button: true,
        child: InkWell(
          onTap: () => context.go('/'),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: 'shore thing', style: TextStyle(color: color)),
              const TextSpan(text: '✳︎', style: TextStyle(color: Brand.orange)),
            ]),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.5),
          ),
        ),
      );
}

/// Thin dark strip at the very top of every page.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key, required this.beachCount});
  final int beachCount;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Brand.ink,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '$beachCount FAVORITE BEACHES, ONE BIG BLUE OCEAN. ',
                style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .6)),
            const TextSpan(text: 'Info from public sources · conditions are typical, not live.'),
          ]),
          style: const TextStyle(color: Brand.yellow, fontSize: 11),
        ),
      );
}

class SiteHeader extends StatelessWidget {
  const SiteHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final phone = Brand.isPhone(context);
    return Container(
      decoration: const BoxDecoration(
        color: Brand.yellow,
        border: Border(bottom: BorderSide(color: Brand.ink, width: 3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        const Logo(),
        const Spacer(),
        InkWell(
          onTap: () => context.go('/'),
          child: const UnderlinedText('Find a beach ↗︎', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ),
        if (!phone) ...[
          const SizedBox(width: 16),
          const Text('GOOD DAYS START AT THE SHORE', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ]),
    );
  }
}

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Brand.ink,
        child: const PageWidth(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Logo(color: Brand.yellow),
            SizedBox(height: 12),
            Text('Less scrolling. More shoreline.', style: TextStyle(color: Brand.paper, fontSize: 15)),
            SizedBox(height: 12),
            Text(
              'Beach info gathered from public sources, Nov 2026. Fees, hours and conditions change, '
              'so always check with lifeguards and official sites. Map © MapTiler © OpenStreetMap contributors. Weather data by Open-Meteo.com (CC BY 4.0). Beach photos from Wikimedia Commons, credited on each beach page.',
              style: TextStyle(color: Brand.paper, fontSize: 12, height: 1.5),
            ),
          ]),
        ),
      );
}
