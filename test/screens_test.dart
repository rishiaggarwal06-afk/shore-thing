import 'dart:io';

import 'package:beach_finder/main.dart';
import 'package:beach_finder/services/beach_repository.dart';
import 'package:beach_finder/widgets/beach_card.dart';
import 'package:beach_finder/widgets/beach_preview.dart';
import 'package:beach_finder/widgets/wave_intro.dart';
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
      ('PlusJakartaSans', ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'].map((w) => 'assets/fonts/PlusJakartaSans-$w.ttf')),
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

  for (final path in ['/', '/search', '/beach/asbury-park', '/beach/myrtle-beach']) {
    testWidgets('$path fits on an iPhone at large text sizes', (tester) async {
      final repo = (await tester.runAsync(BeachRepository.load))!;
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      for (final scale in [1.0, 2.0]) {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        await tester.pumpWidget(ShoreThingApp(repo: repo, intro: false));
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

  testWidgets('tapping a map card opens the mini preview, and Back closes it', (tester) async {
    final repo = (await tester.runAsync(BeachRepository.load))!;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final scale in [1.0, 2.0]) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      await tester.pumpWidget(ShoreThingApp(repo: repo, intro: false));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(BeachCard), findsWidgets);
      await tester.tap(find.byType(BeachCard).hitTestable().first);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(BeachPreview), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'preview at text scale $scale');
      await tester.tap(find.text('Back'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(BeachPreview), findsNothing);
    }
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  testWidgets('wave intro plays over the map, then goes away', (tester) async {
    final repo = (await tester.runAsync(BeachRepository.load))!;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ShoreThingApp(repo: repo));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(WaveIntro), findsOneWidget);
    // 3 s of intro, plus a moment for it to start once the first frames are drawn.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(WaveIntro), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
