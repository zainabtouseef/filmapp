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

  test('AuthSettings parses persisted locale and notification channels', () {
    final settings = AuthSettings.fromJson({
      'timezone': 'Asia/Karachi',
      'locale': 'ur-Latn-PK',
      'notifications': {
        'email_enabled': false,
        'sms_enabled': true,
        'push_enabled': false,
      },
    });

    expect(settings.timezone, 'Asia/Karachi');
    expect(settings.locale, 'ur-Latn-PK');
    expect(settings.emailEnabled, isFalse);
    expect(settings.smsEnabled, isTrue);
    expect(settings.pushEnabled, isFalse);
  });
}
