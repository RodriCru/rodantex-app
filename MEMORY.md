# Memoria del proyecto — rodantex_app

> Archivo de contexto persistente para retomar el trabajo. Actualizar al final de cada sesión
> relevante (fecha, decisiones, pendientes).

## 1. Resumen

- **Proyecto:** `rodantex_app`
- **Producto:** Rodantex — *Plataforma de Gestión de Flotillas*. Dominio previsto: dashboard,
  vehículos, rutas, mantenimiento y documentos (según mockup de `paleta-saas.html`).
- **Tipo:** Aplicación Flutter multiplataforma (objetivo principal: iOS y Android).
- **Estado:** Plantilla inicial de Flutter (contador de ejemplo). Aún **no** se ha implementado
  lógica de negocio ni diseño propio.
- **Repositorio git:** no inicializado en el directorio de trabajo actual.
- **Ubicación:** `/Users/luis/Documents/Cursos/rodantex_app`

## 2. Stack y configuración

| Elemento | Valor |
|----------|-------|
| Framework | Flutter (canal stable) |
| Lenguaje | Dart, `sdk: ^3.13.7` |
| Versión de la app | `1.0.0+1` |
| Lints | `flutter_lints ^6.0.0` (configurados en `analysis_options.yaml`) |
| Dependencias | `flutter`, `cupertino_icons ^1.0.8` |
| Dev deps | `flutter_test`, `flutter_lints` |
| Estado / routing / red | Sin paquetes aún (no hay provider, riverpod, bloc, dio, etc.) |

Lenguaje Dart reciente: se usa la sintaxis abreviada de enums/estáticos (p. ej.
`colorScheme: .fromSeed(...)`, `mainAxisAlignment: .center`).

## 3. Estructura actual

```
rodantex_app/
├── lib/
│   ├── main.dart            # Bootstrap: storage seguro + ApiClient + AuthController + router
│   ├── app/
│   │   ├── router.dart      # go_router con guardas de sesión + SplashPage + NotFoundPage
│   │   ├── routes.dart      # AppRoutes (paths/helpers) y RouteNames
│   │   └── auth_scope.dart  # InheritedWidget que expone AuthController a las rutas
│   ├── core/
│   │   ├── auth/
│   │   │   ├── user_role.dart        # Enum de roles (SUPERADMIN…unknown) + label
│   │   │   ├── models/auth_session.dart  # UserProfile, AuthTokens, AuthSession
│   │   │   ├── token_storage.dart    # TokenStorage (interface) + SecureTokenStorage
│   │   │   ├── auth_controller.dart  # Sesión, rol y estado (ChangeNotifier)
│   │   │   └── data/auth_api.dart    # login / refresh / logout
│   │   ├── config/api_config.dart    # URL base (--dart-define=API_BASE_URL)
│   │   ├── network/
│   │   │   ├── api_client.dart       # Dio + Bearer + refresh automático
│   │   │   ├── api_exception.dart    # ApiException.fromDio + SessionExpiredException
│   │   │   └── page_response.dart    # PageResponse<T> (content/items paginados)
│   │   └── theme/                    # colores, badges, gráficas, ThemeData
│   ├── features/
│   │   ├── auth/presentation/login_page.dart
│   │   └── home/presentation/home_page.dart  # Home provisional por rol
├── assets/
│   ├── fonts/               # Manrope-Variable.ttf + OFL-Manrope.txt (licencia)
│   └── images/              # logo-rodantex.svg, logo-rodantex-side-bar.svg
├── test/
│   ├── auth_test.dart       # login, refresh automático concurrente, logout
│   ├── auth_models_test.dart
│   └── login_page_test.dart
├── ios/ android/ macos/ linux/ windows/ web/   # Proyectos nativos generados
├── .github/
│   └── modernize/java-upgrade/   # Hooks/scripts para migración de Java (Gradle)
├── paleta-saas.html         # Guía de diseño / design tokens (fuente de verdad de la paleta)
├── docs/
│   └── CONTRATO_API_UI.md   # Contrato de integración API → UI (qué entrega el dev y qué entrego yo)
├── logo-rodantex.svg        # Logo oficial (sobre fondo claro)
├── logo-rodantex-side-bar.svg  # Variante para fondos oscuros / sidebar
├── analysis_options.yaml
├── pubspec.yaml / pubspec.lock
└── README.md                # Guía de entorno y ejecución (escrita en español)
```

### Código existente

- `lib/main.dart`: bootstrapea storage seguro, `ApiClient`, `AuthController`; restaura la sesión
  guardada y monta `MaterialApp.router` envuelto en `AuthScope`.
- `lib/app/`: `AppRouter` (go_router) con guardas: `unknown` → splash, sin sesión → `/login`,
  con sesión → `/home`. `AppRoutes`/`RouteNames` centralizan paths y helpers
  (`AppRoutes.vehicleDetail(id)`). Añadir pantallas en `AppRouter.routes`.
