import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cineconnect/core/auth/auth_controller.dart';
import 'package:cineconnect/core/auth/auth_repository.dart';
import 'package:cineconnect/core/auth/token_store.dart';
import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/super_admin/routes/super_admin_routes.dart';
import 'package:cineconnect/features/super_admin/screens/super_admin_screens.dart';
import 'package:cineconnect/main.dart';

void main() {
  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget adminApp({
    required String route,
    Object? arguments,
    ThemeController? themeController,
  }) {
    final client = ApiClient(
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode(<String, Object?>{'data': <String, Object?>{}}),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
      baseUrl: 'https://admin.test/api/v1',
    );
    final authController = AuthController(
      repository: AuthRepository(client),
      client: client,
      tokenStore: const TokenStore(),
    );
    final controller = themeController ?? ThemeController();
    return CineConnectApp(
      controller: controller,
      authController: authController,
      homeOverride: SuperAdminPortalScreen(
        routeName: route,
        arguments: arguments,
      ),
    );
  }

  for (final route in SuperAdminRoutes.allRoutes) {
    testWidgets(
      '$route renders on mobile without layout errors',
      (tester) async {
        setViewport(tester, const Size(390, 844));

        await tester.pumpWidget(adminApp(route: route));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Super Admin'), findsWidgets);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Unexpected exception while rendering $route on mobile.',
        );
      },
    );

    testWidgets(
      '$route renders on desktop without layout errors',
      (tester) async {
        setViewport(tester, const Size(1440, 1000));

        await tester.pumpWidget(adminApp(route: route));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('PLATFORM CONTROL'), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Unexpected exception while rendering $route on desktop.',
        );
      },
    );
  }

  testWidgets('header theme control starts light and switches to dark',
      (tester) async {
    setViewport(tester, const Size(1440, 1000));
    final themeController = ThemeController();

    await tester.pumpWidget(
      adminApp(
        route: SuperAdminRoutes.dashboard,
        themeController: themeController,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(themeController.themeMode, ThemeMode.light);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pump();

    expect(themeController.themeMode, ThemeMode.dark);
    expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile More menu exposes the complete control navigation',
      (tester) async {
    setViewport(tester, const Size(390, 844));

    await tester.pumpWidget(adminApp(route: SuperAdminRoutes.dashboard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Verifications'), findsWidgets);
    expect(find.text('Payments'), findsWidgets);
    expect(find.text('Admin Management'), findsWidgets);
    expect(find.text('Activity Log'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final deepLink in <String, String>{
    SuperAdminRoutes.bookingPath('BK-42'): 'Case Detail',
    SuperAdminRoutes.verificationPath('KYC-42'): 'Verification Detail',
    SuperAdminRoutes.paymentReviewPath('PP-42'): 'Payment Review',
    SuperAdminRoutes.contractTemplatePath('CTPL-42'): 'Contract Detail',
    SuperAdminRoutes.disputePath('DSP-42'): 'Dispute Detail',
  }.entries) {
    testWidgets('${deepLink.key} resolves to ${deepLink.value}',
        (tester) async {
      setViewport(tester, const Size(1280, 900));

      final client = ApiClient(
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'error': {
                'code': 'test.not_found',
                'message': 'Test record is not available.',
              },
            }),
            404,
            headers: {'content-type': 'application/json'},
          ),
        ),
        baseUrl: 'https://admin.test/api/v1',
      );
      final authController = AuthController(
        repository: AuthRepository(client),
        client: client,
        tokenStore: const TokenStore(),
      );

      await tester.pumpWidget(
        CineConnectApp(
          controller: ThemeController(),
          authController: authController,
          initialRoute: deepLink.key,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(deepLink.value), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
