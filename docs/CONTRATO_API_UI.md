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

## 2. Lo mínimo que necesito por cada pantalla

Para cada pantalla o módulo (Vehículos, Rutas, Mantenimiento, etc.) necesito **cinco cosas**:

### 2.1 Endpoint exacto

Incluye ruta relativa (se resuelve contra `api/v1/`), método, query params, y un **JSON real de
respuesta** copiado del backend (no inventado).

```yaml
# Ejemplo
pantalla: Lista de vehículos
endpoint: GET vehiculos
query:
  estado: string?        # "EN_RUTA" | "DISPONIBLE" | ...
  page: int?             # 0-based
  size: int?             # default 20
auth: Bearer (ya lo añade ApiClient)
respuesta: ver 2.2
```

### 2.2 JSON real de respuesta

Cópialo tal cual llega. Incluye un caso con valores reales y, si existe, el caso vacío
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

> ⚠️ No pongas solo el DTO de Java si el JSON es muy distinto. Necesito el JSON **real**.

### 2.3 Modelo Dart + `fromJson`

Esto lo haces tú (es donde se suele romper la app). Ejemplo del formato que espero:

```dart
// lib/features/vehicles/data/models/vehicle.dart
enum VehicleStatus {
  enRuta('EN_RUTA', 'En ruta'),
  disponible('DISPONIBLE', 'Disponible'),
  detenido('DETENIDO', 'Detenido'),
  mantenimiento('MANTENIMIENTO', 'Mantenimiento'),
  incidente('INCIDENTE', 'Incidente'),
  retraso('RETRASO', 'Retraso'),
  desconocido('DESCONOCIDO', '—');

  const VehicleStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static VehicleStatus fromApi(String? v) => values.firstWhere(
        (e) => e.apiValue == v,
        orElse: () => desconocido,
      );
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.status,
    required this.odometro,
    this.driverName,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        placa: json['placa'] as String,
        marca: json['marca'] as String,
        modelo: json['modelo'] as String,
        status: VehicleStatus.fromApi(json['estado'] as String?),
        odometro: (json['odometro'] as num).toInt(),
        driverName: (json['conductor'] as Map<String, dynamic>?)?['nombre'] as String?,
      );

  final String id;
  final String placa;
  final String marca;
  final String modelo;
  final VehicleStatus status;
  final int odometro;
  final String? driverName;
}
```

### 2.4 Repository o servicio

Una clase con métodos tipados; **nada de `Map` suelto en la UI**.

```dart
// lib/features/vehicles/data/vehicle_repository.dart
class VehicleRepository {
  VehicleRepository(this._client);
  final ApiClient _client;

  Future<PageResponse<Vehicle>> list({VehicleStatus? status, int page = 0}) async {
    final res = await _client.get<Map<String, dynamic>>(
      'vehiculos',
      query: {
        if (status != null) 'estado': status.apiValue,
        'page': page,
      },
    );
    return PageResponse.fromJson(res.data!, Vehicle.fromJson);
  }

  Future<Vehicle> getById(String id) async { /* … */ }
}
```

### 2.5 Provider / Controller con estados explícitos

Yo diseño **cuatro estados** en cada pantalla: cargando, datos, vacío y error. Necesito que el
controller los exponga de forma uniforme:

```dart
// lib/features/vehicles/presentation/vehicles_controller.dart
enum LoadStatus { idle, loading, success, empty, failure }

class VehiclesController extends ChangeNotifier {
  LoadStatus status = LoadStatus.idle;
  List<Vehicle> vehicles = const [];
  String? errorMessage;

  Future<void> load() async { /* setea status/vehicles/errorMessage + notifyListeners() */ }
}
```

> Si prefieres Riverpod/Bloc, está bien: solo indícame el tipo de `AsyncValue`/`state` y listo.
> Lo importante es que existan **los cuatro estados**, no un `bool isLoading` suelto.

---

## 3. Plantilla para pedirme una pantalla

Copia esto y rellénalo. Con esto puedo entregar la UI completa ese mismo día.

```md
## Pantalla: <nombre>

**Rol(es) que la ven:** OWNER, MANAGER
**Desde:** menú "Vehículos" en Home
**Acciones disponibles:** ver detalle, filtrar por estado, buscar por placa

**Endpoint(s):**
- GET vehiculos (lista paginada)
- GET vehiculos/{id} (detalle)

**JSON de respuesta:** <pegar real>

**Modelo Dart:** <ruta al archivo ya creado / o pegar>
**Repository:** <ruta>
**Controller:** <ruta>
**Estados:** loading | success | empty | failure

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
7. **Paginación:** siempre `{content, totalElements, page, size}` o dime tu forma exacta.
8. **Errores:** el formato de error de la API (ej. `{code, message, details}`) para mostrarlo bien.
9. **Un cambio de contrato = aviso previo.** Si cambia un campo, la pantalla se rompe en silencio.

---

## 7. Ejemplo aplicado: "Vehículos"

### Lo que tú me pasas

```dart
// lib/features/vehicles/data/models/vehicle.dart       → modelo (sección 2.3)
// lib/features/vehicles/data/vehicle_repository.dart   → repository (2.4)
// lib/features/vehicles/presentation/vehicles_controller.dart → controller (2.5)
```

Con `GET vehiculos` real y su JSON:
`[{ id, placa, marca, modelo, estado, odometro, conductor: { id, nombre } }]`

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

## 8. Si tienes prisa: lo mínimo absoluto

Si no puedes darme todo, con esto me alcanza para empezar:

1. El **JSON real** de respuesta.
2. La **ruta del endpoint**.
3. Qué **roles** ven la pantalla.
4. Un **mockup o descripción** de lo que debe verse.

Con eso construyo la UI con datos falsos con la forma exacta del JSON; luego solo cambia el
origen de los datos.

---

## 9. Referencias internas

- Tema y paleta: `lib/core/theme/` (ver `MEMORY.md` §5.1).
- Red y auth: `lib/core/network/api_client.dart`, `lib/core/auth/`.
- Convenciones: imports `package:rodantex_app/...`, `flutter analyze` y `flutter test` antes de entregar.