- `lib/core/auth/`: `AuthController` es la fuente única de verdad (usuario + rol). Los tokens se
  guardan en `flutter_secure_storage` (Keychain / Keystore).
- `lib/core/network/`:
  - `api_client.dart`: añade `Authorization: Bearer`; ante **401** renueva y reintenta una vez.
    Refresh concurrente compartido (single-flight). Si falla, limpia sesión y el router va a login.
  - `api_exception.dart`: `ApiException.fromDio` (lee `message`/`error`/`detail` del backend y traduce
    por código HTTP) con helpers `isUnauthorized`, `isForbidden`, `isNotFound`, `isServerError`.
    `SessionExpiredException`. Los controllers deben lanzar `ApiException` a la UI.
  - `page_response.dart`: `PageResponse<T>.fromJson(json, itemParser)` con `content`/`items`,
    `isEmpty`, `totalPages`, `hasNextPage`.
- Pantallas: Login (validación, error del servidor, logo SVG) y Home provisional con opciones por
  rol (los tiles aún son placeholders).
- `test/`: login/router, refresh automático, logout, `PageResponse`, `ApiException`, modelos y rutas.
- Nombre visible de la app: **Rodantex** (Android `android:label`, iOS `CFBundleDisplayName`).
  Bundle/application ID siguen en `com.example.*`.

## 4. Entorno de desarrollo (resumen del README)

- **API:** base `http://localhost:8080/api/v1/`. Ejecutar con
  `flutter run --dart-define=API_BASE_URL=192.168.x.x` en dispositivo físico
  (en emulador Android usar `10.0.2.2`). La API desplegada se pasa con el mismo define.
- HTTP local habilitado: ATS `NSAllowsLocalNetworking` en iOS y `usesCleartextTraffic` solo en
  `android/app/src/debug/AndroidManifest.xml`. Producción debe usar HTTPS.
- Endpoints: `auth/login` (`email`, `contrasena`) → `{name, role, tenant, accessToken,
  refreshToken}`; `auth/refresh` (`{refreshToken}`) → `{accessToken, refreshToken}`;
  `auth/logout` (sin body, Bearer).
- Requisitos: Flutter SDK stable, Xcode + Command Line Tools, CocoaPods, Android SDK y Java 17
  (`brew install openjdk@17`).
- Diagnóstico: `flutter doctor -v`.
- Aviso esperado y no bloqueante: `[!] Xcode - Unable to get list of installed Simulator runtimes`.
- Ejecutar: `flutter pub get` → `flutter devices` → `flutter run -d <id>`.
- Hot reload: `r` recarga, `R` reinicia, `q` salir.
- iPhone físico: activar Modo Desarrollador y configurar el Team de firma en Xcode
  (`open ios/Runner.xcworkspace`). Con Apple ID gratuito la app caduca a los 7 días.
- Android físico: activar Opciones de desarrollador + Depuración USB y aceptar el diálogo.

## 5. Convenciones acordadas

- Comunicación del repositorio y README en **español**.
- Mantener el estilo de código generado por Flutter y las reglas de `flutter_lints`.
- Usar imports `package:rodantex_app/...` en todo `lib/` (los relativos con `../` fallaron con el
  analyzer de Dart 3.13; no volver a ellos).
- Antes de entregar cambios: `flutter analyze` y `flutter test`.
- Hacer todo con las mejores prácticas.
- Commits los hace el dev manualmente (el agente no commitea).
- Respetar la paleta de colores definida en `paleta-saas.html`.
- El logo oficial es `logo-rodantex.svg`.
- Variante usable: `logo-rodantex-side-bar.svg` (para fondos oscuros / sidebar).

### 5.1 Diseño — Paleta "Fusion"

Fuente de verdad: `paleta-saas.html`. Personalidad: *Industrial · Tecnológica · Moderna · Robusta*.

| Rol | Token | HEX |
|-----|-------|-----|
| Estructura (sidebar, header, texto) | Graphite | `#17232F` (hover `#0F1922`, mid `#293B4B`) |
| Acción positiva / activo / éxito | Lime | `#B8D957` (hover `#A6C644`, light `#D4E894`, dark `#C6E86A`) |
| Info / disponible | Teal | `#2A9D8F` (hover `#21867A`, light `#5DC4B8`, dark `#0F4C5C`) |
| Advertencia / mantenimiento | Amber | `#E9A23B` (hover `#D18E2A`, light `#F2C77F`) |
| Crítico / incidente / error | Coral | `#E76F51` (hover `#D45A3D`, light `#F4A38F`) |

- **Neutros:** bg-app `#F3F5F6`, surface `#FFFFFF`, subtle `#E7EBEE`, border `#D2D8DD`;
  texto `#17232F` / `#4A5A6B` / `#8795A3`; texto sobre oscuro `#FFFFFF`, texto sobre lime `#17232F`.
