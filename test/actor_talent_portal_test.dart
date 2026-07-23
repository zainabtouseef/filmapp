import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/actor_talent/routes/actor_talent_routes.dart';
import 'package:cineconnect/features/actor_talent/screens/actor_talent_portal_screen.dart';

void main() {
  void setViewport(
    WidgetTester tester, {
    required Size size,
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget actorApp({
    required String route,
    ThemeMode mode = ThemeMode.dark,
  }) {
    return ThemeControllerProvider(
      controller: ThemeController(initialThemeMode: mode),
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: ActorTalentPortalScreen(routeName: route),
      ),
    );
  }

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final route in ActorTalentRoutes.allRoutes) {
      testWidgets('$route in $mode - actor route renders without overflow',
          (WidgetTester tester) async {
        setViewport(tester, size: const Size(360, 800));

        await tester.pumpWidget(actorApp(route: route, mode: mode));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final exception = tester.takeException();
        expect(exception, isNull, reason: 'Unexpected exception: $exception');
      });
    }
  }

  for (final route in ActorTalentRoutes.allRoutes) {
    testWidgets('$route on desktop - workspace shell renders without overflow',
        (WidgetTester tester) async {
      setViewport(tester, size: const Size(1440, 1000));

      await tester.pumpWidget(actorApp(route: route));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Actor / Talent Portal'), findsOneWidget);
      expect(find.text(ActorTalentRoutes.titleFor(route)), findsWidgets);
      final exception = tester.takeException();
      expect(exception, isNull, reason: 'Unexpected exception: $exception');
    });
  }

  testWidgets('mobile More opens the complete actor workspace menu',
      (WidgetTester tester) async {
    setViewport(tester, size: const Size(390, 844));

    await tester.pumpWidget(actorApp(route: ActorTalentRoutes.dashboard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Casting Profile'), findsOneWidget);
    expect(find.text('Contracts'), findsOneWidget);
    expect(find.text('Reviews'), findsWidgets);
    expect(find.text('Safety & Support'), findsOneWidget);
    final exception = tester.takeException();
    expect(exception, isNull, reason: 'Unexpected exception: $exception');
  });
}
