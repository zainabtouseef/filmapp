import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/brand_sponsors/routes/brand_sponsor_routes.dart';
import 'package:cineconnect/features/brand_sponsors/screens/brand_sponsor_portal_screen.dart';

void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final route in BrandSponsorRoutes.allRoutes) {
      testWidgets('$route in $mode - brand sponsor route renders',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ThemeControllerProvider(
            controller: ThemeController(initialThemeMode: mode),
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              home: BrandSponsorPortalScreen(routeName: route),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final exception = tester.takeException();
        expect(exception, isNull, reason: 'Unexpected exception: $exception');
      });
    }
  }
}
