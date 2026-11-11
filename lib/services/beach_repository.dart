import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/beach.dart';

/// Loads the beach list from assets/data/beaches.json and answers searches.
class BeachRepository {
  BeachRepository(this.regions, this.sourcesNote, this.beaches);

  /// Regions in display order, by id.
  final Map<String, Region> regions;

  /// Shared "where this info comes from" note shown on beach pages.
  final String sourcesNote;
  final List<Beach> beaches;

  Region regionOf(Beach b) => regions[b.region]!;

  /// "the Jersey Shore, Florida and Hawaiʻi"
  String get regionsLabel {
    final names = [for (final r in regions.values) r.name == 'Jersey Shore' ? 'the Jersey Shore' : r.name];
    if (names.length < 2) return names.join();
    return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
  }

  static Future<BeachRepository> load() async {
    final raw = await rootBundle.loadString('assets/data/beaches.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return BeachRepository(
      {
        for (final e in (json['regions'] as Map<String, dynamic>).entries)
          e.key: Region.fromJson(e.key, e.value as Map<String, dynamic>),
      },
      json['sourcesNote'] as String,
      [for (final b in json['beaches'] as List) Beach.fromJson(b as Map<String, dynamic>)],
    );
  }

  Beach? bySlug(String slug) {
    for (final b in beaches) {
      if (b.slug == slug) return b;
    }
    return null;
  }

  /// Same matching as the prototype: an exact name first, then a partial match.
  /// Accents and the ʻokina are ignored, so "waikiki" would find "Waikīkī".
  Beach? find(String query) {
    final n = normalize(query);
    if (n.isEmpty) return null;
    for (final b in beaches) {
      if (normalize(b.name) == n) return b;
    }
    for (final b in beaches) {
      final name = normalize(b.name);
      final first = name.split(' ').first;
      // "beach" alone is too common to count as a match (e.g. "myrtle beach").
      if (name.contains(n) || (first != 'beach' && n.contains(first))) return b;
    }
    return null;
  }
}

const _accents = {
  'a': 'āáàâäãåą',
  'c': 'çćč',
  'e': 'ēéèêëęě',
  'i': 'īíìîï',
  'n': 'ñń',
  'o': 'ōóòôöõø',
  's': 'śšş',
  'u': 'ūúùûüů',
  'y': 'ýÿ',
  'z': 'źżž',
};

/// Lowercase, strip accents/macrons and the ʻokina and apostrophes, trim.
String normalize(String s) {
  final out = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    if ("ʻ‘’'".contains(ch)) continue;
    var plain = ch;
    for (final e in _accents.entries) {
      if (e.value.contains(ch)) {
        plain = e.key;
        break;
      }
    }
    out.write(plain);
  }
  return out.toString().trim();
}
