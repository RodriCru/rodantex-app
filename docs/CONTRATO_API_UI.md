# Guía de integración API → UI (contrato de trabajo)

> **Qué es este documento:** el acuerdo para dividir el trabajo. Tú entregas la **capa de datos**
> (endpoint, modelo, repository y provider) y yo entregas únicamente el **diseño y la UI** que
> consume esa capa. Así yo no invento campos ni rutas, y tú no dependes de mi ritmo.
>
> Aplica después de lo ya construido en `MEMORY.md` (tema, login, sesión y roles).

---

## 1. El principio: separar datos de presentación

```
┌─────────────────────────────────────────────────────────┐
│  TÚ (datos)                    │  YO (diseño/UI)        │
├────────────────────────────────┼────────────────────────┤
│ API / JSON                     │ Widgets, tema, layout  │
│ Modelo (`fromJson`)            │ Estados de pantalla    │
│ Repository / ApiClient         │ Badges de estado       │
│ Provider / Controller          │ Loaders, vacíos, errores│
│ Enum + labels                  │ Responsive, a11y       │
│ Estados: loading/error/empty   │ Animaciones            │
└────────────────────────────────┴────────────────────────┘
                    contrato = este documento
```

**Regla de oro:** si yo tengo el contrato (modelo + estados + enum), puedo construir la pantalla
completa **sin la API real**. Tú la enchufas después y la UI no cambia.

---

## 1.1 Estructura de carpetas — **dónde va cada archivo** (obligatorio)

Toda feature nueva vive en `lib/features/<feature>/` y **siempre** usa las mismas cuatro capas.
No crees carpetas nuevas ni pongas archivos sueltos: si algo no encaja abajo, avísame antes.

```
lib/
├── core/                                   # transversal, ya existe
│   ├── auth/                               # ✅ sesión y rol (existente)
│   ├── config/                             # ✅ api_config.dart (existente)
│   ├── network/                            # ✅ api_client, api_exception, page_response
│   └── theme/                              # ✅ paleta, badges, ThemeData
│
└── features/
    └── <feature>/                          # ej. vehicles, routes, maintenance, dashboard
        ├── data/                           # 🔧 TÚ (capa de datos)
        │   ├── models/
        │   │   └── <entity>.dart           # modelos + enums: Vehicle, VehicleStatus
        │   ├── <feature>_repository.dart   # clases con métodos tipados (usa ApiClient)
        │   └── <feature>_api.dart          # OPCIONAL: si hay endpoints crudos o muy variados
        │
        ├── domain/                         # 🔧 TÚ (solo si hay lógica de negocio pura)
        │   └── ...                         # reglas/cálculos sin Flutter (p. ej. costos, rangos)
        │
        └── presentation/                   # 🎨 YO (UI)
            ├── <feature>_controller.dart   # 🔧 TÚ: ChangeNotifier con los 4 estados
            ├── <feature>_page.dart         # 🎨 pantalla principal
            ├── <entity>_detail_page.dart   # 🎨 detalle (si aplica)
            └── widgets/
                └── <widget>.dart           # 🎨 tarjetas, filtros, skeleton, empty, error
```

### Reglas de esta estructura

| Regla | Detalle |
|-------|---------|
| **Un feature = una carpeta** | `vehicles`, `routes`, `maintenance`, `documents`, `dashboard`. Nada en `lib/` raíz. |
| **Capa de datos separada de UI** | `data/` nunca importa `flutter/material.dart` ni widgets. Solo `dart:` y `package:rodantex_app/core/...`. |
| **`presentation/` puede leer `data/`** | La UI importa modelos/controller, pero **nunca** llama a `ApiClient` directamente. |
| **Controller en `presentation/`** | Va aquí (es el puente entre datos y UI), como `<feature>_controller.dart`. |
| **Nombres** | Archivos `snake_case`, clases `PascalCase`. Sufijos fijos: `_repository`, `_api`, `_controller`, `_page`, `_widget`/`<widget>`. |
| **Un modelo por archivo** | Si son varios modelos de la misma entidad (Vehicle + VehicleStatus + VehicleDriver), pueden ir en un solo archivo. |
| **Imports absolutos** | Siempre `package:rodantex_app/...`; nunca relativos con `../` (el analyzer de Dart 3.13 falla). |
| **Comentarios obligatorios** | Cada clase, enum y método público lleva un `///` que explica **qué es y para qué sirve** (no "qué hace línea a línea"). Comenta el *por qué* de lo no obvio: valores de API, `null`s permitidos, fallbacks y castings. Los ejemplos de §2.3–2.5 muestran el nivel esperado. |

### Plantilla exacta: feature "Vehículos"

```
lib/features/vehicles/
├── data/
│   ├── models/vehicle.dart                  # 🔧 Vehicle + VehicleStatus
│   └── vehicle_repository.dart              # 🔧 VehicleRepository(ApiClient)
└── presentation/
    ├── vehicles_controller.dart             # 🔧 VehiclesController (4 estados)
    ├── vehicles_page.dart                   # 🎨 Lista + buscador + filtros
    ├── vehicle_detail_page.dart             # 🎨 Detalle por id
    └── widgets/
        ├── vehicle_card.dart                # 🎨
        ├── vehicle_filters.dart             # 🎨
        └── vehicle_skeleton.dart            # 🎨 Loader
```

