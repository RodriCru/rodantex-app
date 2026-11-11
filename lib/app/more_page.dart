import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:rodantex_app/app/routes.dart';
import 'package:rodantex_app/core/auth/user_role.dart';

/// Accesos a los módulos secundarios de la aplicación.
class MorePage extends StatelessWidget {
  const MorePage({super.key, required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Más')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.build_outlined),
            title: const Text('Mantenimientos'),
            subtitle: const Text(
              'Ingresar vehículos al taller y registrar servicios',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.maintenances),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi perfil'),
            subtitle: const Text('Datos de cuenta y contraseña'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.profile),
          ),
        ),
        if (role != UserRole.accountant)
          Card(
            child: ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Inspecciones'),
              subtitle: const Text('Revisiones de llantas y evidencias'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.inspections),
            ),
          ),
      ],
    ),
  );
}
