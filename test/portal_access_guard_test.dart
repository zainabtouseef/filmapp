import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineconnect/core/auth/auth_controller.dart';
import 'package:cineconnect/core/auth/auth_models.dart';
import 'package:cineconnect/core/auth/auth_repository.dart';
import 'package:cineconnect/core/auth/portal_access_guard.dart';
import 'package:cineconnect/core/auth/token_store.dart';
import 'package:cineconnect/core/network/api_client.dart';

class _SignedOutAuth extends AuthController {
  _SignedOutAuth(ApiClient client)
      : super(
            repository: AuthRepository(client),
            client: client,
            tokenStore: const TokenStore());
  @override
  bool get ready => true;
}

class _SignedInAuth extends _SignedOutAuth {
  final AuthUser signedInUser;

  _SignedInAuth(super.client, this.signedInUser);

  @override
  AuthUser? get user => signedInUser;

  @override
  bool get isAuthenticated => true;
}

void main() {
  for (final route in [
    '/settings',
    '/contract/private-id',
    '/payment/private-id',
    '/notifications',
    '/booking/chat',
    '/project/private-id'
  ]) {
    testWidgets('anonymous direct $route is protected', (tester) async {
      final auth = _SignedOutAuth(ApiClient());
      await tester.pumpWidget(AuthScope(
        controller: auth,
        child: MaterialApp(
            home: PortalAccessGuard(
          routeName: route,
          child: const Text('Private resource'),
        )),
      ));
      expect(find.text('Private resource'), findsNothing);
      expect(find.text('Sign in to access this workspace.'), findsOneWidget);
    });
  }
  testWidgets('anonymous direct admin route never renders protected content',
      (tester) async {
    final auth = _SignedOutAuth(ApiClient());
    await tester.pumpWidget(AuthScope(
        controller: auth,
        child: const MaterialApp(
          home: PortalAccessGuard(
              routeName: '/admin/dashboard',
              child: Text('Private workspace data')),
        )));
    expect(find.text('Private workspace data'), findsNothing);
    expect(find.text('Sign in to access this workspace.'), findsOneWidget);
  });

  testWidgets('active director role can open the console route',
      (tester) async {
    final client = ApiClient();
    final auth = _SignedInAuth(
      client,
      const AuthUser(
        publicId: 'director-qa',
        email: 'director@example.com',
        displayName: 'Director QA',
        status: 'active',
        roles: [
          AuthRole(
            code: 'director_producer',
            name: 'Director / Producer',
            portalRoute: '/director',
            requiresKyc: true,
            isPrimary: true,
            status: 'active',
          ),
        ],
      ),
    );

    await tester.pumpWidget(AuthScope(
      controller: auth,
      child: const MaterialApp(
        home: PortalAccessGuard(
          routeName: '/console',
          child: Text('Director console'),
        ),
      ),
    ));

    expect(find.text('Director console'), findsOneWidget);
    expect(find.text('This workspace requires an active authorized role.'),
        findsNothing);
  });

  test('revoked roles cannot grant access or become primary', () {
    const user = AuthUser(
        publicId: 'qa',
        email: 'qa@example.com',
        displayName: 'QA',
        status: 'active',
        roles: [
          AuthRole(
              code: 'super_admin',
              name: 'Admin',
              portalRoute: '/admin',
              requiresKyc: false,
              isPrimary: true,
              status: 'revoked'),
        ]);
    expect(user.hasRole('super_admin'), isFalse);
    expect(user.primaryRole, isNull);
  });
}
