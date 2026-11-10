import 'package:rodantex_app/core/auth/user_role.dart';

/// Datos del usuario autenticado devueltos por el login.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.role,
    required this.tenant,
    this.id = '',
    this.email = '',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as String?)?.trim() ?? '',
      name:
          (json['fullName'] as String?)?.trim() ??
          (json['name'] as String?)?.trim() ??
          '',
      email: (json['email'] as String?)?.trim() ?? '',
      role: UserRole.fromApi(json['role'] as String?),
      tenant: (json['tenant'] as String?)?.trim() ?? '',
    );
  }

  /// UUID del usuario autenticado cuando lo entrega el endpoint de perfil.
  final String id;

  final String name;

  /// Correo asociado a la cuenta.
  final String email;
  final UserRole role;
  final String tenant;

  /// Copia el perfil manteniendo los datos no incluidos en alguna respuesta.
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? tenant,
  }) => UserProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    role: role ?? this.role,
    tenant: tenant ?? this.tenant,
  );
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
