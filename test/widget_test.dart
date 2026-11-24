import 'package:beach_finder/models/beach.dart';
import 'package:beach_finder/services/beach_of_the_week.dart';
import 'package:beach_finder/services/beach_repository.dart';
import 'package:beach_finder/services/climate_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all beaches with their amenity flags', () async {
    final repo = await BeachRepository.load();
    expect(repo.beaches, hasLength(50));
    expect(repo.bySlug('island-beach-state-park')!.shacksFood, isFalse);
    // Every beach belongs to a known region, and slugs are unique.
    for (final b in repo.beaches) {
      expect(repo.regions.containsKey(b.region), isTrue, reason: b.slug);
    }
    expect(repo.beaches.map((b) => b.slug).toSet(), hasLength(50));
    expect(repo.regionOf(repo.bySlug('hanauma-bay')!).state, 'Hawaiʻi');
  });

  test('search ignores accents, case and apostrophes', () async {
    final repo = await BeachRepository.load();
    expect(normalize('Waikīkī'), 'waikiki');
    expect(normalize('Oʻahu'), 'oahu');
    expect(repo.find('cape may')!.slug, 'cape-may');
    expect(repo.find('Asbury')!.slug, 'asbury-park');
    expect(repo.find('island beach')!.slug, 'island-beach-state-park');
    expect(repo.find('myrtle beach'), isNull);
    expect(repo.find('waikiki')!.slug, 'waikiki-beach');
    expect(repo.find('Hanauma')!.slug, 'hanauma-bay');
    expect(repo.find('siesta key')!.slug, 'siesta-key-beach');
    expect(repo.find('south beach')!.slug, 'south-beach');
    expect(repo.find('daytona')!.slug, 'daytona-beach');
  });

  test('search page matches names, towns and regions', () async {
    final repo = await BeachRepository.load();
    expect(repo.search(''), hasLength(50));
    expect(repo.search('waikiki').map((b) => b.slug), ['waikiki-beach']);
    expect(repo.search('hawaii'), hasLength(5)); // region "Hawaiʻi"
    expect(repo.search('FLORIDA'), hasLength(5));
    expect(repo.search('cape may').first.slug, 'cape-may');
    expect(repo.search('myrtle'), isEmpty);
    expect(repo.search('aruba').map((b) => b.slug), ['eagle-beach']); // by country
    expect(repo.search('australia'), hasLength(4));
    expect(repo.search('bondi').first.slug, 'bondi-beach');
  });

  test('uses real monthly data and photos when a beach has them', () async {
    final repo = await BeachRepository.load();
    final json = {
      ..._asJson(repo.beaches.first),
      'monthly': [for (final m in ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'])
        {'month': m, 'airF': 70, 'waterF': 65, 'waveFt': '1–3', 'rainIn': 3.4}],
      'monthlySource': 'test',
      'photos': [{'asset': 'assets/images/beaches/x.jpg', 'artist': 'A', 'license': 'CC0', 'source': 'https://example.org'}],
    };
    final b = Beach.fromJson(json);
    final c = const ClimateService().monthlyFor(b);
    expect(c.placeholder, isFalse);
    expect(c.months, hasLength(12));
    expect(b.photos.single.credit, 'Photo: A · CC0 · Wikimedia Commons');
    expect(const ClimateService().monthlyFor(repo.beaches.first).placeholder, repo.beaches.first.monthly.isEmpty);
  });

  test('beaches of the week: 6 picks, same all week, new the next week', () async {
    final repo = await BeachRepository.load();
    final monday = DateTime(2026, 11, 23), sunday = DateTime(2026, 11, 29), next = DateTime(2026, 11, 30);
    final a = beachesOfTheWeek(repo.beaches, monday).map((b) => b.slug).toList();
    expect(a, hasLength(6));
    expect(beachesOfTheWeek(repo.beaches, sunday).map((b) => b.slug), a);
    expect(beachesOfTheWeek(repo.beaches, next).map((b) => b.slug), isNot(a));
    expect(weekNumber(DateTime(2026, 1, 1)), 1);
    expect(weekNumber(DateTime(2026, 11, 23)), 48);
  });
}

Map<String, dynamic> _asJson(Beach b) => {
      'slug': b.slug, 'region': b.region, 'name': b.name, 'area': b.area, 'lat': b.lat, 'lon': b.lon, 'tag': b.tag, 'tags': b.tags,
      'wave': b.wave, 'waveNote': b.waveNote, 'lifeguards': b.lifeguards, 'lifeguardNote': b.lifeguardNote,
      'entry': b.entry, 'entryUnit': b.entryUnit, 'entryNote': b.entryNote, 'parking': b.parking, 'hours': b.hours,
      'description': b.description, 'features': b.features, 'safety': b.safety, 'color': b.color,
      'shacksFood': b.shacksFood, 'waterSportsRentals': b.waterSportsRentals, 'restrooms': b.restrooms,
      'familyFriendly': b.familyFriendly,
    };
