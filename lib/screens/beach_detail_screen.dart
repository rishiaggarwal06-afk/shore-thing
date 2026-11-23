import 'package:flutter/material.dart';

import '../models/beach.dart';
import '../models/beach_photo.dart';
import '../widgets/brand_sheet.dart';
import '../widgets/forecast_strip.dart';
import '../widgets/photo_gallery.dart';
import '../services/beach_scope.dart';
import '../services/climate_service.dart';
import '../widgets/brand.dart';
import '../widgets/month_strip.dart';
import '../widgets/site_chrome.dart';

/// Shared page frame: the top bar (Map button + Search) stays put while the page scrolls.
class SitePage extends StatelessWidget {
  const SitePage({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const TopBar(leading: HomeButton(), trailing: SearchButton()),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageWidth(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
                ),
                const SiteFooter(),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Small label + big title + paragraph at the top of a page.
class DetailHead extends StatelessWidget {
  const DetailHead({super.key, required this.eyebrow, required this.title, required this.text});
  final String eyebrow, title, text;

  @override
  Widget build(BuildContext context) {
    final phone = Brand.isPhone(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Semantics(header: true, child: Text(title, style: Brand.title(phone ? 40 : 56))),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(text, style: const TextStyle(fontSize: 17, height: 1.45)),
        ),
      ],
    );
  }
}

class BeachDetailScreen extends StatelessWidget {
  const BeachDetailScreen({super.key, required this.beach});
  final Beach beach;

  @override
  Widget build(BuildContext context) {
    final b = beach;
    final repo = BeachScope.of(context);
    const gap = SizedBox(height: 28);

    return Title(
      title: '${b.name} · Shore Thing',
      color: Brand.ink,
      child: SitePage(
        children: [
          PhotoGallery(beach: b),
          const SizedBox(height: 20),
          DetailHead(eyebrow: '${b.area} · ${repo.placeOf(b)}', title: b.name, text: b.description),
          gap,
          _FactTiles(b),
          gap,
          ForecastStrip(beach: b),
          gap,
          _WhatsThere(b),
          gap,
          BestTimeToGo(climate: const ClimateService().monthlyFor(b), beachName: b.name),
          gap,
          Text(repo.sourcesNote, style: const TextStyle(fontSize: 12, height: 1.5)),
          if (b.photos.isNotEmpty) _PhotoCredits(b.photos),
        ],
      ),
    );
  }
}

/// Full photo credits with links to each photo's page (required by the CC licenses).
class _PhotoCredits extends StatelessWidget {
  const _PhotoCredits(this.photos);
  final List<BeachPhoto> photos;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photo credits', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        for (final p in photos)
          SelectableText(
            '${p.artist} · ${p.license} · ${p.source.replaceFirst('https://', '')}',
            style: const TextStyle(fontSize: 11, height: 1.5),
          ),
      ],
    ),
  );
}

/// The key facts as tappable tiles; each opens a panel with the full details.
class _FactTiles extends StatelessWidget {
  const _FactTiles(this.b);
  final Beach b;

  @override
  Widget build(BuildContext context) {
    // The tile shows just the price; the panel adds what it's per (car, person, day...).
    final entry = b.entry;
    final entryFull = b.entryUnit == null ? b.entry : '${b.entry} ${b.entryUnit}';
    final tiles = [
      (
        Icons.confirmation_number_outlined,
        Brand.sunTint,
        'Entry',
        entry,
        entryFull == entry ? b.entryNote : '$entryFull. ${b.entryNote}',
      ),
      (Icons.pool_rounded, Brand.lagoonTint, 'Lifeguards', b.lifeguards, b.lifeguardNote),
      (Icons.waves_rounded, Brand.lagoonTint, 'Waves', b.wave, b.waveNote),
      (Icons.local_parking_rounded, Brand.sandTint, 'Parking', 'Details', b.parking),
      if (b.hours != null) (Icons.schedule_rounded, Brand.sandTint, 'Hours', 'Details', b.hours!),
      (Icons.health_and_safety_outlined, Brand.coralTint, 'Safety', 'Tips', b.safety),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 560 ? 2 : 3;
        const gap = 10.0;
        final w = (c.maxWidth - gap * (cols - 1) - 5) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (icon, tint, title, value, note) in tiles)
              SizedBox(
                width: w,
                child: Semantics(
                  button: true,
                  label: '$title: $value. Show details',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => showBrandSheet(
                      context,
                      title: title,
                      subtitle: b.name,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (value != 'Details' && value != 'Tips')
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(value, style: Brand.title(32)),
                            ),
                          Text(note, style: const TextStyle(fontSize: 17, height: 1.45)),
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: Brand.card(shadow: 3),
                      child: Row(
                        children: [
                          // Icon in a soft coloured bubble.
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                            child: Icon(icon, size: 22, color: Brand.ink),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(fontSize: 13, color: Brand.inkSoft)),
                                Text(
                                  value,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.15),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Brand.inkSoft),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// "What's there": the beach's features as a checklist.
class _WhatsThere extends StatelessWidget {
  const _WhatsThere(this.b);
  final Beach b;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: Brand.card(shadow: 3, radius: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What’s there', style: Brand.title(28)),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth < 380 ? c.maxWidth : (c.maxWidth - 16) / 2;
            return Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                for (final f in b.features)
                  SizedBox(
                    width: w,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1, right: 8),
                          child: Icon(Icons.check_circle_rounded, size: 20, color: Brand.ocean),
                        ),
                        Expanded(child: Text(f, style: const TextStyle(fontSize: 16, height: 1.3))),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
