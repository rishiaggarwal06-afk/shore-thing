import 'package:flutter/material.dart';

import '../models/beach.dart';
import '../services/beach_scope.dart';
import '../widgets/brand.dart';
import '../widgets/site_chrome.dart';
import '../widgets/tide_transition.dart';

/// Search page: type a beach, town or region and the list narrows as you type.
/// With nothing typed it lists every beach, grouped by region.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Pressing "Search" on the keyboard opens the top result, or the "not one of ours" page.
  void _submit(List<Beach> results) {
    final q = _text.text.trim();
    if (q.isEmpty) return;
    openBeach(context, results.isNotEmpty ? results.first.slug : q);
  }

  @override
  Widget build(BuildContext context) {
    final repo = BeachScope.of(context);
    final query = _text.text.trim();
    final results = repo.search(query);

    final rows = <Widget>[];
    if (query.isEmpty) {
      // Nothing typed: every beach, under its region's name.
      for (final region in repo.regions.values) {
        rows.add(_RegionHeading(region.name));
        rows.addAll([for (final b in repo.beaches.where((b) => b.region == region.id)) _BeachRow(b)]);
      }
    } else if (results.isEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No beaches match “$query”. We cover ${repo.beaches.length} beaches in ${repo.regionsLabel} so far.',
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
      ));
    } else {
      rows.add(_RegionHeading(results.length == 1 ? '1 beach' : '${results.length} beaches'));
      rows.addAll([for (final b in results) _BeachRow(b)]);
    }

    return Title(
      title: 'Search · Shore Thing',
      color: Brand.ink,
      child: Scaffold(
        body: Column(children: [
          const TopBar(leading: HomeButton()),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
              children: [
                PageWidth(
                  vertical: 16,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(
                      decoration: Brand.chunky(shadow: 4),
                      child: TextField(
                        controller: _text,
                        autofocus: true,
                        maxLength: 100,
                        onSubmitted: (_) => _submit(results),
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontSize: 18, color: Brand.ink),
                        decoration: InputDecoration(
                          hintText: 'Beach, town or region',
                          counterText: '',
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search_rounded, color: Brand.ink),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear',
                                  icon: const Icon(Icons.close_rounded, color: Brand.ink),
                                  onPressed: _text.clear,
                                ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    ...rows,
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _RegionHeading extends StatelessWidget {
  const _RegionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 4),
        child: Semantics(
          header: true,
          child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ),
      );
}

/// One beach in the list: small photo, name, town and state. Tapping opens its page.
class _BeachRow extends StatelessWidget {
  const _BeachRow(this.b);
  final Beach b;

  @override
  Widget build(BuildContext context) {
    // The thumbnail grows with the user's text size so rows stay balanced.
    final thumb = MediaQuery.textScalerOf(context).scale(56);
    return InkWell(
      onTap: () => openBeach(context, b.slug),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Brand.teal, width: 1.5))),
        child: Row(children: [
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
              Text(b.area, style: const TextStyle(fontSize: 14)),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: Brand.ink),
        ]),
      ),
    );
  }
}
