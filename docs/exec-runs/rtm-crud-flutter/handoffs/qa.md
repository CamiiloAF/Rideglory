# QA Handoff — rtm-crud-flutter

**Date:** 2026-06-04T19:30:14Z
**Agent:** QA
**Status:** done — conditional sign-off (1 architecture bug)

---

## Catalogo de AC

| AC | Descripción | Cobertura | Estado |
|----|-------------|-----------|--------|
| CA-1 | Payload vía `CreateTecnomecanicaRequestDto.toJson()` | grep + unit (TC-dto-06) | PASS |
| CA-2 | Pattern B: `TecnomecanicaDto extends TecnomecanicaModel`, `.g.dart` sin conflictos | grep + TC-dto-03 + build_runner | PASS |
| CA-3 | `TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel>` + 404→empty | grep + TC-cubit-02 | PASS |
| CA-4 | Registrar: save() → ResultState.data | TC-cubit-04 | PASS |
| CA-5 | Ver: load() → data, documentStatus derivado de mixin (umbral 30d) | TC-cubit-01, TC-rtm-01..05 | PASS |
| CA-6 | Editar: formulario precargado, save → data actualizada | TC-cubit-04 (upsert) — widget test ausente (gap manual) | PASS unit / GAP widget |
| CA-7 | Borrar: ConfirmationDialog + DELETE → empty | TC-cubit-06 + grep `ConfirmationDialog` | PASS |
| CA-8 | Analytics: 4 constantes ≤40 chars, distintas de SOAT | grep + TC-cubit-a1..a8 | PASS |
| CA-9 | Exención no bloqueante: info chip, botón Guardar habilitado | `TecnomecanicaExemptionNotice` widget + código revisado | PASS (test gap) |
| CA-10 | Sin OCR: ningún import image_picker/pdfx/mlkit/UploadCubit | grep → CLEAN | PASS |
| CA-11 | Copy legal propio RTM ≠ SOAT | grep → valores distintos | PASS |
| CA-12 | Clean Architecture: domain/data sin Flutter/HTTP; sin `Widget _buildX()` | grep → CLEAN; dart analyze → 0 issues | PASS |

---

## Matriz de Regresion

| Guardrail | Mecanismo de verificación | Estado |
|-----------|--------------------------|--------|
| Suite SOAT 100% verde | `flutter test test/core/http/rest_client_functions_test.dart` → 30/30 | PASS |
| `flutter test` sin nuevos fallos | Suite completa: 686 tests, 0 failed | PASS |
| `dart analyze` sin nuevos warnings | `dart analyze lib/` → No issues found | PASS |
| `build_runner` sin conflictos | `tecnomecanica_dto.g.dart`, `tecnomecanica_service.g.dart`, `injection.config.dart` generados sin error (reportado por frontend) | PASS |
| Claves SOAT en `app_es.arb` intactas | `grep -c '"soat_'` → 58 claves | PASS |
| Constantes SOAT en `analytics_events.dart` intactas | `grep -c 'soat'` → 16 líneas | PASS |
| `lib/features/vehicle_documents/` no modificado | Solo `vehicle_document_kind.dart` (añadido `rtm`) — los genéricos base no se tocaron | PASS |
| `pubspec.yaml` sin nuevas dependencias | No hay cambios en pubspec | PASS |
| `rideglory-api/` no tocado | git diff no incluye archivos del backend | PASS |

---

## Ejecucion

```
dart analyze lib/                                           → No issues found (0 errors, 0 warnings)
flutter test test/features/tecnomecanica/                   → 30 tests passed, 0 failed
flutter test test/core/http/rest_client_functions_test.dart → 30 tests passed, 0 failed
flutter test (suite completa)                               → 686 tests passed, 0 failed
```

### Checks estáticos

- CA-1: `grep -r "Map<String, dynamic>" lib/features/tecnomecanica/ | grep -v ".g.dart"` — solo aparece en fromJson/toJson de los DTOs (patrón correcto); ningún body construido a mano.
- CA-10: `grep -rn "autofill_banner|ScanSoat|UploadCubit|image_picker|file_picker|pdfx|ml_kit|mlkit|firebase_ml" lib/features/tecnomecanica/` → CLEAN
- CA-12 domain/data sin Flutter: `grep -rn "BuildContext|Widget" lib/features/tecnomecanica/domain/ lib/features/tecnomecanica/data/` → sin resultados
- CA-12 sin `Widget _buildX()`: `grep -rn "Widget _build" lib/features/tecnomecanica/` → CLEAN
- CA-12 strings hardcodeados: ningún literal UI encontrado en capa presentation
- CA-11 copy legal: `tecnomecanica_expired_warning` = "Circular sin revisión técnico-mecánica vigente es una infracción. Lleva tu moto a revisión lo antes posible." vs `soat_expired_warning` = "Circular sin SOAT vigente es una infracción. Renueva tu seguro lo antes posible." → distintos ✓

