import 'package:flutter/material.dart';

import '../models/beach.dart';
import 'brand.dart';

/// One beach in a list: small photo, name, a line underneath, and an arrow.
/// Used by the search page, "Beaches of the week" and the list behind a numbered castle.
class BeachListRow extends StatelessWidget {
  const BeachListRow({super.key, required this.beach, required this.onTap, this.subtitle});

  final Beach beach;
  final VoidCallback onTap;

  /// Line under the name; the beach's area if not given.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final b = beach;
    // The thumbnail grows with the user's text size so rows stay balanced.
    final thumb = MediaQuery.textScalerOf(context).scale(56);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Brand.teal, width: 1.5))),
        child: Row(children: [
          Container(
            width: thumb,
            height: thumb,
            decoration: BoxDecoration(color: Brand.sand, borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: b.photos.isEmpty
                ? const Icon(Icons.beach_access_rounded, color: Brand.ink)
                : Image.asset(
                    b.photos.first.asset,
                    fit: BoxFit.cover,
                    cacheWidth: 200, // small copy in memory, it's only a thumbnail
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => const Icon(Icons.beach_access_rounded, color: Brand.ink),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle ?? b.area, style: const TextStyle(fontSize: 14, color: Brand.inkSoft)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: Brand.ink),
        ]),
      ),
    );
  }
}
