import 'beach.dart';

/// A filter chip on the home screen: a label plus a rule for which beaches match.
class BeachFilter {
  const BeachFilter(this.label, this.matches);

  final String label;
  final bool Function(Beach b) matches;

  static final all = BeachFilter('All beaches', (_) => true);

  /// Activity filters (from each beach's tags).
  static final activities = [
    for (final t in ['Calm swimming', 'Snorkeling', 'Surf spots', 'Quiet escapes', 'Boardwalk fun', 'Nature & wildlife'])
      BeachFilter(t, (b) => b.tags.contains(t)),
  ];

  /// Amenity filters (from the yes/no amenity fields).
  static final amenities = [
    BeachFilter('Shacks & food', (b) => b.shacksFood),
    BeachFilter('Water sports rentals', (b) => b.waterSportsRentals),
    BeachFilter('Restrooms', (b) => b.restrooms),
    BeachFilter('Family friendly', (b) => b.familyFriendly),
  ];
}