> **Cómo conectamos los archivos:** `main.dart` crea `ApiClient` una sola vez (ya lo hace). Cada
> repository recibe ese `ApiClient` (`VehicleRepository(apiClient)`), y cada controller recibe su
> repository (`VehiclesController(VehicleRepository(apiClient))`). Yo inyecto el controller a la
> página; tú no tienes que tocar la UI para conectarla.

---

## 1.2 Formato de respuesta de la API (aplica a todo el backend)

El backend usa **dos formatos**:

| Grupo | Formato | Ejemplo |
|-------|---------|---------|
| `api/v1/auth/*` | **Plano** (sin envoltura) | `{ name, role, tenant, accessToken, refreshToken }` |
| **Resto de endpoints** | **Envuelto** | `{ codigo, mensaje, resultado }` |

```json
// Éxito (HTTP 200 / 201)
{ "codigo": 200, "mensaje": "OK", "resultado": { "total": 0, "items": [] } }

// Error del servidor (HTTP 400 / 404 / 500…)
{ "codigo": 404, "mensaje": "Vehículo no encontrado", "resultado": null }
```

Reglas:

1. **`codigo` es el código HTTP** (200, 201, 404, 401…). No inventes códigos de negocio.
2. **`resultado`** puede ser un objeto, una lista o `null` (éxito sin cuerpo, p. ej. un DELETE).
3. **Los errores HTTP no-2xx ya los traduce `ApiException`** a un mensaje en español. Lee el
   mensaje del backend desde `mensaje` (formato envuelto), luego `message`/`error`/`detail`.
4. **El repository es el único que "desempaqueta"**. La UI y el controller nunca ven
   `codigo`/`mensaje`/`resultado`: reciben modelos ya tipados o una `ApiException`.

Helpers ya disponibles en `ApiClient` (`lib/core/network/api_client.dart`):

```dart
// Si `resultado` es un objeto → Map<String, dynamic>. Lanza ApiException si es null/no-objeto.
final data = _client.unwrap(res.data);
return Model.fromJson(data);

// Si `resultado` es una lista sin paginar → List<Map<String, dynamic>> ([] si es null).
final items = _client.unwrapList(res.data);
return items.map(Model.fromJson).toList();
```

> Las respuestas **planas** (auth) también pasan por `unwrap`: si no hay clave `resultado`,
> devuelve el `Map` tal cual. Así un mismo repository sirve para ambos formatos.

---

## 2. Lo mínimo que necesito por cada pantalla

Para cada pantalla o módulo (Vehículos, Rutas, Mantenimiento, etc.) necesito **cinco cosas**.

> **¿Dónde se entregan y para qué sirve cada una?**
>
> | # | Qué | ¿Dónde va? | ¿Para qué me sirve? |
> |---|-----|-----------|---------------------|
> | 2.1 | Endpoint exacto | ❌ **No va en un archivo de la app.** Lo pones en la **petición** (la plantilla de §3) o en un issue/chat. | Saber qué path, método y parámetros llamar. Yo no lo uso en código; **tú** lo usas en el repository. |
> | 2.2 | JSON real de respuesta | ❌ **No va en la app** (solo como **fixture** de test si quieres). Lo pones en la **petición** (§3). | Saber los **nombres exactos** de los campos. Con esto escribo el `fromJson` y el fake controller. |
> | 2.3 | Modelo Dart | ✅ `lib/features/<feature>/data/models/<entity>.dart` (código) | Representa el JSON en Dart. |
> | 2.4 | Repository | ✅ `lib/features/<feature>/data/<feature>_repository.dart` (código) | Llama al endpoint 2.1 y convierte 2.2 en modelo 2.3. |
> | 2.5 | Controller | ✅ `lib/features/<feature>/presentation/<feature>_controller.dart` (código) | Expone los 4 estados a la UI. |
>
> **Resumen:** 2.1 y 2.2 son **datos de entrada** (me los pasas en la petición, NO se guardan en
> la app). 2.3, 2.4 y 2.5 son **archivos de código** que sí se crean en las rutas indicadas.
>
> **Opcional pero recomendado:** guarda el JSON de 2.2 como fixture en
> `test/fixtures/<feature>_<caso>.json` si quieres tests que validen el modelo contra el JSON real.

### 2.1 Endpoint exacto

**Qué es:** la descripción del endpoint tal como lo llama la app. **No es un archivo Dart**; es un
bloque de texto que me pasas en la petición (§3) para que yo sepa qué tiene que llamar tu
repository.

Incluye ruta relativa (se resuelve contra `api/v1/`), método, query params. El JSON de respuesta
lo documentas aparte en §2.2.

```yaml
# Ejemplo — esto se PEGA en la petición de pantalla, no se crea como archivo
pantalla: Lista de vehículos
endpoint: GET vehiculos                    # → el repository hará client.get('vehiculos', ...)
query:
  estado: string?        # "EN_RUTA" | "DISPONIBLE" | ...
  page: int?             # 0-based
  size: int?             # default 20
auth: Bearer (ya lo añade ApiClient)
respuesta: ver 2.2
```

**Qué haces tú con esto:** nada en la app todavía; esto lo usas al escribir
`VehicleRepository.list()` (§2.4). **Qué hago yo con esto:** sé que la pantalla lista paginado y
qué filtros puedo poner en la UI.

