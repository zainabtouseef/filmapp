import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/auth/auth_models.dart';

void main() {
  test('hasRole finds a non-primary Director / Producer role', () {
    const user = AuthUser(
      publicId: 'user-1',
      email: 'producer@example.com',
      displayName: 'Demo Producer',
      status: 'active',
      roles: [
        AuthRole(
          code: 'actor_talent',
          name: 'Actor / Talent',
          portalRoute: '/talent',
          requiresKyc: true,
          isPrimary: true,
        ),
        AuthRole(
          code: 'director_producer',
          name: 'Director / Producer',
          portalRoute: '/director',
          requiresKyc: true,
        ),
      ],
    );

    expect(user.primaryRole?.code, 'actor_talent');
    expect(user.hasRole('director_producer'), isTrue);
    expect(user.hasRole('brand_sponsor'), isFalse);
  });
}
