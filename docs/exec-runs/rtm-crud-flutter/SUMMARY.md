# SUMMARY — rtm-crud-flutter

**Generado:** 2026-06-04T19:41:01Z (revisión 2)

---

## Objetivo

Implementar CRUD completo de Revisión Técnico-Mecánica (RTM) en Flutter, espejo del flujo SOAT pero sin OCR. El conductor puede registrar, ver, editar y borrar su RTM; la app muestra estado vigente/por vencer/vencido derivado del mixin VehicleDocumentExpiry.

---

## Qué cambió por área

### Core/Shared (modificados)
- `lib/core/http/api_routes.dart` — helper `vehicleTecnomecanica(vehicleId)`
- `lib/core/services/analytics/analytics_events.dart` — 4 constantes RTM (≤40 chars)
- `lib/core/services/analytics/analytics_params.dart` — clave `rtmStatus`
- `lib/shared/router/app_routes.dart` — 2 rutas RTM
- `lib/shared/router/app_router.dart` — 2 GoRoutes registradas
- `lib/l10n/app_es.arb` + archivos generados — ~30 claves `tecnomecanica_*`

### Vehicle Documents
- `lib/features/vehicle_documents/domain/vehicle_document_kind.dart` — añadido `rtm` al enum

### Vehicle Garage
- `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` — case `VehicleDocumentKind.rtm` + `_RtmDocumentCardBody`

### Feature tecnomecanica (nuevo completo)
- Domain: TecnomecanicaModel, TecnomecanicaRepository, 3 use cases
- Data: TecnomecanicaDto (Pattern B), CreateTecnomecanicaRequestDto, TecnomecanicaService (@singleton Retrofit), TecnomecanicaRepositoryImpl
- Presentation: TecnomecanicaCubit (@injectable), StatusPage, ManualCapturePage, StatusView, DataView, EmptyState, ExemptionNotice, EntryFlow

---

## Archivos

19 archivos nuevos en `lib/features/tecnomecanica/`, 8 archivos modificados. Ver handoffs/frontend.md para el listado completo.

---

## Pruebas

- `dart analyze lib/` → 0 errores, 0 warnings
- `flutter test test/features/tecnomecanica/` → 30 tests nuevos, todos pasan
- `flutter test` suite completa → 686 tests, 0 fallos

---

## Riesgos/Watchlist

**BUG-01 RESUELTO:** `TecnomecanicaManualCapturePage.build()` usaba `BlocProvider.value(value: getIt<TecnomecanicaCubit>())` (cubit huérfano sin ciclo de vida). Corregido a `BlocProvider(create: (_) => getIt<TecnomecanicaCubit>())` por Frontend en revisión 2.

**WATCHLIST-01 (performance):** `_RtmDocumentCardBody` dispara `..load(vehicle.id ?? '')` en su `BlocProvider.create` pero no tiene `BlocBuilder` — la llamada HTTP se descarta. Sin impacto funcional. Fase 4 agregará el `BlocBuilder` para mostrar el estado dinámico en el card.

**WATCHLIST-02 (cosmético):** `_RtmDocumentCardBody` usa `vehicle_soat_tap_to_add` en lugar de una clave RTM propia. No bloquea.

---

## Mensaje de commit sugerido

```
feat(rtm): CRUD completo de revisión técnico-mecánica en Flutter

- Feature tecnomecanica/ con Clean Architecture (domain/data/presentation)
- TecnomecanicaModel + VehicleDocumentExpiry mixin, Pattern B DTO
- TecnomecanicaService Retrofit @singleton, 404→Right(null)→empty()
- TecnomecanicaCubit @injectable con analytics (4 eventos RTM)
- StatusPage + ManualCapturePage (sin OCR) + EntryFlow
- ExemptionNotice no bloqueante para vehículos <2 años
- VehicleDocumentKind.rtm + VehicleDocumentCard case rtm
- 2 rutas go_router + ~30 claves l10n tecnomecanica_*
- 30 tests nuevos (domain model, DTO, cubit + analytics)
```
