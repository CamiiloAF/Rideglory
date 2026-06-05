# Tech Lead handoff — rtm-crud-flutter

**Date:** 2026-06-04T19:41:01Z
**Revision:** 2 (re-revisión post-fix BUG-01)
**Verdict:** ready

---

## Veredicto

`ready` — BUG-01 resuelto por Frontend. Sin blockers. Todos los tests pasan, `dart analyze` limpio, regresión SOAT verde. Dos watchlist items documentados; ninguno bloquea.

---

## Hallazgos

### W-01 — `_RtmDocumentCardBody` crea cubit con `.load()` pero nunca muestra su estado

**Archivo:** `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` línea 41

`VehicleDocumentCard` crea el cubit con:
```dart
create: (_) => getIt<TecnomecanicaCubit>()..load(vehicle.id ?? ''),
```
Esto dispara una llamada GET al backend al renderizar el card, pero `_RtmDocumentCardBody` no usa `BlocBuilder` — muestra siempre un card estático gris. El resultado del load se descarta.

El cubit del card se usa en `_onTap` para recargar tras regresar de StatusPage, pero ese reload tampoco se muestra.

**Impacto:** Una llamada HTTP innecesaria cada vez que el card se renderiza. Funcionalidad correcta (StatusPage tiene su propio cubit). No afecta ningún AC de Fase 3.

**Recomendación para Fase 4:** Cuando se agregue el `BlocBuilder` para mostrar el estado RTM en el card, el `..load(vehicle.id ?? '')` tiene sentido. Por ahora, si se quiere eliminar el call innecesario, bastaría con `create: (_) => getIt<TecnomecanicaCubit>()` (sin `..load`). Watchlist para Fase 4.

**Severidad:** Watchlist / Baja.

---

### W-02 — Copy SOAT reutilizado en card RTM

**Archivo:** `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` línea 272

`_RtmDocumentCardBody` usa `context.l10n.vehicle_soat_tap_to_add` en el subtítulo del card. El texto es neutral y legible pero semánticamente incorrecto (menciona SOAT implícitamente o es genérico). La clave `tecnomecanica_status_no_rtm` ya existe en `app_es.arb` y sería más adecuada.

**Severidad:** Watchlist / Cosmético — no bloquea.

---

## Seguridad

- Sin secretos hardcodeados. Sin PII en logs. Sin SQL concatenado.
- Auth vía Firebase ID token inyectado por `FirebaseAuthInterceptor` (heredado por `TecnomecanicaService` a través de `AppDio`).
- `CreateTecnomecanicaRequestDto.toJson()` no expone campos server-managed (`id`, `vehicleId`, `createdAt`, `updatedAt`). AC-1 verificado.
- `documentUrl` es string de referencia; no se hace fetch ni se ejecuta. Riesgo mínimo.
- Domain sin Flutter/HTTP. Data sin `BuildContext`. Verificado por `dart analyze` + grep.

---

## Arquitectura

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Clean Architecture | PASS | Domain → Data → Presentation; dependencias inward |
| Pattern B | PASS | `TecnomecanicaDto extends TecnomecanicaModel`; `CreateTecnomecanicaRequestDto` independiente |
| DTO.toJson() obligatorio | PASS | Payload via `requestDto.toJson()`; sin `Map<String, dynamic>` manual en body |
| Cubit @injectable | PASS | `TecnomecanicaCubit` `@injectable`; `TecnomecanicaService` `@singleton` |
| BlocProvider en árbol | PASS | `ManualCapturePage` usa `BlocProvider(create: (_) => getIt<>())` (BUG-01 resuelto) |
| Un widget por archivo | PASS | Grep `Widget _build` → CLEAN; `_RtmDocumentCardBody` en mismo archivo que `_SoatDocumentCardBody` es violación pre-existente no introducida por esta fase |
| Strings localizados | PASS | Cero literales en UI |
| Sin nuevas dependencias | PASS | `pubspec.yaml` sin cambios |
| 404 → Right(null) → empty() | PASS | Implementado en repositoryImpl + cubit |
| ExemptionNotice no bloqueante | PASS | Widget informativo; botón Guardar siempre habilitado |
| Sin OCR | PASS | Grep image_picker/pdfx/mlkit → CLEAN |
| Analytics ≤40 chars | PASS | Máximo: `tecnomecanica_status_viewed` = 27 chars |

---

## Tests

| Suite | Tests | Estado |
|-------|-------|--------|
| `test/features/tecnomecanica/domain/models/tecnomecanica_model_test.dart` | 9 | PASS |
| `test/features/tecnomecanica/data/dto/tecnomecanica_dto_test.dart` | 6 | PASS |
| `test/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit_test.dart` | 15 | PASS |
| Regresión SOAT (`rest_client_functions_test.dart`) | 30 | PASS |
| Suite completa | 686 | PASS |

**Gaps aceptables (nivel normal):**
- CA-6: sin widget test de preload en modo edición — cubierto por prueba manual M-4.
- CA-9: sin widget test de botón habilitado con ExemptionNotice — cubierto por prueba manual M-7.

---

## Pruebas manuales

| # | Flujo | Precondición | Criterio de éxito |
|---|-------|--------------|-------------------|
| M-1 | VehicleDetail → tile RTM → StatusPage | RTM registrada (fecha futura) | Hero card verde, fecha visible |
| M-2 | StatusPage sin RTM → EmptyState | Vehículo sin RTM | EmptyState + ExemptionNotice si <2 años |
| M-3 | EmptyState → botón → ManualCapturePage vacía → Guardar → StatusPage recarga | Sin RTM | StatusPage muestra Data con datos guardados |
| M-4 | StatusPage Data → "Editar" → ManualCapturePage precargada → modificar → Guardar | RTM existente | Campos precargados; post-save StatusPage refleja cambio |
| M-5 | StatusPage Data → "Eliminar RTM" → ConfirmationDialog → confirmar | RTM existente | SnackBar éxito; StatusPage vuelve a Empty |
| M-6 | Operación con server apagado | Sin red | Estado Error + botón Reintentar funcional |
| M-7 | ExemptionNotice visible, botón Guardar habilitado | Vehículo <2 años | Notice naranja visible; formulario no bloqueado |
| M-8 | VehicleGarage → VehicleDocumentCard kind=rtm → navega a StatusPage | Card RTM en garage | Navegación correcta; recarga al regresar |
