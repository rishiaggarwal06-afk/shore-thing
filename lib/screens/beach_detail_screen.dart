import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/beach.dart';
import '../models/beach_photo.dart';
import '../services/beach_scope.dart';
import '../services/climate_service.dart';
import '../widgets/beach_scene.dart';
import '../widgets/brand.dart';
import '../widgets/month_strip.dart';
import '../widgets/search_box.dart';
import '../widgets/site_chrome.dart';

/// Shared scrolling page frame: banner, header, centred content, footer.
class SitePage extends StatelessWidget {
  const SitePage({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DemoBanner(regionName: BeachScope.of(context).region.name),
            const SiteHeader(),
            PageWidth(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
            ),
            const SiteFooter(),
          ]),
        ),
      );
}

class BackToMap extends StatelessWidget {
  const BackToMap({super.key});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context.go('/'),
        child: const UnderlinedText('← Back to the map', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      );
}

/// Eyebrow + big title + paragraph on the left, search on the right (stacked on phones).
class DetailHead extends StatelessWidget {
  const DetailHead({super.key, required this.eyebrow, required this.title, required this.text});
  final String eyebrow, title, text;

  @override
  Widget build(BuildContext context) {
    final phone = Brand.isPhone(context);
    final words = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(eyebrow.toUpperCase(), style: Brand.eyebrow),
      const SizedBox(height: 8),
      Semantics(
        header: true,
        child: Text(title,
            style: TextStyle(fontSize: phone ? 34 : 52, fontWeight: FontWeight.w900, height: 1.02, letterSpacing: -1)),
      ),
      const SizedBox(height: 12),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Text(text, style: const TextStyle(fontSize: 17, height: 1.45)),
      ),
    ]);
    if (phone) return Column(children: [words, const SizedBox(height: 20), const SearchBox()]);
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(flex: 2, child: words),
      const SizedBox(width: 28),
      const Expanded(child: SearchBox()),
    ]);
  }
}

class BeachDetailScreen extends StatelessWidget {
  const BeachDetailScreen({super.key, required this.beach});
  final Beach beach;

  @override
  Widget build(BuildContext context) {
    final b = beach;
    final region = BeachScope.of(context).region;
    final phone = Brand.isPhone(context);
    const gap = SizedBox(height: 22);

    return Title(
      title: '${b.name} · Shore Thing',
      color: Brand.ink,
      child: SitePage(children: [
        const BackToMap(),
        const SizedBox(height: 14),
        DetailHead(eyebrow: '${b.area} · NEW JERSEY', title: b.name, text: b.description),
        gap,
        _Gallery(b, phone: phone),
        gap,
        _StatusLine(b.tag),
        gap,
        _Stats(cards: [
          _airCard(b, region),
          _waterCard(b, region),
          ('↗︎ Waves', b.wave, b.waveNote),
          ('⚑︎ Lifeguards', b.lifeguards, b.lifeguardNote),
        ]),
        gap,
        _InfoGrid(b, phone: phone),
        const SizedBox(height: 30),
        BestTimeToGo(climate: const ClimateService().monthlyFor(b)),
        gap,
        Text(region.sourcesNote, style: const TextStyle(fontSize: 12, height: 1.5)),
        if (b.photos.isNotEmpty) _PhotoCredits(b.photos),
      ]),
    );
  }
}

/// Air temperature card: this beach's real summer highs if we have them, else the region's.
(String, String, String) _airCard(Beach b, Region region) {
  if (b.monthly.length != 12) return ('☀\ufe0e Air temperature', region.airTemp, region.airNote);
  final summer = b.monthly.sublist(5, 8).map((m) => m.airF).toList()..sort();
  return ('☀\ufe0e Air temperature', '${summer.first}–${summer.last}°F', 'Average summer highs · Jun–Aug');
}

/// Water temperature card: the warmest month on average.
(String, String, String) _waterCard(Beach b, Region region) {
  if (b.monthly.length != 12) return ('≈ Water temperature', region.waterTemp, region.waterNote);
  final warmest = b.monthly.reduce((a, m) => m.waterF > a.waterF ? m : a);
  return ('≈ Water temperature', 'Up to ${warmest.waterF}°F', 'Warmest in ${warmest.month}, on average');
}

/// Full photo credits with links to each photo's page (required by the CC licenses).
class _PhotoCredits extends StatelessWidget {
  const _PhotoCredits(this.photos);
  final List<BeachPhoto> photos;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PHOTO CREDITS', style: Brand.eyebrow),
          const SizedBox(height: 6),
          for (final p in photos)
            SelectableText('${p.artist}, ${p.license}, ${p.source}', style: const TextStyle(fontSize: 11, height: 1.5)),
        ]),
      );
}