### 2.2 JSON real de respuesta

**Qué es:** el JSON tal cual lo devuelve el backend (`copy` del response en Postman/curl).
**No es un archivo de la app.** Va **pegado en la petición** (§3), en el campo "JSON de
respuesta".

**Para qué me sirve:** es lo que uso para escribir el `fromJson` de §2.3 y el fake controller de
los tests. Si este JSON no es real, la pantalla se rompe en silencio al conectar la API.

Cópialo tal cual llega, con un caso con valores reales y, si existe, el caso vacío
(`[]` o `content: []`).

```json
{
  "content": [
    {
      "id": "8f3c…",
      "placa": "ABC-123",
      "marca": "Toyota",
      "modelo": "Hilux",
      "estado": "EN_RUTA",
      "odometro": 152340,
      "conductor": { "id": "u1", "nombre": "Juan Alberto" }
    }
  ],
  "totalElements": 42,
  "page": 0,
  "size": 20
}
```

```json
{ "content": [], "totalElements": 0, "page": 0, "size": 20 }
```

> ⚠️ No pongas solo el DTO de Java si el JSON es muy distinto. Necesito el JSON **real**.

**Opcional (recomendado):** para que los tests validen el modelo contra el JSON real, guárdalo
como fixture en `test/fixtures/vehicles_list.json` y úsalo en un test del repository o del
`fromJson`. No es obligatorio; si no lo guardas, solo es referencia.

### 2.3 Modelo Dart + `fromJson`

Esto **sí es código** y se crea en
`lib/features/<feature>/data/models/<entity>.dart`. Esto lo haces tú (es donde se suele romper
la app). Ejemplo del formato que espero:

```dart
// lib/features/vehicles/data/models/vehicle.dart
//
// Traduce el JSON del backend (§2.2) a objetos Dart. Es la ÚNICA parte que "conoce"
// los nombres de los campos del JSON; el resto de la app solo ve `Vehicle`.

/// Estados posibles de un vehículo.
///
/// - `EN_RUTA` es el valor que llega de la API (lo que te doy en §2.2).
/// - `'En ruta'` es el texto que ve el usuario; se define aquí y no en el backend.
/// - `desconocido` es la red de seguridad: si la API manda un estado nuevo
///   que no conocemos, no rompe la app, solo se muestra "—".
enum VehicleStatus {
  enRuta('EN_RUTA', 'En ruta'), // valor API → texto para la UI
  disponible('DISPONIBLE', 'Disponible'),
  detenido('DETENIDO', 'Detenido'),
  mantenimiento('MANTENIMIENTO', 'Mantenimiento'),
  incidente('INCIDENTE', 'Incidente'),
  retraso('RETRASO', 'Retraso'),
  desconocido('DESCONOCIDO', '—'); // fallback obligatorio

  const VehicleStatus(this.apiValue, this.label);

  /// Valor tal cual llega de la API (p. ej. al filtrar por estado).
  final String apiValue;

  /// Texto legible para badges y listas.
  final String label;

  /// Convierte lo que llega del backend en un enum seguro.
  /// Si `v` es `null` o desconocido → `desconocido` (nunca lanza excepción).
  static VehicleStatus fromApi(String? v) => values.firstWhere(
        (e) => e.apiValue == v,
        orElse: () => desconocido,
      );
}

/// Un vehículo de la flotilla, ya validado y tipado.
/// La UI nunca ve `Map`/`json`; solo esta clase.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.status,
    required this.odometro,
    this.driverName, // opcional: puede no venir conductor asignado
  });

  /// Mapea el JSON recibido a un `Vehicle`.
  /// Aquí se "traduce" cada nombre de campo del backend (ej. `"estado"`) al campo Dart.
  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String, // obligatorio: si falta, es un error de contrato
        placa: json['placa'] as String,
        marca: json['marca'] as String,
        modelo: json['modelo'] as String,
        // El JSON trae "EN_RUTA"; el enum lo busca y se guarda tipado.
        status: VehicleStatus.fromApi(json['estado'] as String?),
        // `num` acepta 152340 o 152340.0; `.toInt()` normaliza a entero.
        odometro: (json['odometro'] as num).toInt(),
        // "conductor" puede ser null → `?[...]` evita el crash y deja null.
        driverName: (json['conductor'] as Map<String, dynamic>?)?['nombre'] as String?,
      );

  final String id;
  final String placa;
  final String marca;
  final String modelo;
  final VehicleStatus status; // ya convertido a enum, no string
  final int odometro; // kilómetros recorridos
  final String? driverName; // null si no tiene conductor
}
```

### 2.4 Repository o servicio

**Qué es:** código Dart que llama a los endpoints de §2.1 y convierte el JSON de §2.2 usando el
modelo de §2.3. **Sí es un archivo**, va en
`lib/features/<feature>/data/<feature>_repository.dart`.

Una clase con métodos tipados; **nada de `Map` suelto en la UI**.

#### ¿El ejemplo es un GET o un CRUD completo?

**El ejemplo de "Vehículos" de abajo es solo LECTURA (GET)**: `list()` y `getById()`. Es un
recorte para la primera pantalla (lista + detalle).

**Un CRUD no cambia el patrón**, solo añade métodos a la misma clase. La correspondencia es:

