import 'package:flutter/material.dart';

import '../models/beach.dart';
import '../services/beach_scope.dart';
import '../widgets/beach_list_row.dart';
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
        rows.addAll([
          for (final b in repo.beaches.where((b) => b.region == region.id))
            BeachListRow(beach: b, onTap: () => openBeach(context, b.slug)),
        ]);
      }
    } else if (results.isEmpty) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No beaches match “$query”. We cover ${repo.beaches.length} beaches in ${repo.regionsLabel} so far.',
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ),
      );
    } else {
      rows.add(_RegionHeading(results.length == 1 ? '1 beach' : '${results.length} beaches'));
      rows.addAll([for (final b in results) BeachListRow(beach: b, onTap: () => openBeach(context, b.slug))]);
    }

    return Title(
      title: 'Search · Shore Thing',
      color: Brand.ink,
      child: Scaffold(
        body: Column(
          children: [
            const TopBar(leading: HomeButton()),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
                children: [
                  PageWidth(
                    vertical: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: Brand.card(shadow: 3, radius: 16),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    child: Semantics(header: true, child: Text(text, style: Brand.title(24))),
  );
}