class _Gallery extends StatelessWidget {
  const _Gallery(this.b, {required this.phone});
  final Beach b;
  final bool phone;

  /// Slot [i] shows the beach's i-th real photo, or an illustration if there isn't one.
  Widget _slot(int i, String sceneLabel) {
    final scene = BeachScene(palette: b.color, view: i, label: sceneLabel);
    return i < b.photos.length ? PhotoTile(photo: b.photos[i], beachName: b.name, fallback: scene) : scene;
  }

  @override
  Widget build(BuildContext context) {
    final main = _slot(0, 'Illustrated shoreline for ${b.name}');
    final side1 = _slot(1, 'Illustrated umbrella on the sand');
    final side2 = _slot(2, 'Illustrated sailboat offshore');
    if (phone) {
      return Column(children: [
        main,
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: side1),
          const SizedBox(width: 10),
          Expanded(child: side2),
        ]),
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 2, child: main),
      const SizedBox(width: 10),
      Expanded(child: Column(children: [side1, const SizedBox(height: 10), side2])),
    ]);
  }
}

/// A real photo in the chunky frame, with its required credit line underneath.
class PhotoTile extends StatelessWidget {
  const PhotoTile({super.key, required this.photo, required this.beachName, required this.fallback});
  final BeachPhoto photo;
  final String beachName;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          decoration: Brand.chunky(shadow: 0),
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: Image.asset(
              photo.asset,
              fit: BoxFit.cover,
              semanticLabel: 'Photo of $beachName',
              errorBuilder: (_, _, _) => fallback, // photo file missing → show the illustration
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(photo.credit, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, height: 1.3)),
      ]);
}

class _StatusLine extends StatelessWidget {
  const _StatusLine(this.tag);
  final String tag;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: const BoxDecoration(
          border: Border.symmetric(horizontal: BorderSide(color: Brand.ink, width: 3)),
        ),
        child: Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 6, spacing: 16, children: [
          Text('✳︎ $tag', style: Brand.eyebrow.copyWith(fontSize: 12)),
          Text('TYPICAL CONDITIONS · NOT A LIVE FORECAST', style: Brand.eyebrow.copyWith(fontSize: 12)),
        ]),
      );
}

class _Stats extends StatelessWidget {
  const _Stats({required this.cards});
  final List<(String, String, String)> cards;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth < 560 ? 2 : 4;
        const gap = 12.0;
        final w = (c.maxWidth - gap * (cols - 1) - 5) / cols;
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final (label, value, note) in cards)
            Container(
              width: w,
              padding: const EdgeInsets.all(14),
              decoration: Brand.chunky(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(note, style: const TextStyle(fontSize: 12.5, height: 1.35)),
              ]),
            ),
        ]);
      });
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid(this.b, {required this.phone});
  final Beach b;
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final whatsThere = Container(
      padding: const EdgeInsets.all(20),
      decoration: Brand.chunky(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('What’s there', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth < 380 ? c.maxWidth : (c.maxWidth - 16) / 2;
          return Wrap(spacing: 16, runSpacing: 10, children: [
            for (final f in b.features)
              SizedBox(
                width: w,
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('✓  ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 16, height: 1.3))),
                ]),
              ),
          ]);
        }),
        const SizedBox(height: 16),
        Text.rich(TextSpan(children: [
          const TextSpan(text: 'Safety: ', style: TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: b.safety),
        ]), style: const TextStyle(fontSize: 13, height: 1.45)),
      ]),
    );

    const label = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
    const body = TextStyle(fontSize: 16, height: 1.4);
    final gettingIn = Container(
      padding: const EdgeInsets.all(20),
      decoration: Brand.chunky(color: Brand.yellow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('GETTING IN', style: Brand.eyebrow),
        const SizedBox(height: 6),
        Text.rich(TextSpan(children: [
          TextSpan(text: b.entry, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
          if (b.entryUnit != null) TextSpan(text: '  ${b.entryUnit}', style: const TextStyle(fontSize: 14)),
        ])),
        const SizedBox(height: 10),
        Text(b.entryNote, style: body),
        const SizedBox(height: 14),
        const Text('Parking', style: label),
        Text(b.parking, style: body),
        if (b.hours != null) ...[
          const SizedBox(height: 14),
          const Text('Hours', style: label),
          Text(b.hours!, style: body),
        ],
      ]),
    );

    if (phone) return Column(children: [whatsThere, const SizedBox(height: 18), gettingIn]);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(flex: 2, child: whatsThere),
        const SizedBox(width: 18),
        Expanded(child: gettingIn),
      ]),
    );
  }
}