| Operación | Verbo | Método del repository | Endpoint típico |
|-----------|-------|----------------------|-----------------|
| Leer lista | `GET` | `list(...)` | `GET vehiculos?page=0` |
| Leer uno | `GET` | `getById(id)` | `GET vehiculos/{id}` |
| Crear | `POST` | `create(dto)` | `POST vehiculos` (devuelve el creado, 201) |
| Actualizar | `PUT` | `update(id, dto)` | `PUT vehiculos/{id}` (devuelve el actualizado) |
| Borrar | `DELETE` | `delete(id)` | `DELETE vehiculos/{id}` (sin `resultado`, 204) |

- **DTO de escritura** (`POST`/`PUT`): no uses el modelo de lectura para enviar. Crea un
  `VehicleInput` en `data/models/` con un `toJson()` que solo incluya los campos editables.
- **Solo implementa lo que la pantalla necesita.** No hagas el CRUD completo si la pantalla solo
  lista y ve detalle.
- Los cuatro métodos siguen las mismas reglas: envueltos en `{codigo, mensaje, resultado}` (§1.2),
  devolviendo modelos tipados y lanzando `ApiException` ante error.

Ejemplo completo (los métodos de escritura son referencia; adáptalos a tus endpoints reales):

```dart
// lib/features/vehicles/data/vehicle_repository.dart
//
// Puente entre la API y la app: llama a los endpoints (§2.1), recibe el JSON (§2.2)
// y lo convierte en modelos (§2.3). La UI NUNCA llama a la API directamente.
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/core/network/page_response.dart';
import 'package:rodantex_app/features/vehicles/data/models/vehicle.dart';

class VehicleRepository {
  // Recibe el ApiClient que ya crea `main.dart` (Bearer + refresh automático incluidos).
  // Así no repetimos configuración de red ni tokens en cada pantalla.
  VehicleRepository(this._client);

  final ApiClient _client;

  // ─── READ ─────────────────────────────────────────────────────────────────

  /// GET vehiculos → lista paginada, con filtro opcional por estado.
  Future<PageResponse<Vehicle>> list({VehicleStatus? status, int page = 0}) async {
    final res = await _client.get<Map<String, dynamic>>(
      'vehiculos', // ruta relativa a la base api/v1/
      query: {
        // Solo envía el filtro si existe; `if` dentro de un Map es válido en Dart.
        if (status != null) 'estado': status.apiValue,
        'page': page,
      },
    );
    // Desempaqueta la envoltura {codigo, mensaje, resultado} (§1.2) y lee del resultado:
    // `content`/`items` + metadatos. Cada elemento pasa por `Vehicle.fromJson`.
    final resultado = res.data!['resultado'] as Map<String, dynamic>;
    return PageResponse.fromJson(resultado, Vehicle.fromJson);
  }

  /// GET vehiculos/{id} → detalle de un vehículo.
  Future<Vehicle> getById(String id) async {
    final res = await _client.get<Map<String, dynamic>>('vehiculos/$id');
    return Vehicle.fromJson(_client.unwrap(res.data));
  }

  // ─── CREATE / UPDATE / DELETE (solo si la pantalla lo necesita) ───────────

  /// POST vehiculos → crea un vehículo. El backend responde 201 con el creado.
  Future<Vehicle> create(VehicleInput input) async {
    final res = await _client.post<Map<String, dynamic>>(
      'vehiculos',
      data: input.toJson(), // solo campos editables
    );
    return Vehicle.fromJson(_client.unwrap(res.data));
  }

  /// PUT vehiculos/{id} → actualiza y devuelve el vehículo actualizado.
  Future<Vehicle> update(String id, VehicleInput input) async {
    final res = await _client.put<Map<String, dynamic>>(
      'vehiculos/$id',
      data: input.toJson(),
    );
    return Vehicle.fromJson(_client.unwrap(res.data));
  }

  /// DELETE vehiculos/{id} → borra. Suele venir `resultado: null` (204/200).
  Future<void> delete(String id) async {
    await _client.delete<void>('vehiculos/$id');
    // Si el backend devuelve 200 con `{codigo: 200, mensaje: "Eliminado"}`,
    // no hay nada que parsear: basta con que no lance ApiException.
  }
}
```

### 2.5 Provider / Controller con estados explícitos

**Qué es:** código Dart que expone los datos a la pantalla y maneja cuándo está cargando, con
datos, vacía o con error. **Sí es un archivo**, va en
`lib/features/<feature>/presentation/<feature>_controller.dart`.

Yo diseño **cuatro estados** en cada pantalla: cargando, datos, vacío y error. Necesito que el
controller los exponga de forma uniforme:

