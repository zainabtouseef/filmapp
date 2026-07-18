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
      if (role.isPrimary) return role;
    }
    return roles.isEmpty ? null : roles.first;
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final roles = (json['roles'] as List<dynamic>? ?? [])
        .map((item) => AuthRole.fromJson(item as Map<String, dynamic>))
        .toList();
    return AuthUser(
      publicId: json['public_id'] as String,
      email: json['email'] as String,
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
