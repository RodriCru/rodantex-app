# Instrucciones del proyecto Rodantex

## Contexto

- App Flutter para gestión de flotillas, en español.
- La guía visual es `paleta-saas.html`; la integración API/UI está descrita en `docs/CONTRATO_API_UI.md`.
- Lee `MEMORY.md` para decisiones y estado entre sesiones; actualízala al cerrar cambios relevantes.

## Estructura y código

- Las features viven en `lib/features/<feature>/` con `data/` y `presentation/`; usa `domain/` solo para lógica pura que lo necesite.
- Mantén las llamadas HTTP dentro de repositories usando el `ApiClient` compartido. La API usa `{codigo, mensaje, resultado}`, salvo `auth/*`.
- Usa imports `package:rodantex_app/...`, no imports relativos.
- Clases, métodos y modelos públicos deben tener documentación Dart `///` que explique su propósito.
- Respeta los tokens y colores de la paleta Fusion; evita inventar colores de marca.
- En formularios, usa etiquetas legibles y en negritas. Toda fecha se selecciona con calendario y se serializa con el formato que espera la API.
- La URL API se configura con `--dart-define=API_BASE_URL=...`; el prefijo `/api/v1/` lo añade `ApiConfig`.

## Trabajo y validación

- Comunicación, documentación y memoria en español.
- El usuario prefiere omitir tests salvo que los pida. No agregues ni ejecutes tests por iniciativa propia; puedes usar `flutter analyze` para revisar cambios de código.
- No crees commits salvo petición explícita del usuario. Si los pide, agrupa cambios relacionados en commits revisables y no incluyas trabajo ajeno o incompleto sin avisar.
- No guardes secretos, tokens ni credenciales en el repositorio.
