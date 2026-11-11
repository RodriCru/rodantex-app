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
- **Repositorio git:** rama `main`, remoto `origin`; commits presentes (revisado 2026-11-09).
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
│   │   ├── router.dart      # go_router: guardas de sesión + StatefulShellRoute (pestañas)
│   │   ├── app_shell.dart   # AppShell: barra inferior + AppRouterTabs (Inicio/Vehículos/Rutas/Más)
│   │   ├── coming_soon_page.dart  # Placeholder de módulos pendientes
│   │   ├── routes.dart      # AppRoutes (paths/helpers) y RouteNames
│   │   └── auth_scope.dart  # InheritedWidget: AuthController + ApiClient + dashboardRepository()
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
│   │   ├── dashboard/        # Pantalla de inicio: models, repository, controller, UI y gráfica
│   │   └── depot/data/models/depot.dart  # En progreso (el dev lo empezó)
├── assets/
│   ├── fonts/               # Manrope-Variable.ttf + OFL-Manrope.txt (licencia)
│   └── images/              # logo-rodantex.svg, logo-rodantex-side-bar.svg
├── test/
│   ├── auth_test.dart       # login, refresh automático concurrente, logout
│   ├── auth_models_test.dart
│   ├── login_page_test.dart
│   ├── api_envelope_test.dart
│   ├── dashboard_models_test.dart  # repository (adaptador falso), modelos, MoneyFormatter
│   └── dashboard_page_test.dart    # render, error por bloque, rol sin acceso, responsive, gráfica
├── ios/ android/ macos/ linux/ windows/ web/   # Proyectos nativos generados
├── .github/
│   └── modernize/java-upgrade/   # Hooks/scripts para migración de Java (Gradle)
├── paleta-saas.html         # Guía de diseño / design tokens (fuente de verdad de la paleta)
├── docs/
│   └── CONTRATO_API_UI.md   # Contrato de integración API → UI (incluye §1.1 estructura de carpetas)
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
  con sesión → `/home/dashboard`. `/home` es la raíz del `StatefulShellRoute.indexedStack` (pestañas
  con estado propio). `AppRoutes`/`RouteNames` centralizan paths y helpers
  (`AppRoutes.vehicleDetail(id)`). Añadir pestañas en `AppRouterTabs.all` + una rama en el shell.
  `AuthScope.dashboardRepository(context)` da el repository conectado al `ApiClient`.
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
- Pantallas: Login (validación, error del servidor, logo SVG) y **Dashboard de inicio**
  (`features/dashboard`, ver §7.2.6 del contrato): KPIs, gráfica de gasto (CustomPainter, sin deps),
  estado de la flota, vehículos en taller y personal; carga en paralelo con estado/error por bloque,
  pull-to-refresh y menú de sesión. Vehículos/Rutas/Más son `ComingSoonPage`.
- `test/`: login/router, refresh automático, logout, `PageResponse`, `ApiException`, modelos y rutas.
- Nombre visible de la app: **Rodantex** (Android `android:label`, iOS `CFBundleDisplayName`).
  Bundle/application ID siguen en `com.example.*`.

## 4. Entorno de desarrollo (resumen del README)

- **API local:** base `http://localhost:8080/api/v1/`. Ejecutar con
  `flutter run --dart-define=API_BASE_URL=192.168.x.x` en dispositivo físico
  (en emulador Android usar `10.0.2.2`). La API desplegada se pasa con el mismo define.
