import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/model_extension/routes/model_extension_routes.dart';
import 'package:cineconnect/features/model_extension/screens/model_extension_portal_screen.dart';

void main() {
  void setViewport(WidgetTester tester, {required Size size}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget modelApp({
    required String route,
    ThemeMode mode = ThemeMode.light,
  }) {
    return ThemeControllerProvider(
      controller: ThemeController(initialThemeMode: mode),
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: ModelExtensionPortalScreen(routeName: route),
      ),
    );
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final route in ModelExtensionRoutes.allRoutes) {
      testWidgets(
        '$route in $mode - model route renders without overflow',
        (WidgetTester tester) async {
          setViewport(tester, size: const Size(360, 800));

          await tester.pumpWidget(modelApp(route: route, mode: mode));
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

  for (final route in ModelExtensionRoutes.allRoutes) {
    testWidgets(
      '$route on desktop - workspace shell renders without overflow',
      (WidgetTester tester) async {
        setViewport(tester, size: const Size(1440, 1000));

        await tester.pumpWidget(modelApp(route: route));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Model Workspace'), findsOneWidget);
        expect(find.text(ModelExtensionRoutes.titleFor(route)), findsWidgets);
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
    for (final route in ModelExtensionRoutes.allRoutes) {
      testWidgets(
        '$route on ${viewport.key} - renders without overflow',
        (WidgetTester tester) async {
          setViewport(tester, size: viewport.value);

          await tester.pumpWidget(modelApp(route: route));
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
    'mobile model navigation exposes every workflow',
    (WidgetTester tester) async {
      setViewport(tester, size: const Size(390, 844));

      await tester.pumpWidget(
        modelApp(route: ModelExtensionRoutes.categories),
      );
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Usage'), findsOneWidget);
      expect(find.text('Portfolio'), findsOneWidget);
      expect(find.text('Rates'), findsOneWidget);
      expect(find.text('Safety'), findsOneWidget);
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: 'Unexpected exception: $exception',
      );
    },
  );
}