```dart
// lib/features/vehicles/presentation/vehicles_controller.dart
//
// Estados que puede mostrar una pantalla:
// - idle    → aún no se ha pedido nada (pantalla recién abierta)
// - loading → esperando la API (se muestra el skeleton)
// - success → hay datos (se muestra la lista)
// - empty   → la API respondió OK pero sin datos (se muestra empty state)
// - failure → error de red/servidor (se muestra tarjeta con "Reintentar")
enum LoadStatus { idle, loading, success, empty, failure }

class VehiclesController extends ChangeNotifier {
  // Recibe el repository (que ya tiene el ApiClient). Así se puede meter un fake en tests.
  VehiclesController(this._repository);

  final VehicleRepository _repository;

  // Estado actual, leído por la página con ListenableBuilder.
  LoadStatus status = LoadStatus.idle;
  List<Vehicle> vehicles = const [];
  String? errorMessage; // solo tiene valor cuando status == failure

  /// Carga la primera página y actualiza el estado.
  /// La UI solo llama a `load()` y escucha el resultado; no maneja bools sueltos.
  Future<void> load() async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners(); // la UI pinta el skeleton

    try {
      final page = await _repository.list(page: 0);
      vehicles = page.items;
      // Distinguimos "sin datos" de "con datos": son pantallas distintas.
      status = page.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } on ApiException catch (e) {
      // Los errores de red ya vienen traducidos y con mensaje listo para mostrar.
      errorMessage = e.message;
      status = LoadStatus.failure;
    } finally {
      notifyListeners(); // la UI pinta lista/empty/error
    }
  }
}
```

> Si prefieres Riverpod/Bloc, está bien: solo indícame el tipo de `AsyncValue`/`state` y listo.
> Lo importante es que existan **los cuatro estados**, no un `bool isLoading` suelto.
> Si usas otro gestor, mantén los mismos nombres de estado (`loading`, `success`, `empty`,
> `failure`) y comenta qué representa cada uno.

---

## 3. Plantilla para pedirme una pantalla

Copia esto y rellénalo. Con esto puedo entregar la UI completa ese mismo día.

> **Dónde se rellena esta plantilla:** en un **issue, chat o comentario** (no es un archivo de la
> app). Los bloques marcados "DATO" son solo información que me pasas; los marcados "CÓDIGO" son
> los archivos que tú crearás con las rutas de §1.1.

```md
## Pantalla: <nombre>

**Rol(es) que la ven:** OWNER, MANAGER
**Desde:** menú "Vehículos" en Home
**Acciones disponibles:** ver detalle, filtrar por estado, buscar por placa

**Endpoint(s)** — DATO (no crear archivo, ver §2.1):
- GET vehiculos (lista paginada) + query estado?, page?, size?
- GET vehiculos/{id} (detalle)

**JSON real de respuesta** — DATO (no crear archivo, ver §2.2): pegar el JSON real aquí.

**Archivos de código a crear (rutas exactas, según §1.1):**
- Modelo — CÓDIGO: `lib/features/<feature>/data/models/<entity>.dart`
- Repository — CÓDIGO: `lib/features/<feature>/data/<feature>_repository.dart`
- Controller — CÓDIGO: `lib/features/<feature>/presentation/<feature>_controller.dart`
- Estados que expone el controller: loading | success | empty | failure

**Diseño de referencia:** <mockup, captura o descripción>
**Datos que deben verse en la tarjeta:** placa, marca/modelo, estado (badge), conductor, odómetro
**Acción al tocar:** abrir detalle
```

---

## 4. Lo que yo entrego a cambio

| Entrega | Detalle |
|---------|---------|
| Pantalla(s) completas | Layout responsive (móvil/tablet), con `RodantexTheme` |
| Los 4 estados | Skeleton/loader, lista, empty state ilustrado, error con reintento |
| Componentes reutilizables | `StatusBadge` (ya existen los tonos), `InfoCard`, `SectionTile`, `EmptyState` |
| Conexión al controller | Solo llamadas (`controller.load()`) y lectura de estado |
| Navegación | Ruta y paso de parámetros (`id`), con go_router |
| Pruebas de widget | Con un controller fake que devuelve cada estado |
| Registro en memoria | Qué se hizo y qué endpoint consume |

---

## 5. Cosas que asumo que ya existen

Para no reinventar, doy por hecho que tienes (y si no, lo hacemos juntos antes de la pantalla):

- [x] `ApiClient` con Bearer y refresh automático (`lib/core/network/api_client.dart`).
- [x] Sesión y rol actual (`AuthController.role`).
- [x] Tema con la paleta Fusion y `RodantexBadgeTone` para estados.
- [x] Helper de paginación común `PageResponse<T>` (`lib/core/network/page_response.dart`).
- [x] Error reutilizable `ApiException.fromDio` (`lib/core/network/api_exception.dart`).
- [x] Rutas nombradas con `go_router` (`lib/app/router.dart`, `lib/app/routes.dart`).

---

## 6. Reglas para que el contrato no se rompa

1. **Enum cerrados con valor por defecto seguro.** Siempre incluir `desconocido`/`unknown`.
2. **`null` documentado.** Dime qué campos pueden faltar y la UI mostrará `—`.
3. **Fechas en ISO-8601** (`2026-11-06T14:30:00Z`). Yo formateo a la zona local.
4. **Dinero en número + moneda separada** (`{"amount": 1500.50, "currency": "MXN"}`), no strings.
5. **Enums de estado:** los valores tal cual llegan (`EN_RUTA`), y su label se define en Dart,
   no en la API.
6. **Imágenes:** si vienen de la API, dame solo la URL; manejo caché desde UI.
7. **Paginación:** todos los endpoints van envueltos en `{codigo, mensaje, resultado}` (§1.2).
   En `resultado`, la forma exacta según el caso:
   - Listas paginadas completas: `{content, totalElements, page, size}` (o `{items, total}`).
   - Bloques de dashboard con `limit`: `{total, items}` → `PagedBlock<T>` (§7.2.3).
   Si un endpoint usa otra forma, dímela antes.
