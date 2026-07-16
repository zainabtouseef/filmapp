import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/super_admin/routes/super_admin_routes.dart';
import 'package:cineconnect/features/super_admin/screens/super_admin_screens.dart';

void main() {
  final routes = [
    SuperAdminRoutes.reviewHub,
    SuperAdminRoutes.reviewHubPeople,
    SuperAdminRoutes.reviewHubListings,
    SuperAdminRoutes.reviewHubContent,
  ];

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final size in [const Size(360, 800), const Size(411, 914)]) {
      for (final route in routes) {
        testWidgets('$route at ${size.width}x${size.height} in $mode - no overflow',
            (WidgetTester tester) async {
          tester.view.physicalSize = size;
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
                home: SuperAdminPortalScreen(routeName: route),
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
}
