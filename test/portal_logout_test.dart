import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/auth/auth_controller.dart';
import 'package:cineconnect/core/auth/auth_models.dart';
import 'package:cineconnect/core/auth/auth_repository.dart';
import 'package:cineconnect/core/auth/token_store.dart';
import 'package:cineconnect/core/core_ui/core_logout.dart';
import 'package:cineconnect/core/core_ui/core_routes.dart';
import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/general_public/routes/general_public_routes.dart';
import 'package:cineconnect/features/general_public/screens/general_public_portal_screen.dart';
import 'package:cineconnect/shared/marketplace/marketplace_portal_screen.dart';
import 'package:cineconnect/shared/marketplace/marketplace_routes.dart';

class _MemoryTokenStore extends TokenStore {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }
}

class _AuthRepository extends AuthRepository {
  bool failLogout = false;
  int logoutCalls = 0;

  _AuthRepository(super.client);

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async =>
      const AuthSession(
        user: AuthUser(
          publicId: 'user-1',
          email: 'user@example.com',
          displayName: 'Portal User',
          status: 'active',
          roles: [],
        ),
        tokens: AuthTokens(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          expiresIn: 3600,
          tokenType: 'Bearer',
        ),
      );

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalls++;
    expect(refreshToken, 'refresh-token');
    if (failLogout) throw StateError('Server unavailable');
  }
}

void main() {
  for (final (label, screen) in [
    (
      'public portal',
      const GeneralPublicShell(
        title: 'Public',
        currentRoute: GeneralPublicRoutes.home,
        showHeading: false,
        child: SizedBox.shrink(),
      ),
    ),
    (
      'standalone marketplace',
      const MarketplacePortalScreen(routeName: MarketplaceRoutes.profile),
    ),
  ]) {
    for (final width in [320.0, 360.0]) {
      testWidgets('$label shows logout at ${width.toInt()}px', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ThemeControllerProvider(
            controller: ThemeController(),
            child: MaterialApp(
              theme: AppTheme.light,
              home: screen,
            ),
          ),
        );
        await tester.pump();

        expect(find.byTooltip('Logout'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final failLogout in [false, true]) {
    testWidgets(
      'header logout clears the session and opens login '
      '${failLogout ? 'when revocation fails' : 'after revocation'}',
      (tester) async {
        final client = ApiClient();
        final repository = _AuthRepository(client)..failLogout = failLogout;
        final store = _MemoryTokenStore();
        final auth = AuthController(
          repository: repository,
          client: client,
          tokenStore: store,
        );
        await auth.login(email: 'user@example.com', password: 'password');

        await tester.pumpWidget(
          AuthScope(
            controller: auth,
            child: MaterialApp(
              routes: {
                CoreRoutes.login: (_) =>
                    const Scaffold(body: Text('Login screen')),
              },
              home: Builder(
                builder: (context) => Scaffold(
                  body: IconButton(
                    tooltip: 'Logout',
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () => logoutToLogin(context),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byTooltip('Logout'));
        await tester.pumpAndSettle();

        expect(find.text('Login screen'), findsOneWidget);
        expect(repository.logoutCalls, 1);
        expect(auth.isAuthenticated, isFalse);
        expect(client.accessToken, isNull);
        expect(store.accessToken, isNull);
        expect(store.refreshToken, isNull);
      },
    );
  }
}
