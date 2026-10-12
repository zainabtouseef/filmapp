import 'package:cineconnect/core/auth/auth_controller.dart';
import 'package:cineconnect/core/auth/auth_repository.dart';
import 'package:cineconnect/core/auth/token_store.dart';
import 'package:cineconnect/core/cineplanner/cineplanner_controller.dart';
import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/director_producer/routes/director_producer_routes.dart';
import 'package:cineconnect/features/director_producer/screens/director_producer_portal_screen.dart';
import 'package:cineconnect/features/general_public/routes/general_public_routes.dart';
import 'package:cineconnect/features/general_public/screens/general_public_portal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final size in const [Size(390, 844), Size(1440, 1000)]) {
    for (final route in DirectorProducerRoutes.allRoutes) {
      testWidgets('director $route renders at ${size.width}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        final api = ApiClient(
          baseUrl: 'https://cine.test/api/v1',
          httpClient: MockClient((_) async => http.Response(
                '{"error":{"code":"audit.unavailable","message":"Audit offline"}}',
                503,
                headers: {'content-type': 'application/json'},
              )),
        );
        final auth = AuthController(
          repository: AuthRepository(api),
          client: api,
          tokenStore: const TokenStore(),
        );
        await tester.pumpWidget(AuthScope(
          controller: auth,
          child: CinePlannerScope(
            controller: CinePlannerController.fromClient(api),
            child: ThemeControllerProvider(
              controller: ThemeController(initialThemeMode: ThemeMode.light),
              child: MaterialApp(
                theme: AppTheme.light,
                home: DirectorProducerPortalScreen(routeName: route),
              ),
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: route);
      });
    }
    for (final route in GeneralPublicRoutes.allRoutes) {
      testWidgets('public $route renders at ${size.width}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(
          ThemeControllerProvider(
            controller: ThemeController(initialThemeMode: ThemeMode.light),
            child: MaterialApp(
              theme: AppTheme.light,
              home: GeneralPublicPortalScreen(routeName: route),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: route);
      });
    }
  }
}
