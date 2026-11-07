import 'package:rodantex_app/core/auth/user_role.dart';

/// Datos del usuario autenticado devueltos por el login.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.role,
    required this.tenant,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: (json['name'] as String?)?.trim() ?? '',
      role: UserRole.fromApi(json['role'] as String?),
      tenant: (json['tenant'] as String?)?.trim() ?? '',
    );
  }

  final String name;
  final UserRole role;
  final String tenant;
}

/// Par de tokens devuelto por login y refresh.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }

  final String accessToken;
  final String refreshToken;

  bool get isValid => accessToken.isNotEmpty && refreshToken.isNotEmpty;
}

/// Sesión completa: usuario + tokens.
class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  final UserProfile user;
  final AuthTokens tokens;
}
