import 'dart:io';

import 'package:beach_finder/main.dart';
import 'package:beach_finder/services/beach_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Opens each page on an iPhone-sized screen at normal and large text sizes.
/// Text spilling out of its box throws an error, which fails the test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Tests normally draw every letter as a wide square; load the app's real fonts so widths match a phone.
  setUpAll(() async {
    for (final (family, files) in [
      ('LiberationSans', ['Regular', 'Bold', 'Italic', 'BoldItalic'].map((w) => 'assets/fonts/LiberationSans-$w.ttf')),
      ('DejaVuSans', ['assets/fonts/DejaVuSans.ttf', 'assets/fonts/DejaVuSans-Bold.ttf']),
      ('MaterialIcons', ['${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        final file = File(f);
        if (file.existsSync()) loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      }
      await loader.load();
    }
  });

  for (final path in ['/search', '/beach/asbury-park', '/beach/myrtle-beach']) {
    testWidgets('$path fits on an iPhone at large text sizes', (tester) async {
      final repo = (await tester.runAsync(BeachRepository.load))!;
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      for (final scale in [1.0, 2.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpWidget(ShoreThingApp(repo: repo));
        await tester.pump();
        GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull, reason: '$path at text scale $scale');
      }
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
  }
}
