import 'package:flutter/material.dart';

import '../models/beach.dart';
import 'brand.dart';

/// Card in the row along the bottom of the map: photo, name, town, what it's
/// good for, entry fee and lifeguards. Tapping it opens the beach page.
class BeachCard extends StatelessWidget {
  const BeachCard({super.key, required this.beach, required this.selected, required this.onTap});

  final Beach beach;
  final bool selected;
  final VoidCallback onTap;

  static const _pad = 12.0;
  static const _shadow = 4.0;
  static const _name = TextStyle(fontSize: 17, fontWeight: FontWeight.w900, height: 1.25);
  static const _small = TextStyle(fontSize: 13, height: 1.35);

  /// Height the card needs at the user's text size (the iPhone's big text setting included).
  static double heightFor(BuildContext context) {
    final t = MediaQuery.textScalerOf(context);
    // + a little spare room (half a line), since fonts measure slightly differently on each device.
    return _pad * 2 + _shadow + t.scale(17) * 1.25 + t.scale(13) * 1.35 * 3.5 + 8;
  }

  String get _entry => beach.entry == 'Free' ? 'Free entry' : '${beach.entry} ${beach.entryUnit ?? ''}'.trim();
  String get _guards => beach.lifeguards.startsWith('Yes') ? 'Lifeguards' : 'No lifeguards';

  @override
  Widget build(BuildContext context) {
    final b = beach;
    return Semantics(
      button: true,
      label: '${b.name}, ${b.area}. ${b.tags.join(', ')}. $_entry, $_guards. Open beach page',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: _shadow, bottom: _shadow),
          padding: const EdgeInsets.all(_pad),
          decoration: Brand.chunky(color: selected ? Brand.yellow : Colors.white, shadow: _shadow),
          child: LayoutBuilder(
            builder: (context, c) => Row(children: [
              // Square photo as tall as the card's text.
              Container(
                width: c.maxHeight,
                height: c.maxHeight,
                decoration: BoxDecoration(color: Brand.sand, border: Border.all(color: Brand.ink, width: 2)),
                clipBehavior: Clip.antiAlias,
                child: b.photos.isEmpty
                    ? const Icon(Icons.beach_access_rounded, color: Brand.ink)
                    : Image.asset(
                        b.photos.first.asset,
                        fit: BoxFit.cover,
                        cacheWidth: 240, // small copy in memory, it's only a thumbnail
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => const Icon(Icons.beach_access_rounded, color: Brand.ink),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _line(b.name, _name),
                    const SizedBox(height: 2),
                    _line(b.area, _small),
                    const SizedBox(height: 6),
                    _line(b.tags.join(' · '), _small.copyWith(fontWeight: FontWeight.w700)),
                    _line('$_entry · $_guards', _small),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Brand.ink),
            ]),
          ),
        ),
      ),
    );
  }

  static Widget _line(String text, TextStyle style) =>
      Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
}
