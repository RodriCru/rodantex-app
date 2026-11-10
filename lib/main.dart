import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rodantex_app/app/auth_scope.dart';
import 'package:rodantex_app/app/router.dart';
import 'package:rodantex_app/core/auth/auth_controller.dart';
import 'package:rodantex_app/core/auth/token_storage.dart';
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/theme/rodantex_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureTokenStorage();
  final client = ApiClient.create(storage: storage);
  final auth = AuthController(client: client, storage: storage);

  // Restaura la sesión guardada antes de resolver la primera ruta.
  await auth.restore();

  runApp(RodantexApp(auth: auth, apiClient: client));
}

class RodantexApp extends StatefulWidget {
  const RodantexApp({super.key, required this.auth, required this.apiClient});

  final AuthController auth;

  /// Cliente HTTP compartido por los repositories de las features.
  final ApiClient apiClient;

  @override
  State<RodantexApp> createState() => _RodantexAppState();
}

class _RodantexAppState extends State<RodantexApp> {
  late final AppRouter _appRouter = AppRouter(auth: widget.auth);

  @override
  Widget build(BuildContext context) {
    // AppBar y superficies son claras: iconos oscuros en la status bar.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return AuthScope(
      auth: widget.auth,
      apiClient: widget.apiClient,
      child: MaterialApp.router(
        title: 'Rodantex',
        debugShowCheckedModeBanner: false,
        theme: RodantexTheme.light,
        darkTheme: RodantexTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
