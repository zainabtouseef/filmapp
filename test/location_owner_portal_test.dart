import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/location_owner/routes/location_owner_routes.dart';
import 'package:cineconnect/features/location_owner/screens/location_owner_portal_screen.dart';

void main() {
  void setViewport(WidgetTester tester, {required Size size}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget locationApp({
    required String route,
    ThemeMode mode = ThemeMode.dark,
  }) {
    return ThemeControllerProvider(
      controller: ThemeController(initialThemeMode: mode),
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: LocationOwnerPortalScreen(routeName: route),
      ),
    );
  }

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final route in LocationOwnerRoutes.allRoutes) {
      testWidgets(
        '$route in $mode - location owner route renders without overflow',
        (WidgetTester tester) async {
          setViewport(tester, size: const Size(360, 800));

          await tester.pumpWidget(locationApp(route: route, mode: mode));
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

  for (final route in LocationOwnerRoutes.allRoutes) {
    testWidgets(
      '$route on desktop - workspace shell renders without overflow',
      (WidgetTester tester) async {
        setViewport(tester, size: const Size(1440, 1000));

        await tester.pumpWidget(locationApp(route: route));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Property operations portal'), findsOneWidget);
        expect(find.text(LocationOwnerRoutes.titleFor(route)), findsWidgets);
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
    for (final route in LocationOwnerRoutes.allRoutes) {
      testWidgets(
        '$route on ${viewport.key} - renders without overflow',
        (WidgetTester tester) async {
          setViewport(tester, size: viewport.value);

          await tester.pumpWidget(locationApp(route: route));
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
    'mobile More opens the complete location workspace menu',
    (WidgetTester tester) async {
      setViewport(tester, size: const Size(390, 844));

      await tester.pumpWidget(
        locationApp(route: LocationOwnerRoutes.home),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('Properties'), findsOneWidget);
      expect(find.text('Rates & Deposits'), findsOneWidget);
      expect(find.text('Check-Out & Claims'), findsOneWidget);
      expect(find.text('Property Insights'), findsOneWidget);
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: 'Unexpected exception: $exception',
      );
    },
  );
}
