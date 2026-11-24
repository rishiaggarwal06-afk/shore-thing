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
  const SitePage({super.key, required this.children, this.beach, this.hero});
  final List<Widget> children;

  /// Full-width piece above the page content (the beach's photos), edge to edge.
  final Widget? hero;

  /// The beach this page is about, for its photo credits in the footer's Credits panel.
  final Beach? beach;

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
                ?hero,
                PageWidth(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
                ),
                SiteFooter(beach: beach),
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
        Semantics(header: true, child: Text(title, style: Brand.title(phone ? 34 : 48))),
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
        beach: b,
        hero: PhotoGallery(beach: b, edgeToEdge: true),
        children: [
          const SizedBox(height: 4),
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
          // Sources and full photo credits live behind "Credits & sources" in the footer.
        ],
      ),
    );
  }
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
    // A plain list with thin dividers: each row opens a panel with the full details.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (icon, _, title, value, note) in tiles)
          Semantics(
            button: true,
            label: '$title: $value. Show details',
            excludeSemantics: true,
            child: InkWell(
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
                        child: Text(value, style: Brand.title(30)),
                      ),
                    Text(note, style: const TextStyle(fontSize: 17, height: 1.45)),
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Brand.teal)),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: Brand.ocean),
                    const SizedBox(width: 14),
                    Text(title, style: const TextStyle(fontSize: 16, color: Brand.inkSoft)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value == 'Details' || value == 'Tips' ? '' : value,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: Brand.inkSoft),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "What's there": the beach's features as a checklist.
class _WhatsThere extends StatelessWidget {
  const _WhatsThere(this.b);
  final Beach b;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What’s there', style: Brand.title(24)),
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
