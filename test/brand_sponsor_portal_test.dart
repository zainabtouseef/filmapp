import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/brand_sponsors/routes/brand_sponsor_routes.dart';
import 'package:cineconnect/features/brand_sponsors/screens/brand_sponsor_portal_screen.dart';

void main() {
  void setViewport(WidgetTester tester, {required Size size}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget brandApp({
    required String route,
    ThemeMode mode = ThemeMode.dark,
  }) {
    return ThemeControllerProvider(
      controller: ThemeController(initialThemeMode: mode),
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: BrandSponsorPortalScreen(routeName: route),
      ),
    );
  }

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final route in BrandSponsorRoutes.allRoutes) {
      testWidgets(
        '$route in $mode - brand route renders without overflow',
        (WidgetTester tester) async {
          setViewport(tester, size: const Size(360, 800));

          await tester.pumpWidget(brandApp(route: route, mode: mode));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          final exception = tester.takeException();
          expect(
            exception,
            isNull,
            reason: 'Unexpected exception: $exception',
          );
        },
      );
    }
  }

  for (final route in BrandSponsorRoutes.allRoutes) {
    testWidgets(
      '$route on desktop - workspace shell renders without overflow',
      (WidgetTester tester) async {
        setViewport(tester, size: const Size(1440, 1000));

        await tester.pumpWidget(brandApp(route: route));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Campaign operations portal'), findsOneWidget);
        expect(find.text(BrandSponsorRoutes.titleFor(route)), findsWidgets);
        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: 'Unexpected exception: $exception',
        );
      },
    );
  }

  for (final viewport in const {
    'tablet': Size(768, 1024),
    'laptop': Size(1280, 800),
  }.entries) {
    for (final route in BrandSponsorRoutes.allRoutes) {
      testWidgets(
        '$route on ${viewport.key} - renders without overflow',
        (WidgetTester tester) async {
          setViewport(tester, size: viewport.value);

          await tester.pumpWidget(brandApp(route: route));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          final exception = tester.takeException();
          expect(
            exception,
            isNull,
            reason: 'Unexpected exception: $exception',
          );
        },
      );
    }
  }

  testWidgets(
    'mobile More opens the complete brand workspace menu',
    (WidgetTester tester) async {
      setViewport(tester, size: const Size(390, 844));

      await tester.pumpWidget(
        brandApp(route: BrandSponsorRoutes.home),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('Brand Profile'), findsOneWidget);
      expect(find.text('Terms & Deals'), findsOneWidget);
      expect(find.text('Finance & Records'), findsOneWidget);
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: 'Unexpected exception: $exception',
      );
    },
  );
}
