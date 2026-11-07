/// Roles de usuario que define el backend.
///
/// El rol determina qué pantallas y opciones ve cada usuario. Cualquier valor
/// desconocido se trata como [unknown] para fallar de forma segura.
enum UserRole {
  superAdmin('SUPERADMIN'),
  owner('OWNER'),
  manager('MANAGER'),
  driver('DRIVER'),
  mechanic('MECHANIC'),
  accountant('ACCOUNTANT'),
  unknown('UNKNOWN');

  const UserRole(this.apiValue);

  /// Valor tal como lo envía la API.
  final String apiValue;

  static UserRole fromApi(String? value) {
    final normalized = value?.trim().toUpperCase();
    return UserRole.values.firstWhere(
      (role) => role.apiValue == normalized,
      orElse: () => UserRole.unknown,
    );
  }

  /// Nombre legible para mostrar en la UI.
  String get label => switch (this) {
    UserRole.superAdmin => 'Superadmin',
    UserRole.owner => 'Propietario',
    UserRole.manager => 'Gerente',
    UserRole.driver => 'Chofer',
    UserRole.mechanic => 'Mecánico',
    UserRole.accountant => 'Contabilidad',
    UserRole.unknown => 'Sin rol',
  };
}