8. **Errores:** la API responde `{codigo, mensaje, resultado}` donde `codigo` es el HTTP y
   `mensaje` trae el texto. `ApiException` leerá `mensaje` (además de `message`/`error`/`detail`).
9. **Un cambio de contrato = aviso previo.** Si cambia un campo, la pantalla se rompe en silencio.

---

## 7. Ejemplo aplicado: "Vehículos"

### Lo que tú me pasas

**Código (archivos en la app):**

```
lib/features/vehicles/
├── data/
│   ├── models/vehicle.dart                       # modelo (sección 2.3)
│   └── vehicle_repository.dart                   # repository (2.4)
└── presentation/
    └── vehicles_controller.dart                  # controller (2.5)
```

**Datos (en la petición §3, no como archivos):** el endpoint `GET vehiculos` (§2.1) y su JSON real
(§2.2), con la forma `[{ id, placa, marca, modelo, estado, odometro, conductor: { id, nombre } }]`.

### Lo que yo construyo

```
lib/features/vehicles/presentation/
├── vehicles_page.dart          # Lista + buscador + filtro de estado
├── widgets/
│   ├── vehicle_card.dart       # Placa, marca/modelo, badge, conductor, odómetro
│   ├── vehicle_filters.dart    # Chips de estado
│   └── vehicle_skeleton.dart   # Loader
└── vehicle_detail_page.dart    # Detalle (recibe id)
```

- El **badge** usa el estado → `RodantexBadgeTone` (en ruta=lime, disponible=teal,
  mantenimiento=amber, incidente=coral…).
- Si `controller.status == empty` → empty state con CTA "Agregar vehículo" (si el rol lo permite).
- Si `failure` → tarjeta de error con botón "Reintentar" que llama `controller.load()`.

### Flujo de trabajo

1. Tú entregas modelo + repository + controller + JSON real.
2. Yo creo la UI con un **fake controller** (sin red) y te muestro la pantalla.
3. Tú conectas el controller real a la pantalla (una línea: pasar la instancia).
4. Ajustes visuales y pruebas.

---

## 7.2 Ejemplo aplicado: "Dashboard — vehículos en mantenimiento"

Este es el caso **real** con la envoltura de §1.2. Es un **GET de widget del dashboard**
(no un CRUD): solo lee los vehículos que llevan N días en mantenimiento.

### 7.2.1 Endpoint (DATO — va en la petición, no es archivo)

```yaml
pantalla: Dashboard → tarjeta "En mantenimiento"
endpoint: GET dashboard/vehicles-in-maintenance?limit=6&depotId=4A1B43E2-1183-4AD4-A3DE-C2DA787AE56A
query:
  limit: int?      # cuántos quiero traer (la tarjeta muestra 6)
  depotId: uuid?   # filtro por depósito; null = todos los del tenant
auth: Bearer (lo añade ApiClient)
formato: envuelto {codigo, mensaje, resultado} (§1.2)
```

**Decisión de UI:** la tarjeta del dashboard no sirve para listar cientos de registros; con
`limit=6` es suficiente. Por eso **no** uso `PageResponse`, sino un modelo de bloque
`PagedBlock<T>` = `total` + `items`.

### 7.2.2 JSON real de respuesta (DATO)

```json
{
  "codigo": 200,
  "mensaje": "OK",
  "resultado": {
    "total": 0,
    "items": [
      {
        "vehicleId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "plate": "string",
        "numberEco": "string",
        "make": "string",
        "model": "string",
        "year": "string",
        "depotId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "depotName": "string",
        "since": "2026-11-07T05:40:39.451Z",
        "daysInMaintenance": 0
      }
    ]
  }
}
```

Caso vacío:

```json
{ "codigo": 200, "mensaje": "OK", "resultado": { "total": 0, "items": [] } }
```

> Notas de campos (las que necesito confirmar contigo):
> - `year` es **string** (`"2021"`), no número. ¿Puede venir `null`?
> - `since` es ISO-8601 **UTC** (`Z`). Lo muestro en hora local.
> - `daysInMaintenance` es entero; ¿puede ser `null` si aún no se calcula?

### 7.2.3 Modelos (CÓDIGO — `lib/features/dashboard/data/models/`)

```dart
// lib/features/dashboard/data/models/vehicle_in_maintenance.dart
//
// Representa UN elemento de la tarjeta "En mantenimiento" del dashboard.
// Es un modelo de LECTURA: la UI solo lo muestra, nunca lo envía de vuelta.
class VehicleInMaintenance {
  const VehicleInMaintenance({
    required this.vehicleId,
    required this.plate,
    required this.numberEco,
    required this.make,
    required this.model,
    required this.depotId,
    required this.depotName,
    required this.since,
    required this.daysInMaintenance,
    this.year, // "string" en el JSON; null si no está capturado
  });

  /// Traduce un elemento de `resultado.items`. Los `??` evitan crashes cuando
  /// el backend manda `null` en campos secundarios.
  factory VehicleInMaintenance.fromJson(Map<String, dynamic> json) =>
      VehicleInMaintenance(
        vehicleId: json['vehicleId'] as String,
        plate: json['plate'] as String? ?? '—',
        numberEco: json['numberEco'] as String? ?? '—',
        make: json['make'] as String? ?? '—',
        model: json['model'] as String? ?? '—',
        year: json['year'] as String?,
        depotId: json['depotId'] as String,
        depotName: json['depotName'] as String? ?? '—',
        // ISO-8601 con `Z` → DateTime en UTC. OJO: `toLocal()` es para pintar.
        since: DateTime.parse(json['since'] as String).toLocal(),
        daysInMaintenance: (json['daysInMaintenance'] as num?)?.toInt() ?? 0,
      );

  final String vehicleId; // id real que se pasa a AppRoutes.vehicleDetail(id)
  final String plate; // "ABC-123"
  final String numberEco; // número económico interno
  final String make; // marca
  final String model; // modelo
  final String? year; // "2021"
  final String depotId;
  final String depotName; // "Depósito Norte"
  final DateTime since; // desde cuándo está en taller (local)
  final int daysInMaintenance; // 0..N → color del badge si > 7

  /// "Toyota Hilux 2021" para el subtítulo de la tarjeta.
  String get displayName =>
      [make, model, year].whereType<String>().where((v) => v.isNotEmpty).join(' ');
}
```

