# Frontend handoff — rtm-crud-flutter

**Date:** 2026-06-04T19:23:12Z
**Agent:** Frontend (Flutter lib/)
**Status:** done

---

## Baseline

- `flutter test test/core/http/rest_client_functions_test.dart` → **30 tests passed** before any changes.
- `dart analyze lib/` → 0 errors, 0 warnings (baseline had local-api lint noise already ignored per memory).

---

## Archivos cambiados

### Modificados

| Archivo | Cambio |
|---------|--------|
| `lib/features/vehicle_documents/domain/vehicle_document_kind.dart` | Añadido `rtm` al enum `VehicleDocumentKind` |
| `lib/core/http/api_routes.dart` | Añadido helper `vehicleTecnomecanica(vehicleId)` |
| `lib/core/services/analytics/analytics_events.dart` | Añadidas 4 constantes: `tecnomecanicaStatusViewed`, `tecnomecanicaManualSaved`, `tecnomecanicaUpdated`, `tecnomecanicaDeleted` |
| `lib/core/services/analytics/analytics_params.dart` | Añadida clave `rtmStatus` |
| `lib/shared/router/app_routes.dart` | Añadidas rutas `tecnomecanicaStatus` y `tecnomecanicaManualCapture` |
| `lib/shared/router/app_router.dart` | Registradas 2 GoRoutes RTM + imports de páginas tecnomecanica |
| `lib/l10n/app_es.arb` | Añadidas ~30 claves `tecnomecanica_*` con copy ES completo |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` | Añadido case `VehicleDocumentKind.rtm` al switch exhaustivo + `_RtmDocumentCardBody` |
| `lib/core/di/injection.config.dart` | Regenerado por build_runner (auto) — incluye TecnomecanicaService, repo, use cases, cubit |

### Creados — Domain

| Archivo | Descripción |
|---------|-------------|
| `lib/features/tecnomecanica/domain/models/tecnomecanica_model.dart` | Modelo puro con `VehicleDocumentExpiry` mixin |
| `lib/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart` | Interfaz abstracta |
| `lib/features/tecnomecanica/domain/usecases/get_tecnomecanica_usecase.dart` | Read use case |
| `lib/features/tecnomecanica/domain/usecases/save_tecnomecanica_usecase.dart` | Write use case (upsert) |
| `lib/features/tecnomecanica/domain/usecases/delete_tecnomecanica_usecase.dart` | Delete use case |

### Creados — Data

| Archivo | Descripción |
|---------|-------------|
| `lib/features/tecnomecanica/data/dto/tecnomecanica_dto.dart` | Pattern B DTO (read) + `CreateTecnomecanicaRequestDto` (write) con `toJson()` |
| `lib/features/tecnomecanica/data/dto/tecnomecanica_dto.g.dart` | Generado por build_runner |
| `lib/features/tecnomecanica/data/service/tecnomecanica_service.dart` | Retrofit `@singleton` GET/POST/DELETE |
| `lib/features/tecnomecanica/data/service/tecnomecanica_service.g.dart` | Generado por build_runner |
| `lib/features/tecnomecanica/data/repository/tecnomecanica_repository_impl.dart` | Impl: 404 → `Right(null)` → `ResultState.empty()` |

### Creados — Presentation

| Archivo | Descripción |
|---------|-------------|
| `lib/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart` | `@injectable`, extiende `VehicleDocumentCubit<TecnomecanicaModel>`, métodos load/save/delete con analytics |
| `lib/features/tecnomecanica/presentation/pages/tecnomecanica_status_page.dart` | BlocProvider + load on init |
| `lib/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_page.dart` | StatefulWidget; formulario 6 campos; modo creación/edición; sin OCR |
| `lib/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_params.dart` | Data class params para go_router extra |
| `lib/features/tecnomecanica/presentation/flow/tecnomecanica_entry_flow.dart` | Entry flow estático (sin bottom sheet) |
| `lib/features/tecnomecanica/presentation/widgets/tecnomecanica_status_view.dart` | Scaffold con AppBar + BlocBuilder; todos los estados |
| `lib/features/tecnomecanica/presentation/widgets/tecnomecanica_data_view.dart` | Hero card + warning banner + details card + actions |
| `lib/features/tecnomecanica/presentation/widgets/tecnomecanica_empty_state.dart` | Empty state con ExemptionNotice + CTA |
| `lib/features/tecnomecanica/presentation/widgets/tecnomecanica_exemption_notice.dart` | Info chip naranja no bloqueante (vehículos <2 años) |

### Creados — Tests

| Archivo | Tests |
|---------|-------|
| `test/features/tecnomecanica/domain/models/tecnomecanica_model_test.dart` | 9 tests: documentStatus, copyWith, equality |
| `test/features/tecnomecanica/data/dto/tecnomecanica_dto_test.dart` | 6 tests: fromJson, toJson, Pattern B inheritance |
| `test/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit_test.dart` | 15 tests: load/save/delete states + 8 analytics tests |

---

## Pruebas nuevas

**Total: 30 tests nuevos** — todos en `test/features/tecnomecanica/`.

### Cobertura por módulo

- **Domain model** (9): documentStatus valid/expiringSoon/expired, daysUntilExpiry day-aligned, copyWith, equality/hashCode.
- **DTO serialization** (6): fromJson required fields, null optionals, Pattern B inheritance check, toJson ISO8601, optional fields, write DTO no tiene id/vehicleId.
- **Cubit — estados** (7): load→data, load→empty (404), load→error, save→data, save→error, delete→empty, delete→error.
- **Cubit — analytics** (8): updated vs manual_saved según id, updated NO cuando id vacío, deleted on success, deleted NO on error, ningún evento on save error, status_viewed on data, status_viewed NO on empty.

---

## Fix aplicado — BUG-01 (Tech Lead MODE FIX)

**Archivo:** `lib/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_page.dart` línea 104

**Problema:** `build()` usaba `BlocProvider.value(value: getIt<TecnomecanicaCubit>())`. Como `TecnomecanicaCubit` es `@injectable` (factory), cada rebuild creaba una instancia nueva huérfana que `BlocProvider.value` nunca disponía.

**Fix:** Cambiado a `BlocProvider(create: (_) => getIt<TecnomecanicaCubit>())` — BlocProvider con `create` es responsable del ciclo de vida y llama `close()` automáticamente al desmontar.

---

## Resultado final

```
dart analyze lib/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_page.dart  →  0 issues
flutter test --no-pub  →  exit 0 (all tests passed)
```

---

## Verificación manual

Flujos a verificar manualmente en el device/simulator:

1. **Ver RTM existente**: navegar a VehicleDetail → tile RTM → StatusPage carga y muestra hero card verde/naranja/rojo según fecha.
2. **RTM no registrada**: StatusPage muestra EmptyState con ExemptionNotice (si vehículo <2 años) + botón "Registrar RTM".
3. **Registrar RTM nueva**: EmptyState → botón → ManualCapturePage vacía → completar campos → Guardar → StatusPage recarga a Data.
4. **Editar RTM**: StatusPage Data → AppBar "Editar" → ManualCapturePage con campos precargados → modificar → Guardar → StatusPage recarga.
5. **Eliminar RTM**: StatusPage Data → "Eliminar RTM" → ConfirmationDialog → confirmar → SnackBar "RTM eliminada" → StatusPage vuelve a Empty.
6. **Error de red**: apagar server → cualquier operación → estado Error con mensaje + botón Reintentar.
7. **ExemptionNotice**: vehículo con purchaseDate < 2 años → notice naranja visible en EmptyState y ManualCapturePage.

---

## Notas para QA

1. **`TecnomecanicaManualCapturePage` no tiene cubit propio** — usa `BlocProvider(create: _ => getIt<TecnomecanicaCubit>())` en `TecnomecanicaStatusPage`. Cuando se navega desde EntryFlow directamente a ManualCapture sin pasar por StatusPage, el cubit se crea en ManualCapturePage vía `BlocProvider(create: _ => getIt<TecnomecanicaCubit>())`.

2. **ExemptionNotice no bloquea** — el botón "Guardar datos" permanece habilitado aunque el vehículo sea menor a 2 años. Es puramente informativo.

3. **Pattern B validado en tests**: `TecnomecanicaDto extends TecnomecanicaModel`; `CreateTecnomecanicaRequestDto` es independiente y su `toJson()` no incluye `id` ni `vehicleId`.

4. **Analytics `rtm_status`** — el valor enviado es `documentStatus.name` (enum string: `valid`, `expiringSoon`, `expired`, `none`). Verificar en Firebase DebugView.

5. **404 → empty**: el repositorio convierte 404 en `Right(null)` que el cubit convierte a `ResultState.empty()`. QA puede simular cortando el server después de guardar para ver el estado de error.

6. **`VehicleDocumentCard` con `kind: VehicleDocumentKind.rtm`** — actualmente muestra un card estático (no carga SOAT status); navega a `AppRoutes.tecnomecanicaStatus`. Si el equipo quiere mostrar el estado del RTM en el card del garage, es trabajo adicional (no en scope de esta iteración).
