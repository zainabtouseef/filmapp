import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/media_equipment/routes/media_equipment_routes.dart';
import 'package:cineconnect/features/media_equipment/screens/media_equipment_portal_screen.dart';

void main() {
  void setViewport(WidgetTester tester, {required Size size}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget equipmentApp({
    required String route,
    ThemeMode mode = ThemeMode.light,
  }) {
    return ThemeControllerProvider(
      controller: ThemeController(initialThemeMode: mode),
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: MediaEquipmentPortalScreen(routeName: route),
      ),
    );
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final route in MediaEquipmentRoutes.allRoutes) {
      testWidgets(
        '$route in $mode - media equipment route renders without overflow',
        (WidgetTester tester) async {
          setViewport(tester, size: const Size(360, 800));

          await tester.pumpWidget(equipmentApp(route: route, mode: mode));
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

  for (final route in MediaEquipmentRoutes.allRoutes) {
    testWidgets(
      '$route on desktop - workspace shell renders without overflow',
      (WidgetTester tester) async {
        setViewport(tester, size: const Size(1440, 1000));

        await tester.pumpWidget(equipmentApp(route: route));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Equipment Workspace'), findsWidgets);
        expect(find.text(MediaEquipmentRoutes.titleFor(route)), findsWidgets);
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
    for (final route in MediaEquipmentRoutes.allRoutes) {
      testWidgets(
        '$route on ${viewport.key} - renders without overflow',
        (WidgetTester tester) async {
          setViewport(tester, size: viewport.value);

          await tester.pumpWidget(equipmentApp(route: route));
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
    'mobile More opens the complete equipment workspace menu',
    (WidgetTester tester) async {
      setViewport(tester, size: const Size(390, 844));

      await tester.pumpWidget(
        equipmentApp(route: MediaEquipmentRoutes.home),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('Provider Profile'), findsOneWidget);
      expect(find.text('Rental Packages'), findsOneWidget);
      expect(find.text('Rates & Terms'), findsOneWidget);
      expect(find.text('Returns & Claims'), findsOneWidget);
      expect(find.text('Earnings & Ratings'), findsOneWidget);
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: 'Unexpected exception: $exception',
      );
    },
  );
}
