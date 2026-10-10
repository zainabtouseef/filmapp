import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cineconnect/core/auth/auth_controller.dart';
import 'package:cineconnect/core/auth/auth_repository.dart';
import 'package:cineconnect/core/auth/token_store.dart';
import 'package:cineconnect/core/core_ui/screens/auth_screens.dart';
import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';

class _RecoveryTokenStore extends TokenStore {
  @override
  Future<void> clear() async {}
}

void main() {
  for (final succeeds in [true, false]) {
    testWidgets(
        'recovery only confirms success after backend accepts token: $succeeds',
        (tester) async {
      var calls = 0;
      final client = ApiClient(
          httpClient: MockClient((request) async {
            expect(request.url.path, '/api/v1/auth/password/reset');
            expect(
                jsonDecode(request.body)['token'], 'opaque-local-test-token');
            calls++;
            return http.Response(
                jsonEncode(succeeds
                    ? {
                        'data': {'reset': true}
                      }
                    : {
                        'error': {
                          'code': 'auth.invalid_reset_token',
                          'message': 'Reset link is invalid or expired.'
                        }
                      }),
                succeeds ? 200 : 401,
                headers: {'content-type': 'application/json'});
          }),
          baseUrl: 'https://qa.example.com/api/v1');
      final auth = AuthController(
          repository: AuthRepository(client),
          client: client,
          tokenStore: _RecoveryTokenStore());
      await tester.pumpWidget(ThemeControllerProvider(
          controller: ThemeController(),
          child: AuthScope(
              controller: auth,
              child: const MaterialApp(
                home:
                    ForgotPasswordScreen(resetToken: 'opaque-local-test-token'),
              ))));
      await tester.enterText(find.byType(TextField).at(0), 'StrongPass2026!');
      await tester.enterText(find.byType(TextField).at(1), 'StrongPass2026!');
      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(calls, 1);
      expect(find.text('Password updated successfully'),
          succeeds ? findsOneWidget : findsNothing);
      if (!succeeds) {
        expect(find.text('Reset link is invalid or expired.'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
