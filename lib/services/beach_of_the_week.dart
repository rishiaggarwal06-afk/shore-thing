import 'dart:math' as math;

import '../models/beach.dart';

/// "Beaches of the week": [count] beaches that stay the same all week and change
/// every Monday. Everyone sees the same picks, because they're chosen by a fixed
/// shuffle that depends only on the year and week number, not on a random seed.
/// Picks are spread out so one region doesn't take every spot.
List<Beach> beachesOfTheWeek(List<Beach> all, DateTime now, {int count = 6}) {
  final week = weekNumber(now);
  final shuffled = [...all]..shuffle(math.Random(now.year * 100 + week));
  final picks = <Beach>[];
  final perRegion = <String, int>{};
  for (final b in shuffled) {
    if (picks.length == count) break;
    if ((perRegion[b.region] ?? 0) >= 2) continue; // at most 2 from any one region
    picks.add(b);
    perRegion[b.region] = (perRegion[b.region] ?? 0) + 1;
  }
  return picks;
}

/// The ISO week number (weeks start on Monday; week 1 contains the year's first Thursday).
int weekNumber(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  final thursday = day.add(Duration(days: 4 - day.weekday)); // weekday: Mon = 1 … Sun = 7
  final firstThursday = DateTime(thursday.year, 1, 1);
  return ((thursday.difference(firstThursday).inDays) ~/ 7) + 1;
}
