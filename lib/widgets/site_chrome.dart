import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/beach.dart';
import '../services/beach_scope.dart';
import 'brand.dart';
import 'brand_sheet.dart';

/// "shore thing" wordmark. Tapping it goes home.
/// [onStripes]: sits on the striped awning, so it gets a cream pill behind it.
class Logo extends StatelessWidget {
  const Logo({super.key, this.color = Brand.ink, this.onStripes = false});
  final Color color;
  final bool onStripes;

  @override
  Widget build(BuildContext context) {
    final text = Text.rich(
      TextSpan(children: [
        const TextSpan(text: 'shore '),
        TextSpan(text: 'thing', style: TextStyle(color: color == Brand.ink ? Brand.ocean : color)),
      ]),
      style: Brand.title(onStripes ? 22 : 26, color: color).copyWith(height: 1),
    );
    return Semantics(
      label: 'Shore Thing home',
      button: true,
      excludeSemantics: true,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => context.go('/'),
        child: onStripes
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: Brand.card(color: Brand.paper, shadow: 2, radius: 999),
                child: text,
              )
            : text,
      ),
    );
  }
}

/// Bar at the top of every screen: a striped beach-umbrella awning with a scalloped
/// edge. It reaches up under the iPhone's status bar (SafeArea keeps the buttons below
/// the clock and notch).
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.leading, this.trailing});
  final Widget leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const _AwningPainter(),
        child: SafeArea(
          bottom: false,
          child: Padding(
            // The bottom padding leaves room for the scallops.
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10 + _AwningPainter.scallop),
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

/// Teal and cream stripes, each ending in a rounded scallop, over the page background.
class _AwningPainter extends CustomPainter {
  const _AwningPainter();
  static const stripe = 26.0; // width of one stripe
  static const scallop = 10.0; // how far the scallops hang down

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Brand.paper);
    final body = size.height - scallop;
    final colors = [Brand.ocean, const Color(0xFFFDFBF6)];
    var i = 0;
    for (var x = 0.0; x < size.width; x += stripe, i++) {
      final p = Paint()..color = colors[i % 2];
      canvas.drawRect(Rect.fromLTWH(x, 0, stripe + .5, body), p);
      // Rounded flap hanging below each stripe.
      canvas.drawArc(Rect.fromLTWH(x, body - scallop, stripe, scallop * 2), 0, 3.14159, true, p);
    }
    // A soft shadow line where the awning meets the page.
    canvas.drawRect(
      Rect.fromLTWH(0, body - 1, size.width, 1),
      Paint()..color = Brand.ink.withValues(alpha: .06),
    );
  }

  @override
  bool shouldRepaint(_AwningPainter oldDelegate) => false;
}

class _Shrink extends StatelessWidget {
  const _Shrink(this.child, this.alignment);
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
}

/// Small white pill-shaped button with an icon and a word.
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
      customBorder: const StadiumBorder(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: Brand.card(color: Brand.paper, shadow: 2, radius: 999),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Brand.ink),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    ),
  );
}

/// Goes back to the map (the first screen).
class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) => BarButton(icon: Icons.home_rounded, label: 'Map', onTap: () => context.go('/'));
}

/// Opens the search page.
class SearchButton extends StatelessWidget {
  const SearchButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BarButton(icon: Icons.search_rounded, label: 'Search', onTap: () => context.go('/search'));
}

/// One quiet line at the bottom of a page: a short safety note and a "Credits & sources"
/// link. The full credits (sources, weather data, photo credits with links, map data)
/// open in a panel, so the page itself stays clean. Pass [beach] for its photo credits.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key, this.beach});
  final Beach? beach;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Brand.teal))),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: PageWidth(
          vertical: 14,
          child: Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Conditions change: check with lifeguards before you swim.',
                  style: TextStyle(fontSize: 12.5, color: Brand.inkSoft)),
              Semantics(
                button: true,
                child: InkWell(
                  onTap: () => showCredits(context, beach),
                  child: const UnderlinedText('Credits & sources',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
}

/// The full credits panel. Everything here is what the data and photo licenses ask for.
void showCredits(BuildContext context, Beach? beach) {
  final repo = BeachScope.of(context);
  const head = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
  const body = TextStyle(fontSize: 13.5, height: 1.5);
  Widget section(String title, List<Widget> lines) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: head),
          const SizedBox(height: 4),
          ...lines,
        ]),
      );
  showBrandSheet(
    context,
    title: 'Credits & sources',
    subtitle: beach?.name,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      section('Beach information', [Text(repo.sourcesNote, style: body)]),
      section('Weather', [
        if (beach?.monthlySource != null) Text('Monthly averages: ${beach!.monthlySource}', style: body),
        const Text('7-day forecast: weather data by Open-Meteo.com, licensed CC BY 4.0.', style: body),
      ]),
      if (beach != null && beach.photos.isNotEmpty)
        section('Photos (Wikimedia Commons)', [
          for (final p in beach.photos)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SelectableText('${p.artist} · ${p.license}\n${p.source}', style: body),
            ),
        ]),
      section('Map', [
        const Text('© MapTiler © OpenStreetMap contributors. Built-in map: Natural Earth (public domain).', style: body),
      ]),
    ]),
  );
}
