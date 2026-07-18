import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/auth/auth_controller.dart';
import 'package:cineconnect/core/auth/auth_repository.dart';
import 'package:cineconnect/core/auth/token_store.dart';
import 'package:cineconnect/core/core_ui/screens/onboarding_screen.dart';
import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/main.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';

void main() {
  testWidgets('renders CineConnect shared launch flow without overflow errors',
      (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final apiClient = ApiClient();
    final authController = AuthController(
      repository: AuthRepository(apiClient),
      client: apiClient,
      tokenStore: const TokenStore(),
    );

    await tester.pumpWidget(
      CineConnectApp(
        controller: ThemeController(),
        authController: authController,
        homeOverride: const OnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final exception = tester.takeException();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Find Verified Industry Professionals'), findsOneWidget);
    expect(exception, isNull, reason: 'Unexpected exception: $exception');
  });
}
