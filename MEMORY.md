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
│   ├── main.dart            # RodantexApp: MaterialApp con tema claro/oscuro + pantalla preview temporal
│   └── core/
│       └── theme/
│           ├── rodantex_colors.dart    # Tokens de color (paleta Fusion)
│           ├── rodantex_palette.dart   # Badges (RodantexBadgeTone) y colores de gráficas
│           └── rodantex_theme.dart     # ThemeData light/dark + ColorScheme
├── assets/
│   ├── fonts/               # Manrope-Variable.ttf + OFL-Manrope.txt (licencia)
│   └── images/              # logo-rodantex.svg, logo-rodantex-side-bar.svg
├── test/
│   └── widget_test.dart     # Smoke test de arranque de RodantexApp
├── ios/ android/ macos/ linux/ windows/ web/   # Proyectos nativos generados
├── .github/
│   └── modernize/java-upgrade/   # Hooks/scripts para migración de Java (Gradle)
├── paleta-saas.html         # Guía de diseño / design tokens (fuente de verdad de la paleta)
├── logo-rodantex.svg        # Logo oficial (sobre fondo claro)
├── logo-rodantex-side-bar.svg  # Variante para fondos oscuros / sidebar
├── analysis_options.yaml
├── pubspec.yaml / pubspec.lock
└── README.md                # Guía de entorno y ejecución (escrita en español)
```

### Código existente

- `lib/main.dart`: `RodantexApp` aplica `RodantexTheme.light`/`.dark` con `ThemeMode.system`.
  La pantalla es un *preview* temporal de la paleta hasta definir la UI real.
- `lib/core/theme/`: tema centralizado. `RodantexColors` (tokens), `RodantexBadgeTone`
  (estados operativos/alertas/documentos) y `RodantexChartColors` (series de gráficas).
- `pubspec.yaml`: registra la fuente **Manrope** (variable, marca wght) y `assets/images/`.
- Nombre visible de la app: **Rodantex** (Android `android:label`, iOS `CFBundleDisplayName`).
  Bundle/application ID siguen en `com.example.*`.

## 4. Entorno de desarrollo (resumen del README)

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

## 7. Pendientes / próximos pasos

- [x] Contexto de dominio: plataforma de gestión de flotillas (vehículos, rutas, mantenimiento, documentos).
- [x] Implementar design tokens de la paleta como tema de Flutter (light y dark).
- [x] Empaquetar la fuente Manrope y los logos SVG como assets en `pubspec.yaml`.
- [x] Configurar nombre visible de la app ("Rodantex").
- [ ] Definir pantallas y funcionalidades concretas del MVP.
- [ ] Definir la estructura de `lib/` por features (p. ej. `lib/features/vehicles/`) y el routing.
- [ ] Pantalla Dashboard con el layout del mockup (cards de resumen y badges de estado).
- [ ] Decidir gestor de estado y capa de red/API.
- [ ] Definir bundle/application ID definitivo (hoy `com.example.rodantexApp` / `com.example.rodantex_app`).
- [ ] Revisar uso de `ThemeMode.system`: hoy la status bar se fuerza a iconos oscuros (ajustar si se prioriza modo oscuro).