```dart
// lib/features/dashboard/data/models/paged_block.dart
//
// `resultado` de los endpoints tipo bloque: { total, items }.
// No es PageResponse porque no hay página ni tamaño fijo: solo "total y estos pocos".
// Si otro widget del dashboard devuelve otra forma (p. ej. kpis), crea su propio modelo.
class PagedBlock<T> {
  const PagedBlock({required this.total, required this.items});

  factory PagedBlock.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final raw = (json['items'] as List<dynamic>? ?? const []);
    return PagedBlock<T>(
      total: (json['total'] as num?)?.toInt() ?? raw.length,
      items: raw.whereType<Map<String, dynamic>>().map(itemParser).toList(),
    );
  }

  final int total; // total real en el backend (puede ser > items.length)
  final List<T> items; // los `limit` pedidos

  bool get isEmpty => items.isEmpty;
  bool get hasMore => total > items.length; // → pintar "Ver todas (12)"
}
```

### 7.2.4 Repository (CÓDIGO — `lib/features/dashboard/data/dashboard_repository.dart`)

```dart
// lib/features/dashboard/data/dashboard_repository.dart
//
// Endpoints del dashboard. Todos son GET y todos responden envueltos en
// {codigo, mensaje, resultado} (§1.2): este es el único lugar que lo desempaqueta.
import 'package:rodantex_app/core/network/api_client.dart';
import 'package:rodantex_app/features/dashboard/data/models/paged_block.dart';
import 'package:rodantex_app/features/dashboard/data/models/vehicle_in_maintenance.dart';

class DashboardRepository {
  // Se reutiliza el ApiClient de main.dart (Bearer + refresh automático).
  DashboardRepository(this._client);

  final ApiClient _client;

  /// GET dashboard/vehicles-in-maintenance?limit=6&depotId=...
  /// - `limit`: cuántos traer (la tarjeta usa 6).
  /// - `depotId`: filtro por depósito; si es null se omiten los del tenant.
  Future<PagedBlock<VehicleInMaintenance>> vehiclesInMaintenance({
    String? depotId,
    int limit = 6,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      'dashboard/vehicles-in-maintenance', // relativo a api/v1/
      query: {
        'limit': limit,
        // Si no hay depósito seleccionado, no mandamos el query param vacío.
        if (depotId != null) 'depotId': depotId,
      },
    );
    // 1) quita la envoltura → { total, items }
    // 2) PagedBlock lee total/items y aplica VehicleInMaintenance.fromJson a cada uno
    return PagedBlock.fromJson(_client.unwrap(res.data), VehicleInMaintenance.fromJson);
  }
}
```

### 7.2.5 Controller (CÓDIGO — `lib/features/dashboard/presentation/dashboard_controller.dart`)

```dart
// lib/features/dashboard/presentation/dashboard_controller.dart
//
// Estado de la sección "En mantenimiento" del dashboard.
// Reutiliza el mismo enum de 4 estados que el resto de la app (§2.5).
import 'package:flutter/foundation.dart';

import 'package:rodantex_app/core/network/api_exception.dart';
import 'package:rodantex_app/features/dashboard/data/dashboard_repository.dart';
import 'package:rodantex_app/features/dashboard/data/models/vehicle_in_maintenance.dart';

enum LoadStatus { idle, loading, success, empty, failure }

class MaintenanceWidgetController extends ChangeNotifier {
  // El repository llega por constructor: en tests se pasa un fake sin red.
  MaintenanceWidgetController(this._repository);

  final DashboardRepository _repository;

  LoadStatus status = LoadStatus.idle;
  List<VehicleInMaintenance> items = const [];
  int total = 0; // para el "Ver todas (12)"
  String? errorMessage;

  bool get hasMore => total > items.length;

  /// Carga la tarjeta. `depotId` viene del filtro global del dashboard.
  Future<void> load({String? depotId, int limit = 6}) async {
    status = LoadStatus.loading;
    errorMessage = null;
    notifyListeners(); // pinta skeleton

    try {
      final block = await _repository.vehiclesInMaintenance(
        depotId: depotId,
        limit: limit,
      );
      items = block.items;
      total = block.total;
      // "Sin datos" no es un error: la tarjeta muestra "Todo al día".
      status = block.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } on ApiException catch (e) {
      errorMessage = e.message; // ya traducido a español
      status = LoadStatus.failure;
    } finally {
      notifyListeners(); // pinta lista / vacío / error
    }
  }
}
```

