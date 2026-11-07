import 'package:flutter/widgets.dart';

import 'package:rodantex_app/core/auth/auth_controller.dart';

/// Expone el [AuthController] a todo el árbol, incluidas las rutas de
/// go_router, sin pasar el objeto por cada widget.
class AuthScope extends InheritedWidget {
  const AuthScope({super.key, required this.auth, required super.child});

  final AuthController auth;

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope no encontrado en el árbol de widgets.');
    return scope!.auth;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) => oldWidget.auth != auth;
}
