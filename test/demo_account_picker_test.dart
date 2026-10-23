import 'dart:convert';

import 'package:cineconnect/core/auth/auth_controller.dart';
import 'package:cineconnect/core/auth/auth_repository.dart';
import 'package:cineconnect/core/auth/token_store.dart';
import 'package:cineconnect/core/core_ui/core_routes.dart';
import 'package:cineconnect/core/core_ui/screens/demo_account_picker_screen.dart';
import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryTokens extends TokenStore {
  String? access;
  String? refresh;
  @override
  Future<String?> readAccessToken() async => access;
  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<void> save(
      {required String accessToken, required String refreshToken}) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

Map<String, Object> _account(String id, String name, {bool enabled = true}) => {
      'public_id': id,
      'display_name': name,
      'email': '$id@example.com',
      'status': enabled ? 'active' : 'suspended',
      'can_login': enabled,
    };

final _directory = {
  'total_accounts': 3,
  'categories': [
    {
      'code': 'director_producer',
      'name': 'Director / Producer',
      'accounts': [
        _account('director', 'Alex Director'),
      ]
    },
    {
      'code': 'actor_talent',
      'name': 'Actor / Talent',
      'accounts': [
        _account('actor', 'Sam Actor'),
        _account('paused', 'Paused Actor', enabled: false),
      ]
    },
  ],
};

Map<String, Object> _session(String id, String role) => {
      'user': {
        'public_id': id,
        'display_name': id,
        'email': '$id@example.com',
        'status': 'active',
        'roles': [
          {
            'code': role,
            'name': role,
            'portal_route': '/console',
            'is_primary': true
          },
        ]
      },
      'tokens': {
        'access_token': 'access-$id',
        'refresh_token': 'refresh-$id',
        'token_type': 'Bearer',
        'expires_in': 900
      },
    };

http.Response _ok(Object data) => http.Response(jsonEncode({'data': data}), 200,
    headers: {'content-type': 'application/json'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AuthController> mount(
    WidgetTester tester, {
    String key = 'private-demo-link',
    Future<http.Response> Function(http.Request)? handler,
    Size size = const Size(1280, 1000),
    bool light = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = ApiClient(
        httpClient: MockClient(handler ?? (request) async => _ok(_directory)));
    final auth = AuthController(
        repository: AuthRepository(client),
        client: client,
        tokenStore: _MemoryTokens());
    addTearDown(auth.dispose);
    await auth.initialize();
    await tester.pumpWidget(AuthScope(
        controller: auth,
        child: MaterialApp(
          theme: light ? AppTheme.light : AppTheme.dark,
          home: DemoAccountPickerScreen(accessKey: key),
          routes: {
            '/console': (_) => const Scaffold(body: Text('Director workspace'))
          },
        )));
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('private route reads its key without mounting normal login',
      (tester) async {
    final route = CoreRoutes.onGenerateRoute(
        const RouteSettings(name: '/demo-access?key=abc123'));
    final page = (route as MaterialPageRoute<void>).builder;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      final screen = page(context) as DemoAccountPickerScreen;
      expect(screen.accessKey, 'abc123');
      return const SizedBox();
    })));
  });

  testWidgets('missing key keeps account directory private', (tester) async {
    var requests = 0;
    await mount(tester, key: '', handler: (request) async {
      requests++;
      return _ok(_directory);
    });
    expect(requests, 0);
    expect(find.text('Open your demo access link to choose an account.'),
        findsOneWidget);
    expect(find.text('Alex Director'), findsNothing);
  });

  testWidgets(
      'categories, search, and unavailable accounts reflect backend data',
      (tester) async {
    await mount(tester);
    expect(find.text('3 accounts · 2 categories'), findsOneWidget);
    expect(find.text('Alex Director'), findsOneWidget);
    await tester.tap(find.text('Actor (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Director'), findsNothing);
    expect(find.text('Sam Actor'), findsOneWidget);
    final disabledCard =
        find.byKey(const ValueKey('account:actor_talent:paused'));
    final disabled = tester.widget<FilledButton>(
        find.descendant(of: disabledCard, matching: find.byType(FilledButton)));
    expect(disabled.onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'actor@example.com');
    await tester.pumpAndSettle();
    expect(find.text('Sam Actor'), findsOneWidget);
    expect(find.text('Paused Actor'), findsNothing);
    await tester.enterText(find.byType(TextField), 'no match');
    await tester.pumpAndSettle();
    expect(find.text('No accounts match your search.'), findsOneWidget);
  });

  for (final light in [true, false]) {
    testWidgets(
        'mobile picker opens the selected workspace (${light ? "light" : "dark"})',
        (tester) async {
      final auth = await mount(tester, size: const Size(360, 800), light: light,
          handler: (request) async {
        if (request.method == 'GET') return _ok({'submissions': []});
        expect(request.url.query, isEmpty);
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['access_key'], 'private-demo-link');
        if (request.url.path.endsWith('/demo/accounts')) return _ok(_directory);
        expect(request.url.path, endsWith('/demo/login'));
        expect(payload['user_id'], 'director');
        expect(payload['role_code'], 'director_producer');
        return _ok(_session('director', 'director_producer'));
      });
      expect(tester.takeException(), isNull);
      final button = find.descendant(
          of: find.byKey(const ValueKey('account:director_producer:director')),
          matching: find.byType(FilledButton));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Director workspace'), findsOneWidget);
      expect(auth.user?.publicId, 'director');
      expect(auth.apiClient.accessToken, 'access-director');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('failed login stays on picker with actionable error',
      (tester) async {
    await mount(tester, handler: (request) async {
      if (request.url.path.endsWith('/demo/accounts')) return _ok(_directory);
      return http.Response(
          jsonEncode({
            'error': {
              'code': 'demo.account_unavailable',
              'message': 'This account is unavailable.'
            }
          }),
          403);
    });
    await tester.tap(find.widgetWithText(FilledButton, 'Open workspace').first);
    await tester.pumpAndSettle();
    expect(find.text('This account is unavailable.'), findsOneWidget);
    expect(find.text('Choose an account'), findsOneWidget);
  });

  test('switching accounts revokes previous session and saves selected one',
      () async {
    final calls = <String>[];
    final tokens = _MemoryTokens();
    final client = ApiClient(httpClient: MockClient((request) async {
      if (request.method == 'GET') return _ok({'submissions': []});
      calls.add(request.url.path);
      if (request.url.path.endsWith('/demo/login')) {
        return _ok(_session('second', 'actor_talent'));
      }
      if (request.url.path.endsWith('/logout')) {
        expect(jsonDecode(request.body)['refresh_token'], 'refresh-first');
        return _ok({'revoked': true});
      }
      return _ok(_session('first', 'director_producer'));
    }));
    final auth = AuthController(
        repository: AuthRepository(client), client: client, tokenStore: tokens);
    await auth.initialize();
    await auth.login(email: 'first@example.com', password: 'test');
    await auth.demoLogin(
        accessKey: 'private-demo-link',
        userId: 'second',
        roleCode: 'actor_talent');
    expect(auth.user?.publicId, 'second');
    expect(tokens.refresh, 'refresh-second');
    expect(calls.map((path) => path.split('/').last),
        ['login', 'login', 'logout']);
    auth.dispose();
  });
}