- **API producción:** `https://api-prod.rodantex.com`; ejecutar con
  `flutter run --dart-define=API_BASE_URL=https://api-prod.rodantex.com`.
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
- El usuario prefiere omitir tests salvo que los solicite; se puede ejecutar `flutter analyze` al implementar código.
- Hacer todo con las mejores prácticas.
- Crear commits solo cuando el usuario lo pida explícitamente; entonces agrupar por funcionalidad.
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
| 2026-11-06 | Sesión 7. El dev señaló que `docs/CONTRATO_API_UI.md` no indicaba dónde crear cada archivo. Se añadió §1.1 **Estructura de carpetas obligatoria** (feature → `data/models`, `data/<feature>_repository.dart`, `domain/` opcional, `presentation/<feature>_controller.dart` + páginas/widgets) con reglas e inyección (`ApiClient` → repository → controller). Se actualizaron §2.3, §2.4, §2.5, §3 (plantilla ahora exige rutas exactas), §7 y §8. |
| 2026-11-06 | Sesión 8. El dev pidió ser **explícito** sobre §2.1 (endpoint) y §2.2 (JSON real): no sabía si eran archivos. Se aclaró en §2 que son **DATOS de entrada** (van en la petición de pantalla/issue/chat, **no** se crean archivos; opcionalmente el JSON como fixture en `test/fixtures/`), mientras 2.3–2.5 son **CÓDIGO** con rutas fijas. §3 marcada como DATO/CÓDIGO y notas en 2.1, 2.2, 2.4, 2.5 y §7. |
| 2026-11-06 | Sesión 9. El dev pidió **comentarios** en los ejemplos de código del contrato. Se comentaron completos `Vehicle`/`VehicleStatus` (§2.3), `VehicleRepository` (§2.4, con `TODO` en `getById`) y `VehiclesController` (§2.5, implementado con try/catch de `ApiException` y los 4 estados). Se añadió la regla **"Comentarios obligatorios"** a la tabla de §1.1 (`///` en clases/métodos públicos y el *por qué* de lo no obvio). |
| 2026-11-06 | Sesión 10. **Contrato del backend confirmado por el dev:** todos los endpoints responden envueltos `{codigo, mensaje, resultado}` **excepto `api/v1/auth/*`** (formato plano actual); `codigo` es el código HTTP. Documentado en §1.2 (nueva) y actualizadas §6 reglas 7–8. §2.4 aclarado: el ejemplo de Vehículos es solo GET; añadida tabla GET/POST/PUT/DELETE y ejemplo CRUD comentado. Nueva §7.2 ejemplo completo **Dashboard `GET dashboard/vehicles-in-maintenance?limit&depotId`**: modelos `VehicleInMaintenance` + `PagedBlock<T>`, `DashboardRepository`, `MaintenanceWidgetController`, UI y pendientes. **Pendiente de código:** `ApiClient.unwrap()` y añadir `mensaje` a `ApiException._readMessage`. |
| 2026-11-06 | Sesión 11. Implementado el soporte de la envoltura: `ApiClient.unwrap()` y `ApiClient.unwrapList()` (devuelven `resultado`, aceptan respuestas planas de auth, lanzan `ApiException` si `resultado` es null/no-objeto en `unwrap`); `ApiException` ahora lee `mensaje` (prioritario) y acepta `codigo` numérico como `code`. Tests nuevos en `test/api_envelope_test.dart` (11 casos). `flutter analyze` sin issues y `flutter test` 28 OK. Contrato §1.2 y §7.2.7 actualizados (ya no hay pendiente). |
| 2026-11-07 | Sesión 12. **Dashboard de inicio** implementado. Endpoints `dashboard/summary`, `dashboard/spending` y `dashboard/vehicles-in-maintenance` (contrato §7.2). Modelos tolerantes a `null` (`Summary`, `FleetSummary`, `SpendingSummary`, `StaffSummary`, `SpendingHistory`, `MonthlySpending`, `VehicleInMaintenance`, `PagedBlock<T>`), `DashboardRepository` (traduce `DioException` → `ApiException`), `DashboardController` (carga en paralelo, `LoadStatus` por bloque, `depotId` preparado sin selector), UI responsiva 1–3 columnas con `MoneyFormatter` propio. Navegación: `StatefulShellRoute` + `AppShell` con barra inferior (Inicio, Vehículos, Rutas, Más); se eliminó `features/home`. `AuthScope` ahora expone `apiClient`. `AuthController.restore()` acepta cualquier `TokenStorage`. Tests: 43 OK, `flutter analyze` limpio. |
| 2026-11-09 | Sesión 13. Se leyó `openapi.json` y se conectó la pestaña Vehículos: `GET vehicles` con búsqueda, paginación 1-based y exclusión de eliminados (`isDeleted=false`), DTO `GetVehicleDto` y enum de estados; se añadió detalle mediante `GET vehicles/{id}`. Lista y detalle usan el `ApiClient` compartido. Swagger no documenta filtro por estado ni formularios de alta/edición. |
| 2026-11-09 | Sesión 14. Integrados los tres endpoints `GET/POST/PATCH vehicles/{vehicleId}/maintenance`: consulta, registro y edición de datos de verificación, seguro, póliza, odómetro e intervalo. Se muestra el bloque en el detalle del vehículo; un 404 de GET se interpreta como registro aún inexistente. Se agregó soporte HTTP PATCH a `ApiClient`. Tests omitidos por preferencia explícita del dev. |
| 2026-11-09 | Sesión 15. Ajustado GET de mantenimiento para aceptar `{codigo: 200, mensaje: ..., resultado: null}` como ausencia normal de registro (sin pasar por `unwrap`); arreglados callbacks `setState` que retornaban Future. Añadido `GET suppliers` filtrado por `supplierType=INSURANCE` e `isDeleted=false`, con selector de aseguradora en alta/edición. |
| 2026-11-09 | Sesión 16. Preferencia de UI: las etiquetas verdes de formularios deben ir en negritas y todos los campos de fecha deben abrir un calendario. Aplicado al formulario de mantenimiento para verificación, seguro y placas; el payload conserva `yyyy-MM-dd`. |
| 2026-11-09 | Sesión 17. Implementado módulo de servicios de mantenimiento: listado, búsqueda y paginación; alta, detalle, edición y eliminación con `/maintenances`, `/maintenances/{id}` y catálogos de vehículos/proveedores. Formulario usa calendario para fecha de servicio. En esa sesión quedó pendiente la carga de factura (`PATCH /maintenances/{id}/invoice`, multipart `invoice`); `file_picker` se añadió en la sesión 18 para inspecciones y puede reutilizarse. Tests omitidos por preferencia del dev. |
| 2026-11-09 | Sesión 18. Implementado módulo de inspecciones: historial paginado por vehículo, alta con captura de tres lecturas y estado por llanta, detalle, edición, eliminación, carga multipart de evidencia y configuración/restablecimiento de reglas por tipo de vehículo. Se añadió `file_picker ^13.3.2`. `flutter analyze` limpio; tests omitidos por preferencia del dev. |
| 2026-11-09 | Sesión 19. Implementados `GET/PATCH users/me` con pantalla Mi perfil, edición de nombre/correo y cambio opcional de contraseña con contraseña actual. El perfil devuelto se actualiza en `AuthController` y almacenamiento seguro. README documenta `https://api-prod.rodantex.com` mediante `API_BASE_URL` y el host local. `flutter analyze` limpio; tests omitidos. |
| 2026-11-10 | Sesión 20. Implementado el módulo de consulta de rutas y viajes desde el `openapi.json`: `GET routes`, `GET routes/{id}`, `GET trips`, `GET trips/{id}` y `PATCH trips/{id}/status`. La pestaña Rutas dejó de ser provisional y ahora muestra rutas, viajes del usuario y cambios de estado; no incluye creación, edición ni monitoreo de ubicación. |
| 2026-11-10 | Sesión 21. Unificada la presentación de formularios: etiquetas bold con texto de alto contraste y estado enfocado teal, padding de campos y márgenes de diálogo aptos para móviles. Los diálogos de perfil, vehículo, mantenimiento e inspección ahora permiten desplazamiento en pantallas bajas. Se reorganizaron las acciones del diálogo de órdenes para que se adapten al ancho disponible. |
| 2026-11-10 | Sesión 22. Simplificado Dashboard: se retiraron KPIs de gastos (llantas y mantenimiento), personal, total de vehículos, gráfica mensual y bloque de personal. Se conservan estado de flota y vehículos en taller, con layout adaptable de una o dos columnas. El controlador ya no solicita el endpoint de gasto mensual. |
| 2026-11-10 | Sesión 23. El formulario de inspección ahora obtiene reglas por `carType` con `GET tire-inspection-rules`, calcula la profundidad promedio de las tres mediciones y deriva el estado automáticamente. Ya no permite elegir manualmente el resultado; requiere las tres lecturas para cada llanta seleccionada y organiza los campos en una columna en móvil o tres columnas en pantallas amplias. `INSPECTION_IMPOSSIBLE` queda fuera de la clasificación numérica. |
| 2026-11-11 | Implementada la sección de gastos dentro del detalle de viaje: listado, alta, edición y eliminación lógica mediante `GET/POST /trips/{tripId}/expenses`, `PUT/DELETE /trips/expenses/{expenseId}`. Incluye tipos del contrato, validación de litros para combustible y fecha con calendario/hora. Los KPIs no se implementaron. `flutter analyze` sin errores; solo conserva infos de estilo. |
| 2026-11-11 | Aplicada la matriz de permisos de gastos en la UI: `MECHANIC` no ve la sección; `DRIVER` puede consultar y registrar, pero no editar/eliminar; `SUPERADMIN`, `OWNER`, `MANAGER` y `ACCOUNTANT` pueden administrar. El backend continúa siendo la autoridad para restringir los viajes propios del chofer. |
| 2026-11-11 | Ampliados los controles de rol en navegación y acciones: `ACCOUNTANT` no accede a vehículos ni inspecciones; `MECHANIC` no accede a rutas/viajes; `DRIVER` ve vehículos y mantenimientos/inspecciones en modo consulta, sin acciones de edición/alta/baja; el resto conserva administración. Guardas directas de rutas añadidas. |
| 2026-11-11 | Iniciada la implementación de monitoreo: modelos y repository para ubicaciones/vehículos monitoreados, tracking del `DRIVER` durante `IN_PROGRESS` cada 5 minutos, background location, cola local con `shared_preferences`, permisos Android/iOS y pantalla de monitoreo con `flutter_map`/OpenStreetMap. `flutter analyze` sin errores; falta validación en dispositivos físicos y ajustar respuestas reales si difieren del contrato. |

