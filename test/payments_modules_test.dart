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
  Widget adminApp({
    required String route,
    required ThemeMode mode,
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
    return CineConnectApp(
      controller: ThemeController(initialThemeMode: mode),
      authController: authController,
      homeOverride: SuperAdminPortalScreen(routeName: route),
    );
  }

  final routes = [
    SuperAdminRoutes.dashboard,
    SuperAdminRoutes.payments,
    SuperAdminRoutes.paymentQueue,
    SuperAdminRoutes.paymentReview,
    SuperAdminRoutes.paymentLedger,
    SuperAdminRoutes.paymentRevenue,
    SuperAdminRoutes.fees,
    SuperAdminRoutes.disputes,
    SuperAdminRoutes.disputeCase,
    SuperAdminRoutes.bookingsMonitor,
    SuperAdminRoutes.bookingDetail,
    SuperAdminRoutes.contractTemplates,
    SuperAdminRoutes.contractTemplateDetail,
  ];

  for (final mode in [ThemeMode.dark, ThemeMode.light]) {
    for (final size in [const Size(360, 800), const Size(411, 914)]) {
      for (final route in routes) {
        testWidgets(
            '$route at ${size.width}x${size.height} in $mode - no overflow',
            (WidgetTester tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(adminApp(route: route, mode: mode));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          final exception = tester.takeException();
          expect(exception, isNull, reason: 'Unexpected exception: $exception');
        });
      }
    }
  }
}
