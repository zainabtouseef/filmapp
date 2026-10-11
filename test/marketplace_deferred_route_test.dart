import 'package:cineconnect/core/auth/auth_controller.dart';
import 'package:cineconnect/core/auth/auth_models.dart';
import 'package:cineconnect/core/auth/auth_repository.dart';
import 'package:cineconnect/core/auth/token_store.dart';
import 'package:cineconnect/core/core_ui/core_routes.dart';
import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/core/verification/verification_models.dart';
import 'package:cineconnect/shared/layout/portal_page_header.dart';
import 'package:cineconnect/shared/marketplace/marketplace_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryTokenStore extends TokenStore {
  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<void> clear() async {}
}

class _InsuranceAuthRepository extends AuthRepository {
  _InsuranceAuthRepository(super.client);

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async =>
      const AuthSession(
        user: AuthUser(
          publicId: 'insurance-1',
          email: 'insurance@example.com',
          displayName: 'Insurance Partner',
          status: 'active',
          roles: [
            AuthRole(
              code: 'insurance_partner',
              name: 'Insurance / Safety Partner',
              portalRoute: '/insurance',
              requiresKyc: true,
              isPrimary: true,
            ),
          ],
        ),
        tokens: AuthTokens(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          expiresIn: 3600,
          tokenType: 'Bearer',
        ),
      );

  @override
  Future<List<KycSubmission>> myKycSubmissions() async => const [];
}

void main() {
  testWidgets(
    'Marketplace switches deferred bundles when a role session becomes ready',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final client = ApiClient();
      final auth = AuthController(
        repository: _InsuranceAuthRepository(client),
        client: client,
        tokenStore: _MemoryTokenStore(),
      );

      await tester.pumpWidget(
        AuthScope(
          controller: auth,
          child: ThemeControllerProvider(
            controller: ThemeController(initialThemeMode: ThemeMode.dark),
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.dark,
              onGenerateInitialRoutes: (_) => [
                CoreRoutes.onGenerateRoute(
                  const RouteSettings(name: MarketplaceRoutes.browse),
                ),
              ],
              onGenerateRoute: CoreRoutes.onGenerateRoute,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      await auth.login(email: 'insurance@example.com', password: 'password');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('SAFETY DESK'), findsOneWidget);
      expect(find.byType(PortalPageHeader), findsOneWidget);
      expect(find.text('Marketplace'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
