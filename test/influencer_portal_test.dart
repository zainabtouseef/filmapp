import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/influencer/routes/influencer_routes.dart';
import 'package:cineconnect/features/influencer/screens/influencer_portal_screen.dart';

void main() {
  void setViewport(WidgetTester tester, {required Size size}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget influencerApp({
    required String route,
    ThemeMode mode = ThemeMode.dark,
  }) {
    return ThemeControllerProvider(
      controller: ThemeController(initialThemeMode: mode),
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: InfluencerPortalScreen(routeName: route),
      ),
    );
  }

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final route in InfluencerRoutes.allRoutes) {
      testWidgets(
        '$route in $mode - influencer route renders without overflow',
        (WidgetTester tester) async {
          setViewport(tester, size: const Size(390, 844));

          await tester.pumpWidget(influencerApp(route: route, mode: mode));
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

  for (final route in InfluencerRoutes.allRoutes) {
    testWidgets(
      '$route on desktop - workspace shell renders',
      (WidgetTester tester) async {
        setViewport(tester, size: const Size(1440, 1000));

        await tester.pumpWidget(influencerApp(route: route));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Influencer Workspace'), findsOneWidget);
        expect(find.text(InfluencerRoutes.titleFor(route)), findsWidgets);
        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: 'Unexpected exception: $exception',
        );
      },
    );
  }

  testWidgets(
    'mobile influencer navigation exposes core workflow tabs',
    (WidgetTester tester) async {
      setViewport(tester, size: const Size(390, 844));

      await tester.pumpWidget(influencerApp(route: InfluencerRoutes.home));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Media Kit'), findsWidgets);
      expect(find.text('Packages'), findsWidgets);
      expect(find.text('Campaigns'), findsWidgets);
      expect(find.text('Analytics'), findsWidgets);
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: 'Unexpected exception: $exception',
      );
    },
  );
}