- **Modo oscuro:** bg `#0F1922`, surface `#17232F`, elevado `#293B4B`, borde `#3A4D5F`,
  texto secundario `#9FB0BE`, lime `#C6E86A`, teal `#5DC4B8`, coral `#F4A38F`.
- **Badges (fondo suave + texto oscuro):**
  - En ruta/activo `#E8F2C6` / `#3D5210`
  - Disponible `#D9F2EE` / `#0F4C5C`
  - Detenido/inactivo `#E7EBEE` / `#293B4B`
  - Mantenimiento `#FBEED4` / `#7A4E0F`
  - Incidente `#FBE3DC` / `#8A2E1A`
  - Retraso/desvío `#FCE8D6` / `#8A4A12`
- **Tipografía:** Manrope (wordmark/UI). En web se carga como fuente web; en Flutter hay que
  empaquetarla como asset.
- **Accesibilidad:** badges siempre texto oscuro sobre fondo suave; botones teal/coral solo con
  texto grande o bold ≥14px.
- **Logos:** `logo-rodantex.svg` (wordmark `#264653`, descriptor teal) y
  `logo-rodantex-side-bar.svg` (isotipo y texto blancos, para sidebar). El isotipo conserva
  teal `#0F4C5C`, verde `#2A9D8F` y coral `#E76F51`. Nota: el SVG del sidebar usa `fill="#ffff"`;
  normalizar a `#FFFFFF` si se edita.

## 6. Historial de sesiones

| Fecha | Resumen |
|-------|---------|
| 2026-11-06 | Primera sesión. Se revisó el proyecto (plantilla Flutter sin cambios) y se creó este archivo de memoria. |
| 2026-11-06 | Sesión 2. El dev agregó convenciones (mejores prácticas, commits manuales, paleta y logos) y los archivos `paleta-saas.html`, `logo-rodantex.svg`, `logo-rodantex-side-bar.svg`. Se documentó la paleta y el contexto de dominio en la memoria. |
| 2026-11-06 | Sesión 3. Implementado el tema base: `lib/core/theme/` (colores, badges, gráficas, ThemeData light/dark), fuente Manrope empaquetada desde Google Fonts, logos en `assets/images/`, nombre visible "Rodantex" y preview temporal. `flutter analyze` y `flutter test` OK. |
| 2026-11-06 | Sesión 4. Implementado login contra la API: `dio` + `flutter_secure_storage` + `flutter_svg`, `ApiClient` con Bearer y refresh automático (single-flight) con cierre de sesión si falla, `AuthController` con rol, LoginPage y Home provisional por rol. Tests con adaptador falso. `analyze` y `test` OK. |
| 2026-11-06 | Sesión 5. Creado `docs/CONTRATO_API_UI.md`: qué entrega el dev (endpoint, JSON real, modelo, repository, controller con 4 estados) y qué entrego yo (UI, estados, componentes, tests). |
| 2026-11-06 | Sesión 6. Preparadas las 3 bases: `go_router` (`app/router.dart`, `routes.dart`, `auth_scope.dart`, se elimina `AuthGate`), `ApiException`/`SessionExpiredException` (`core/network/api_exception.dart`) y `PageResponse<T>` (`core/network/page_response.dart`). Refactor de `AuthApi`/`AuthController`. 17 tests OK. |

## 7. Pendientes / próximos pasos

- [x] Contexto de dominio: plataforma de gestión de flotillas (vehículos, rutas, mantenimiento, documentos).
- [x] Implementar design tokens de la paleta como tema de Flutter (light y dark).
- [x] Empaquetar la fuente Manrope y los logos SVG como assets en `pubspec.yaml`.
- [x] Configurar nombre visible de la app ("Rodantex").
- [x] Login + refresh automático + logout conectados a la API.
- [x] Bases reutilizables: go_router con guardas, `ApiException`, `PageResponse<T>`.
- [ ] MVP: definir y construir la pantalla Dashboard con el layout del mockup.
- [ ] Reemplazar los tiles placeholder de la Home por módulos reales y rutas en `AppRouter`.
- [ ] Validar que el backend usa el formato de error `{message}` (si no, ajustar `ApiException`).
- [ ] Validar paginación real de la API (`content`/`items` y nombres de metadata).
- [ ] Decidir/consolidar gestor de estado (hoy `ChangeNotifier` + `ListenableBuilder`).
- [ ] Configurar `API_BASE_URL` en el build y documentar la URL del servidor desplegado.
- [ ] Guardas de ruta por rol (hoy la Home filtra secciones, pero no hay deep links protegidos).
- [ ] Definir bundle/application ID definitivo (hoy `com.example.rodantexApp` / `com.example.rodantex_app`).
- [ ] Revisar uso de `ThemeMode.system`: hoy la status bar se fuerza a iconos oscuros (ajustar si se prioriza modo oscuro).
