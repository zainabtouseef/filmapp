class AuthRole {
  final String code;
  final String name;
  final String portalRoute;
  final bool requiresKyc;
  final bool isPrimary;
  final String status;

  const AuthRole({
    required this.code,
    required this.name,
    required this.portalRoute,
    required this.requiresKyc,
    this.isPrimary = false,
    this.status = 'active',
  });

  factory AuthRole.fromJson(Map<String, dynamic> json) {
    return AuthRole(
      code: json['code'] as String,
      name: json['name'] as String,
      portalRoute: json['portal_route'] as String,
      requiresKyc: json['requires_kyc'] as bool? ?? true,
      isPrimary: json['is_primary'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class AuthUser {
  final String publicId;
  final String email;
  final String displayName;
  final String status;
  final List<AuthRole> roles;

  const AuthUser({
    required this.publicId,
    required this.email,
    required this.displayName,
    required this.status,
    required this.roles,
  });

  AuthRole? get primaryRole {
    for (final role in roles) {
      if (role.isPrimary && role.status == 'active') return role;
    }
    for (final role in roles) {
      if (role.status == 'active') return role;
    }
    return null;
  }

  bool hasRole(String code) =>
      roles.any((role) => role.code == code && role.status == 'active');

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final roles = (json['roles'] as List<dynamic>? ?? [])
        .map((item) => AuthRole.fromJson(item as Map<String, dynamic>))
        .toList();
    return AuthUser(
      publicId: json['public_id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String,
      status: json['status'] as String,
      roles: roles,
    );
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      tokenType: json['token_type'] as String,
    );
  }
}

class AuthSession {
  final AuthUser user;
  final AuthTokens tokens;

  const AuthSession({required this.user, required this.tokens});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthSession(
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(data['tokens'] as Map<String, dynamic>),
    );
  }
}

class AuthSettings {
  final String timezone;
  final String locale;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool pushEnabled;

  const AuthSettings({
    required this.timezone,
    required this.locale,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.pushEnabled,
  });

  factory AuthSettings.fromJson(Map<String, dynamic> json) {
    final notifications =
        json['notifications'] as Map<String, dynamic>? ?? const {};
    return AuthSettings(
      timezone: json['timezone'] as String? ?? 'Asia/Karachi',
      locale: json['locale'] as String? ?? 'en-PK',
      emailEnabled: notifications['email_enabled'] as bool? ?? true,
      smsEnabled: notifications['sms_enabled'] as bool? ?? false,
      pushEnabled: notifications['push_enabled'] as bool? ?? true,
    );
  }
}

class AuthDeviceSession {
  final String id;
  final bool isCurrent;
  final String ipAddress;
  final String userAgent;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;

  const AuthDeviceSession({
    required this.id,
    required this.isCurrent,
    required this.ipAddress,
    required this.userAgent,
    required this.createdAt,
    required this.lastUsedAt,
    required this.expiresAt,
  });

  factory AuthDeviceSession.fromJson(Map<String, dynamic> json) {
    return AuthDeviceSession(
      id: json['id'] as String? ?? '',
      isCurrent: json['is_current'] as bool? ?? false,
      ipAddress: json['ip_address'] as String? ?? 'Unknown network',
      userAgent: json['user_agent'] as String? ?? 'Unknown device',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      lastUsedAt: DateTime.tryParse(json['last_used_at'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
    );
  }

  String get deviceLabel {
    final value = userAgent.toLowerCase();
    final browser = value.contains('edg/')
        ? 'Edge'
        : value.contains('chrome/')
            ? 'Chrome'
            : value.contains('firefox/')
                ? 'Firefox'
                : value.contains('safari/')
                    ? 'Safari'
                    : 'CineConnect app';
    final platform = value.contains('android')
        ? 'Android'
        : value.contains('iphone') || value.contains('ipad')
            ? 'iOS'
            : value.contains('mac os') || value.contains('macintosh')
                ? 'macOS'
                : value.contains('windows')
                    ? 'Windows'
                    : value.contains('linux')
                        ? 'Linux'
                        : '';
    return platform.isEmpty ? browser : '$browser on $platform';
  }
}
