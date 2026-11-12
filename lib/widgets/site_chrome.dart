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
        excludeSemantics: true,
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

/// Yellow bar at the top of every screen. It reaches up under the iPhone's
/// status bar (SafeArea keeps the buttons below the clock and notch).
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.leading, this.trailing});
  final Widget leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Brand.yellow,
          border: Border(bottom: BorderSide(color: Brand.ink, width: 3)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            // With a very large text size the two sides shrink a little rather than spill off the screen.
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(child: _Shrink(leading, Alignment.centerLeft)),
              const SizedBox(width: 12),
              if (trailing != null) Flexible(child: _Shrink(trailing!, Alignment.centerRight)),
            ]),
          ),
        ),
      );
}

class _Shrink extends StatelessWidget {
  const _Shrink(this.child, this.alignment);
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
}

/// Small white button with an icon and a word, in the chunky brand style.
class BarButton extends StatelessWidget {
  const BarButton({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: Brand.chunky(shadow: 3, border: 2.5),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 20, color: Brand.ink),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ]),
          ),
        ),
      );
}

/// Goes back to the map (the first screen).
class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BarButton(icon: Icons.home_rounded, label: 'Map', onTap: () => context.go('/'));
}

/// Opens the search page.
class SearchButton extends StatelessWidget {
  const SearchButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BarButton(icon: Icons.search_rounded, label: 'Search', onTap: () => context.go('/search'));
}

/// Dark strip at the bottom of the beach pages with the required credits.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Brand.ink,
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: const PageWidth(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Logo(color: Brand.yellow),
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
