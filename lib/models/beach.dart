/// One beach, exactly as stored in assets/data/beaches.json.
class Beach {
  const Beach({
    required this.slug,
    required this.name,
    required this.area,
    required this.lat,
    required this.lon,
    required this.tag,
    required this.tags,
    required this.wave,
    required this.waveNote,
    required this.lifeguards,
    required this.lifeguardNote,
    required this.entry,
    this.entryUnit,
    required this.entryNote,
    required this.parking,
    this.hours,
    required this.description,
    required this.features,
    required this.safety,
    required this.color,
    required this.shacksFood,
    required this.waterSportsRentals,
    required this.restrooms,
    required this.familyFriendly,
  });

  /// URL-friendly name, used in web addresses like /beach/asbury-park.
  final String slug;
  final String name;
  final String area;
  final double lat;
  final double lon;

  /// Short personality line, e.g. "THE WILD ONE".
  final String tag;

  /// Activity filters this beach matches, e.g. "Surf spots".
  final List<String> tags;
  final String wave;
  final String waveNote;
  final String lifeguards;
  final String lifeguardNote;
  final String entry;
  final String? entryUnit;
  final String entryNote;
  final String parking;
  final String? hours;
  final String description;
  final List<String> features;
  final String safety;

  /// Which of the three illustration palettes (0, 1 or 2) to use.
  final int color;

  // Amenity flags, set from each beach's features list.
  final bool shacksFood;
  final bool waterSportsRentals;
  final bool restrooms;
  final bool familyFriendly;

  factory Beach.fromJson(Map<String, dynamic> j) => Beach(
        slug: j['slug'] as String,
        name: j['name'] as String,
        area: j['area'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        tag: j['tag'] as String,
        tags: List<String>.from(j['tags'] as List),
        wave: j['wave'] as String,
        waveNote: j['waveNote'] as String,
        lifeguards: j['lifeguards'] as String,
        lifeguardNote: j['lifeguardNote'] as String,
        entry: j['entry'] as String,
        entryUnit: j['entryUnit'] as String?,
        entryNote: j['entryNote'] as String,
        parking: j['parking'] as String,
        hours: j['hours'] as String?,
        description: j['description'] as String,
        features: List<String>.from(j['features'] as List),
        safety: j['safety'] as String,
        color: j['color'] as int,
        shacksFood: j['shacksFood'] as bool,
        waterSportsRentals: j['waterSportsRentals'] as bool,
        restrooms: j['restrooms'] as bool,
        familyFriendly: j['familyFriendly'] as bool,
      );
}

/// Facts shared by every beach in the region (shown on the stat cards).
class Region {
  const Region({
    required this.name,
    required this.airTemp,
    required this.airNote,
    required this.waterTemp,
    required this.waterNote,
    required this.sourcesNote,
  });

  final String name;
  final String airTemp;
  final String airNote;
  final String waterTemp;
  final String waterNote;
  final String sourcesNote;

  factory Region.fromJson(Map<String, dynamic> j) => Region(
        name: j['name'] as String,
        airTemp: j['airTemp'] as String,
        airNote: j['airNote'] as String,
        waterTemp: j['waterTemp'] as String,
        waterNote: j['waterNote'] as String,
        sourcesNote: j['sourcesNote'] as String,
      );
}
