import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/legal_partner/routes/legal_partner_routes.dart';
import 'package:cineconnect/features/legal_partner/screens/legal_partner_portal_screen.dart';

void main() {
  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final route in LegalPartnerRoutes.allRoutes) {
      testWidgets('$route in $mode - legal partner route renders',
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
              home: LegalPartnerPortalScreen(routeName: route),
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