### 7.2.6 Lo que yo construyo (UI)

```
lib/features/dashboard/
├── data/
│   ├── dashboard_repository.dart            # GET summary / spending / vehicles-in-maintenance
│   └── models/
│       ├── summary.dart                     # Summary (fleet, tireSpending, maintenanceSpending, staff, periodo)
│       ├── fleet_summary.dart               # FleetSummary (+ byStatus y atajos)
│       ├── spending_summary.dart            # SpendingSummary (amount, changePercent, trend)
│       ├── staff_summary.dart               # StaffSummary
│       ├── spending_history.dart            # SpendingHistory (months, totales, maxMonthlyTotal)
│       ├── monthly_spending.dart            # MonthlySpending (month "YYYY-MM", compras, mantenimiento)
│       ├── vehicle_in_maintenance.dart      # VehicleInMaintenance
│       └── paged_block.dart                 # PagedBlock<T> {total, items}
└── presentation/
    ├── dashboard_page.dart                  # Pantalla de inicio (responsiva 1–3 columnas)
    ├── dashboard_controller.dart            # Carga en paralelo con estado por bloque
    ├── load_status.dart                     # LoadStatus { idle, loading, success, empty, failure }
    ├── money_formatter.dart                 # Formato de dinero sin `intl`
    └── widgets/
        ├── kpi_card.dart                    # KPI + TrendPill
        ├── dashboard_section.dart           # Sección común, ErrorRetry, EmptyState, SkeletonCard, DistributionBar
        ├── spending_chart.dart              # Barras agrupadas con CustomPainter (sin dependencias)
        ├── spending_formatters.dart         # Cambio % / tendencia
        ├── fleet_breakdown_card.dart        # Estado de la flota
        ├── maintenance_card.dart            # Vehículos en taller
        └── staff_card.dart                  # Personal
```

**Endpoints (todos `GET`, envueltos):**

| Endpoint | Query | Modelo |
|----------|-------|--------|
| `dashboard/summary` | `depotId?` | `Summary` |
| `dashboard/spending` | `months`, `depotId?` | `SpendingHistory` |
| `dashboard/vehicles-in-maintenance` | `limit`, `depotId?` | `PagedBlock<VehicleInMaintenance>` |

**Reglas de la UI:**

- **Saludo:** `Hola, <primer nombre>` + periodo del resumen (`1 – 7 nov 2026`).
- **KPIs:** Vehículos (operativos / en taller), Gasto en llantas, Gasto en mantenimiento
  (con badge de tendencia: subir = amber, bajar = teal, sin periodo = neutro) y Personal.
- **Gráfica:** compras (Lime) vs. mantenimiento (Teal); al tocar una barra se fija el mes.
- **Badge de días** en mantenimiento: `≤7` amber · `8–14` naranja de retraso · `>14` coral.
- **Estado por bloque:** si un endpoint falla solo su tarjeta muestra **Reintentar**; el resto sigue visible.
- **Roles:** dashboard visible para `SUPERADMIN`, `OWNER`, `MANAGER` y `ACCOUNTANT`; las cifras de gasto
  solo para `SUPERADMIN`, `OWNER` y `ACCOUNTANT` (los demás ven "Solo administración").
- **Pull-to-refresh** y botón de actualizar en el AppBar.
- `depotId` se transporta en el controller pero aún no hay selector (falta endpoint de depósitos).

### 7.2.7 Lo que ya está resuelto en `core/network/`

El ejemplo **funciona tal cual** desde esta sesión:

1. `ApiClient.unwrap(Object? data)` → devuelve `resultado` como `Map<String, dynamic>`, o el `Map`
   tal cual si no hay envoltura (auth). Lanza `ApiException` si `resultado` viene `null` o no es
   objeto.
2. `ApiClient.unwrapList(Object? data)` → lo mismo cuando `resultado` es una lista (con `null` →
   lista vacía).
3. `ApiException` ya lee **`mensaje`** (antes de `message`/`error`/`detail`) y acepta `codigo` numérico
   como `code`.
4. Tests en `test/api_envelope_test.dart` (11 casos).

Confirmado en tu respuesta: **todos los endpoints usan `{codigo, mensaje, resultado}` salvo
`api/v1/auth/*`**, y `codigo` es el código HTTP.

---

## 8. Si tienes prisa: lo mínimo absoluto

Si no puedes darme todo, con esto me alcanza para empezar:

1. El **JSON real** de respuesta.
2. La **ruta del endpoint**.
3. Qué **roles** ven la pantalla.
4. Un **mockup o descripción** de lo que debe verse.

> Aun así debo saber en qué carpeta de `lib/features/<feature>/` irá (ver §1.1). Si no me dices
> la feature, asumo que es la del nombre de la pantalla. Con esto construyo la UI con datos falsos
> con la forma exacta del JSON; luego solo cambia el origen de los datos.

---

## 9. Referencias internas

- Tema y paleta: `lib/core/theme/` (ver `MEMORY.md` §5.1).
- Red y auth: `lib/core/network/api_client.dart`, `lib/core/auth/`.
- Convenciones: imports `package:rodantex_app/...`, `flutter analyze` y `flutter test` antes de entregar.
