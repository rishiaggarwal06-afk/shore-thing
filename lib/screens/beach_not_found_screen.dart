import 'package:flutter/material.dart';

import '../services/beach_scope.dart';
import '../widgets/brand.dart';
import '../widgets/tide_transition.dart';
import 'beach_detail_screen.dart';

/// Shown when a search (or a typed-in web address) doesn't match any of our beaches.
class BeachNotFoundScreen extends StatelessWidget {
  const BeachNotFoundScreen({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final repo = BeachScope.of(context);
    return SitePage(children: [
      const BackToMap(),
      const SizedBox(height: 14),
      DetailHead(
        eyebrow: 'NOT ONE OF OUR TEN (YET)',
        title: query,
        text: 'We don’t have a guide for that beach yet. Here are the ten ${repo.region.name} favorites we do cover.',
      ),
      const SizedBox(height: 24),
      LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth < 560 ? 1 : (c.maxWidth < 900 ? 2 : 3);
        final w = (c.maxWidth - 12.0 * (cols - 1) - 4) / cols;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final b in repo.beaches)
            SizedBox(
              width: w,
              child: InkWell(
                onTap: () => openBeach(context, b.slug),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: Brand.chunky(shadow: 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                    const SizedBox(height: 4),
                    Text(b.area, style: const TextStyle(fontSize: 13)),
                  ]),
                ),
              ),
            ),
        ]);
      }),
    ]);
  }
}
