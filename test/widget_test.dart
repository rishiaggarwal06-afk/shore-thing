import 'package:beach_finder/services/beach_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads all ten beaches with their amenity flags', () async {
    final repo = await BeachRepository.load();
    expect(repo.beaches, hasLength(10));
    expect(repo.bySlug('island-beach-state-park')!.shacksFood, isFalse);
  });

  test('search ignores accents, case and apostrophes', () async {
    final repo = await BeachRepository.load();
    expect(normalize('Waikīkī'), 'waikiki');
    expect(normalize('Oʻahu'), 'oahu');
    expect(repo.find('cape may')!.slug, 'cape-may');
    expect(repo.find('Asbury')!.slug, 'asbury-park');
    expect(repo.find('island beach')!.slug, 'island-beach-state-park');
    expect(repo.find('myrtle beach'), isNull);
  });
}
