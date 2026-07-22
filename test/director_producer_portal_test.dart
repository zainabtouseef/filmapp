import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/core_ui/core_routes.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';

void main() {
  const routes = [
    '/console',
    '/projects',
    '/project/prj-hunza/shortlists',
    '/discover/Talent',
    '/profile/Talent/cand-001',
    '/booking/cand-001',
    '/contract/ctr-001',
    '/payment/pay-001',
  ];

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final route in routes) {
      testWidgets('$route in $mode - director route renders without overflow', (
        WidgetTester tester,
      ) async {
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
              onGenerateInitialRoutes: (_) => [
                CoreRoutes.onGenerateRoute(RouteSettings(name: route)),
              ],
              onGenerateRoute: CoreRoutes.onGenerateRoute,
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
