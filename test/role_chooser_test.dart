import 'dart:convert';

import 'package:cineconnect/core/auth/auth_controller.dart';
import 'package:cineconnect/core/auth/auth_repository.dart';
import 'package:cineconnect/core/auth/role_mapper.dart';
import 'package:cineconnect/core/auth/token_store.dart';
import 'package:cineconnect/core/core_ui/screens/profile_role_switcher_screen.dart';
import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryTokens extends TokenStore {
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<String?> readRefreshToken() async => null;
  @override
  Future<void> save(
      {required String accessToken, required String refreshToken}) async {}
  @override
  Future<void> clear() async {}
}

Map<String, dynamic> _user(String primary) => {
      'public_id': 'USR-test',
      'email': '',
      'display_name': 'Faizan Khwaja',
      'status': 'active',
      'roles': [
        for (final code in ['actor_talent', 'director_producer'])
          {
            'code': code,
            'name': code == 'actor_talent'
                ? 'Actor / Talent'
                : 'Director / Producer',
            'portal_route': '/test',
            'requires_kyc': true,
            'is_primary': code == primary,
            'status': 'active',
          },
      ],
    };

http.Response _ok(Object data) => http.Response(jsonEncode({'data': data}), 200,
    headers: {'content-type': 'application/json'});

void main() {
  testWidgets('multi-role login opens chooser, then the selected normal portal',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = ApiClient(httpClient: MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/auth/login')) {
        return _ok({
          'user': _user('actor_talent'),
          'tokens': {
            'access_token': 'access',
            'refresh_token': 'refresh',
            'token_type': 'Bearer',
            'expires_in': 900,
          }
        });
      }
      if (path.endsWith('/me/role-covers')) return _ok({'covers': {}});
      if (path.endsWith('/me/kyc')) return _ok({'submissions': []});
      if (path.endsWith('/professional-profiles/director_producer')) {
        return _ok({
          'fields': {'focus': 'Director'}
        });
      }
      if (path.endsWith('/me/primary-role')) {
        return _ok(_user('director_producer'));
      }
      return _ok([]);
    }));
    final auth = AuthController(
      repository: AuthRepository(client),
      client: client,
      tokenStore: _MemoryTokens(),
    );
    addTearDown(auth.dispose);
    await auth.initialize();
    await auth.login(email: 'faizan', password: 'test-password');
    expect(auth.initialAuthenticatedRoute, '/profile/roles');

    await tester.pumpWidget(AuthScope(
        controller: auth,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProfileRoleSwitcherScreen(),
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(body: Text('Portal ${settings.name}')),
          ),
        )));
    await tester.pumpAndSettle();
    expect(find.text('Who is working today?'), findsOneWidget);
    expect(find.text('Actor'), findsOneWidget);
    expect(find.text('Director'), findsOneWidget);
    expect(find.text('Manage roles'), findsOneWidget);
    await tester.tap(find.text('Manage roles'));
    await tester.pumpAndSettle();
    expect(find.text('Add a role'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Director'));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Portal ${RoleMapper.portalRouteForCode('director_producer')}'),
        findsOneWidget);
  });
}