## 7. Pendientes / próximos pasos

- [x] Contexto de dominio: plataforma de gestión de flotillas (vehículos, rutas, mantenimiento, documentos).
- [x] Implementar design tokens de la paleta como tema de Flutter (light y dark).
- [x] Empaquetar la fuente Manrope y los logos SVG como assets en `pubspec.yaml`.
- [x] Configurar nombre visible de la app ("Rodantex").
- [x] Login + refresh automático + logout conectados a la API.
- [x] Bases reutilizables: go_router con guardas, `ApiException`, `PageResponse<T>`.
- [x] Soporte de la envoltura `{codigo, mensaje, resultado}`: `ApiClient.unwrap`/`unwrapList` y `ApiException` lee `mensaje`.
- [x] MVP: pantalla Dashboard (inicio) con datos reales de la API.
- [ ] Selector de depósito en el dashboard (requiere endpoint de depósitos; `depotId` ya viaja en el repository).
- [x] Lista de vehículos con búsqueda y paginación conectadas a la API (`GET vehicles`).
- [x] Pantalla de detalle de vehículo (`GET vehicles/{id}`) y ruta bajo la pestaña Vehículos.
- [ ] Formularios para crear/editar vehículos (multipart/form-data) y operaciones de baja.
- [x] Consultar, registrar y editar los datos de mantenimiento de un vehículo.
- [x] Seleccionar aseguradora desde proveedores activos tipo `INSURANCE`.
- [x] Historial, registro, detalle, edición y eliminación de inspecciones de llantas.
- [x] Cargar evidencia de inspección con multipart y configurar reglas de profundidad por tipo de vehículo.
- [ ] Revisar filtros por estado: Swagger solo documenta búsqueda, `isDeleted`, paginación y ordenamiento en el listado.
- [ ] Sustituir `ComingSoonPage` de Rutas por el módulo real.
- [ ] Añadir carga de factura usando `file_picker` (`PATCH maintenances/{id}/invoice`, multipart `invoice`).
- [ ] Terminar `features/depot/data/models/depot.dart` (el dev lo empezó).
- [x] Reemplazar la Home provisional por el shell con dashboard.
- [ ] Validar paginación real de la API (`content`/`items` y nombres de metadata).
- [ ] Decidir/consolidar gestor de estado (hoy `ChangeNotifier` + `ListenableBuilder`).
- [x] Documentar backend remoto `https://api-prod.rodantex.com` y configuración con `API_BASE_URL`.
- [ ] Guardas de ruta por rol (el dashboard oculta gastos por rol, pero no hay deep links protegidos).
- [ ] Definir bundle/application ID definitivo (hoy `com.example.rodantexApp` / `com.example.rodantex_app`).
- [ ] Revisar uso de `ThemeMode.system`: hoy la status bar se fuerza a iconos oscuros (ajustar si se prioriza modo oscuro).