---

## Bugs

### BUG-01 — `TecnomecanicaManualCapturePage` usa `getIt<TecnomecanicaCubit>()` en `BlocProvider.value`

**Área:** frontend
**Archivo:** `lib/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_page.dart` línea 104–105
**Severidad:** Arquitectura / Media

**Descripción:** El `build()` de `TecnomecanicaManualCapturePage` hace:
```dart
return BlocProvider.value(
  value: getIt<TecnomecanicaCubit>(),
  ...
```
Como `TecnomecanicaCubit` está anotado con `@injectable` (factory), cada llamada a `getIt<TecnomecanicaCubit>()` crea una instancia nueva desconectada del árbol de widgets. La llamada `context.read<TecnomecanicaCubit>().save(...)` en `_submit()` opera sobre este cubit huérfano, cuyo estado no está ligado al `BlocProvider` de `TecnomecanicaStatusPage`. La UX funciona incidentalmente porque `TecnomecanicaStatusView` llama a `.load()` sobre su propio cubit al regresar de la ruta, pero el patrón viola las reglas de Cubits del proyecto (`@injectable + BlocProvider en el árbol`) y produce un cubit que nunca es cerrado correctamente por `BlocProvider.value` (que no cierra cubits que no creó, y el factory de getIt tampoco lo hace).

**Fix recomendado:** Eliminar el `BlocProvider.value` de `TecnomecanicaManualCapturePage.build()` y pasar el cubit como parámetro del constructor (`required TecnomecanicaCubit cubit`) para que sea el mismo cubit del árbol superior, o usar `context.read<TecnomecanicaCubit>()` directamente si la página siempre es hija del árbol de `TecnomecanicaStatusPage`. Alternativamente, si ManualCapturePage puede abrirse sin pasar por StatusPage (vía EntryFlow), el cubit debe ser `create: (_) => getIt<TecnomecanicaCubit>()` (no `.value`), y la StatusPage debe recargar al regresar — como ya lo hace.

---

## Pruebas manuales

Flujos a verificar en device/simulator (reportados por frontend; sin cambios):

| # | Flujo | Precondición |
|---|-------|--------------|
| M-1 | VehicleDetail → tile RTM → StatusPage → hero card verde/naranja/rojo | RTM registrada con fecha futura/próxima/vencida |
| M-2 | StatusPage sin RTM → EmptyState + ExemptionNotice (si <2 años) + botón "Registrar RTM" | Vehículo sin RTM |
| M-3 | EmptyState → botón → ManualCapturePage vacía → completar → Guardar → StatusPage recarga a Data | Vehículo sin RTM |
| M-4 | StatusPage Data → AppBar "Editar" → ManualCapturePage campos precargados → modificar → Guardar → StatusPage recarga | RTM existente |
| M-5 | StatusPage Data → "Eliminar RTM" → ConfirmationDialog → confirmar → SnackBar → StatusPage Empty | RTM existente |
| M-6 | Cualquier operación con server apagado → estado Error + botón Reintentar | Sin red |
| M-7 | ExemptionNotice visible; botón Guardar habilitado (no bloqueante) | Vehículo con purchaseDate < 2 años |
| M-8 | VehicleGarage → VehicleDocumentCard con `kind: rtm` → navega a StatusPage | Card RTM en garage |

---

## Sign-off

**Sign-off:** `conditional`

### Condición para green

- Resolver BUG-01 (arquitectura cubit en ManualCapturePage): cambiar `BlocProvider.value(value: getIt<>())` por el patrón correcto (`BlocProvider(create: ...)` o paso por parámetro).

### Notas

- Los 686 tests existentes pasan sin regresiones.
- `dart analyze` limpio.
- La suite de 30 tests nuevos cubre todos los AC de capa domain, data y cubit con alta densidad.
- Los gaps de widget tests (CA-6 preload, CA-9 botón habilitado) son aceptables para nivel `normal` y se cubren vía pruebas manuales M-4 y M-7.
- El feature no tiene usuarios reales en producción; el riesgo del BUG-01 es arquitectónico, no de pérdida de datos.
