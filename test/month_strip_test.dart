import 'package:beach_finder/models/month_conditions.dart';
import 'package:beach_finder/widgets/month_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // An iPhone with a large text-size setting, like the screenshot that showed the bug.
  testWidgets('month cards fit their text at large text sizes', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final months = [for (final m in ['Jan', 'Feb', 'Mar']) MonthConditions(m, 42, 41, '3–4', 3.8)];
    for (final scale in [1.0, 1.5, 2.0]) {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: const Size(390, 844), textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: BestTimeToGo(climate: (months: months, placeholder: false, source: 'test')),
            ),
          ),
        ),
      ));
      // A layout overflow (text spilling out of a card) fails the test with an exception.
      expect(tester.takeException(), isNull, reason: 'overflow at text scale $scale');
    }
  });
}
