import 'package:flutter/material.dart';

import 'package:rodantex_app/core/auth/auth_controller.dart';
import 'package:rodantex_app/core/auth/models/auth_session.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/profile/data/profile_repository.dart';

/// Consulta y actualiza el perfil del usuario que inició sesión.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.auth, required this.repository});

  /// Sesión que conserva el perfil actualizado en memoria y almacenamiento.
  final AuthController auth;

  /// Repository conectado a `users/me`.
  final ProfileRepository repository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile> _profile = _loadProfile();

  Future<UserProfile> _loadProfile() async {
    final profile = await widget.repository.getMe();
    await widget.auth.updateProfile(profile);
    return widget.auth.user ?? profile;
  }

  Future<void> _edit(UserProfile profile) async {
    final updated = await showDialog<UserProfile>(
      context: context,
      builder: (_) =>
          _EditProfileDialog(repository: widget.repository, profile: profile),
    );
    if (updated == null || !mounted) return;
    await widget.auth.updateProfile(updated);
    if (mounted) {
      setState(() {
        _profile = Future.value(widget.auth.user ?? updated);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mi perfil'),
      actions: [
        IconButton(
          tooltip: 'Actualizar perfil',
          onPressed: () => setState(() {
            _profile = _loadProfile();
          }),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<UserProfile>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is ApiException
                        ? error.message
                        : 'No se pudo cargar el perfil.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _profile = _loadProfile();
                    }),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final profile = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: Text(
                        _initials(profile.name),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.name.isEmpty ? 'Usuario' : profile.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(profile.email),
                    const SizedBox(height: 12),
                    Chip(label: Text(profile.role.label)),
                    if (profile.tenant.isNotEmpty)
                      Text('Organización: ${profile.tenant}'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _edit(profile),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar perfil'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.repository, required this.profile});

  final ProfileRepository repository;
  final UserProfile profile;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _email = TextEditingController(text: widget.profile.email);
  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final password = _password.text;
    final data = <String, dynamic>{
      'fullName': _name.text.trim(),
      'email': _email.text.trim(),
      if (password.isNotEmpty) 'password': password,
      if (password.isNotEmpty) 'currentPassword': _currentPassword.text,
    };
    try {
      final profile = await widget.repository.updateMe(data);
      if (mounted) Navigator.of(context).pop(profile);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Object {
      if (mounted) setState(() => _error = 'No se pudo actualizar el perfil.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar perfil'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                controller: _name,
                label: 'Nombre completo',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe tu nombre'
                    : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _email,
                label: 'Correo electrónico',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  return text.contains('@') && text.contains('.')
                      ? null
                      : 'Escribe un correo válido';
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cambiar contraseña (opcional)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              _field(
                controller: _currentPassword,
                label: 'Contraseña actual',
                obscureText: true,
                validator: (value) =>
                    _password.text.isNotEmpty &&
                        (value == null || value.isEmpty)
                    ? 'Ingresa tu contraseña actual'
                    : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _password,
                label: 'Nueva contraseña',
                obscureText: true,
                validator: (value) =>
                    value != null && value.isNotEmpty && value.length < 8
                    ? 'Usa al menos 8 caracteres'
                    : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _confirmPassword,
                label: 'Confirmar nueva contraseña',
                obscureText: true,
                validator: (value) =>
                    _password.text.isNotEmpty && value != _password.text
                    ? 'Las contraseñas no coinciden'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Guardar'),
      ),
    ],
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    validator: validator,
    style: const TextStyle(fontWeight: FontWeight.w700),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
