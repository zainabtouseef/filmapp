import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/auth/auth_controller.dart';
import 'package:cineconnect/core/auth/auth_repository.dart';
import 'package:cineconnect/core/auth/token_store.dart';
import 'package:cineconnect/core/network/api_client.dart';

class _HangingTokenStore extends TokenStore {
  const _HangingTokenStore();

  @override
  Future<String?> readAccessToken() => Completer<String?>().future;

  @override
  Future<String?> readRefreshToken() => Completer<String?>().future;
}

void main() {
  test('blocked browser storage cannot prevent auth startup from completing',
      () async {
    final client = ApiClient();
    final controller = AuthController(
      repository: AuthRepository(client),
      client: client,
      tokenStore: const _HangingTokenStore(),
      storageTimeout: const Duration(milliseconds: 10),
      sessionRefreshTimeout: const Duration(milliseconds: 10),
    );

    final firstInitialization = controller.initialize();
    final repeatedInitialization = controller.initialize();

    expect(identical(firstInitialization, repeatedInitialization), isTrue);
    await firstInitialization.timeout(const Duration(seconds: 1));
    expect(controller.ready, isTrue);
    expect(controller.isAuthenticated, isFalse);
  });
}
