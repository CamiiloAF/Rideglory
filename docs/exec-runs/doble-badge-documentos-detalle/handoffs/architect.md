# Architect handoff — doble-badge-documentos-detalle

**Fecha:** 2026-06-04T20:49:36Z
**Status:** done
**Nivel:** normal

---

## Decisiones

### D-1: Prerequisitos de Fase 1 y Fase 3 — SATISFECHOS con reserva

`vehicle_documents/` existe con dominio completo (`VehicleDocumentModel`, `VehicleDocumentExpiry`,
`VehicleDocumentStatus`, `VehicleDocumentKind`, `VehicleDocumentCubit<T>`). `SoatCubit extends
VehicleDocumentCubit<SoatModel>` y `TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel>`.
`TecnomecanicaModel` implementa `VehicleDocumentModel` vía el mixin. El flujo RTM completo existe
(`TecnomecanicaStatusPage`, `TecnomecanicaEntryFlow`, `AppRoutes.tecnomecanicaStatus`).

**Reserva:** `vehicle_document_card.dart` (en `vehicles/presentation/garage/widgets/`) usa
`getIt<SoatCubit>()` y `getIt<TecnomecanicaCubit>()` dentro de `BlocProvider.create` y contiene
imports concretos de `features/soat/` y `features/tecnomecanica/`. La docstring del archivo dice
explícitamente "No getIt calls in the widget body — DI only in BlocProvider.create factory", lo que
indica que esta es la entrega intencional de Fase 1. **El gate A11 del PRD aplica ÚNICAMENTE a los
dos hosts del detalle** (`vehicle_detail_page.dart` y `vehicle_detail_view.dart`), no a
`vehicle_document_card.dart`. Por tanto la fase 4 PUEDE proceder sin bloquear.

### D-2: Patrón de provisión de cubits — mantenemos BlocProvider self-contained en VehicleDocumentCard

`VehicleDocumentCard` instancia sus propios cubits con `BlocProvider(create: (_) => getIt<XCubit>()..load())`.
Esto mantiene cada badge autocontenido y garantiza carga independiente sin bloqueo cruzado. **No se
mueven los `BlocProvider`s al host** (`vehicle_detail_page.dart`), porque hacerlo requeriría importar
`SoatCubit`/`TecnomecanicaCubit` concretos en el host, lo que rompería el gate A11. El patrón actual
cumple el Criterio 4 (carga independiente) y el gate A11 sobre los hosts.

### D-3: VehicleDocumentCard — solo completar _RtmDocumentCardBody

`_SoatDocumentCardBody` está completamente implementado (4 estados, BlocBuilder, tap). 
`_RtmDocumentCardBody` es un STUB: card estático sin BlocBuilder, sin estados de carga, sin manejo
de `documentStatus`. **Phase 4 debe completar `_RtmDocumentCardBody`** para que muestre los mismos
4 estados derivados de `ResultState<TecnomecanicaModel>` + `VehicleDocumentStatus`. El tap RTM ya
existe (`AppRoutes.tecnomecanicaStatus`).

### D-4: Gate A11 — vehicle_detail_view.dart falla HOY, se corrige en esta fase

`vehicle_detail_view.dart` línea 11 importa `TecnomecanicaEntryFlow` (de `features/tecnomecanica/`)
y líneas 66-74 tienen `OutlinedButton.icon` con `TecnomecanicaEntryFlow.start(context, vehicle)`.
Esto es exactamente el anti-patrón de la fase: un placeholder que acopla el host del detalle con
`tecnomecanica/`. La corrección es: (1) eliminar el import de `TecnomecanicaEntryFlow`, (2) reemplazar
el `OutlinedButton.icon` con `VehicleDocumentCard(kind: VehicleDocumentKind.rtm, vehicle: vehicle)`.
Después de este cambio el grep acotado del Criterio 1 devuelve cero matches.

`vehicle_detail_page.dart` ya pasa el gate A11 (sin imports de soat/ ni tecnomecanica/).

### D-5: Huérfano vehicle_soat_section.dart — borrar

Confirmado sin consumidores reales en `lib/` (solo aparece en el propio archivo y en las claves l10n
del ARB, que no son imports de código). Se borra.

### D-6: vehicle_soat_card.dart — NO EXISTE

El archivo `vehicle_soat_card.dart` no existe en el árbol (`find` confirma). La lógica del SOAT badge
vive íntegramente en `_SoatDocumentCardBody` dentro de `vehicle_document_card.dart`. No hay nada que
borrar para este item.

### D-7: l10n para el badge RTM — 3 claves nuevas necesarias

`_SoatDocumentCardBody` usa claves cortas de estado: `soat_status_valid` ("Vigente"), 
`soat_status_expiring_soon` ("Por vencer"), `maintenance_expired_label` ("vencido"). Para `_RtmDocumentCardBody`
se necesitan equivalentes. Las claves existentes de tecnomecanica son para la página de estado completa
("Tu RTM está al día", "Tu RTM vence pronto", etc.), no para el badge compacto. Se añaden 3 claves
nuevas de badge: `vehicle_doc_rtm_status_valid`, `vehicle_doc_rtm_status_expiring_soon`,
`vehicle_doc_rtm_status_expired`. La clave "tap to add" para RTM reutiliza `tecnomecanica_status_no_rtm`
("Sin RTM registrada") — ya existe.

### D-8: BlocListener de odómetro — sin riesgo

`vehicle_detail_page.dart` no se modifica en esta fase (no necesita importar cubits nuevos dado D-2).
El `BlocListener<VehicleCubit>` de odómetro queda intacto.

---

## Change map

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` | modify | Eliminar import `TecnomecanicaEntryFlow`; reemplazar `OutlinedButton.icon` con `VehicleDocumentCard(kind:rtm)`. Satisface gate A11. | med |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` | modify | Completar `_RtmDocumentCardBody` con `BlocBuilder<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>` y 4 estados (loading skeleton, valid, expiringSoon, expired, empty). Reutilizar mismo layout que `_SoatDocumentCardBody`. | med |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_section.dart` | delete | Huérfano confirmado (sin consumidores en lib/). Importa features/soat/ sin razón. | low |
| `lib/l10n/app_es.arb` | modify | Añadir 3 claves de badge RTM: `vehicle_doc_rtm_status_valid`, `vehicle_doc_rtm_status_expiring_soon`, `vehicle_doc_rtm_status_expired`. | low |
| `lib/l10n/app_localizations.dart` | modify | Regenerado por flutter gen-l10n (no editar a mano). | low |
| `lib/l10n/app_localizations_es.dart` | modify | Regenerado por flutter gen-l10n (no editar a mano). | low |
| `test/features/vehicles/presentation/vehicle_documents_badges_test.dart` | create | Widget tests: dos badges, carga independiente, regresión SOAT 4 estados, tap por kind, listener de odómetro. | low |

**Archivos NO tocar (guardrails):**
- `lib/features/vehicles/presentation/detail/vehicle_detail_page.dart` — sin cambios necesarios (gate A11 ya lo pasa)
- `lib/features/vehicles/presentation/form/**` — fuera de alcance
- `vehicle_soat_form_slot.dart`, `vehicle_form_docs_section.dart`, `vehicle_form_view.dart` — fuera de alcance

---

## Contratos rideglory-api

**Ninguno.** Fase 100% Flutter de presentación. No hay endpoints nuevos ni modificados.

---

## Datos / migraciones

**Ninguno.** No hay cambios de Prisma, esquema ni persistencia.

---

## Env

**Ninguna variable nueva.** No se necesita `ENV_DELTA.md`.

---

## Riesgos

| ID | Riesgo | Severidad | Mitigación |
|----|--------|-----------|-----------|
| R-visual | Regresión visual del badge SOAT si `_SoatDocumentCardBody` se toca accidentalmente. | media | `_SoatDocumentCardBody` es readonly en esta fase; solo se añade `_RtmDocumentCardBody` completo. Widget test parametrizado por 4 estados. |
| R-cross | Bloqueo cruzado si `_RtmDocumentCardBody` comparte cubit con `_SoatDocumentCardBody`. | media | Cada `BlocProvider` en `VehicleDocumentCard.build` crea su propia instancia; son independientes por diseño (switch por kind). Widget test con estados desincronizados. |
| R-listener | Romper `BlocListener<VehicleCubit>` si se modifica `vehicle_detail_page.dart` por error. | media | `vehicle_detail_page.dart` NO se modifica. Solo `vehicle_detail_view.dart` cambia. |
| R-l10n | Strings RTM hardcodeadas o duplicadas. | baja | 3 claves nuevas en ARB; regenerar localization; 0 literales en widget. |
| R-import | `TecnomecanicaEntryFlow` import olvidado en `vehicle_detail_view.dart`. | baja | Gate A11 grep acotado ejecutado como paso de verificación final. |

---

## Orden de implementación

1. `app_es.arb` — añadir 3 claves RTM badge (no deps)
2. `flutter gen-l10n` — regenerar localization
3. `vehicle_document_card.dart` — completar `_RtmDocumentCardBody` con 4 estados
4. `vehicle_detail_view.dart` — eliminar import TecnomecanicaEntryFlow + reemplazar OutlinedButton
5. `vehicle_soat_section.dart` — borrar (verificar con grep antes)
6. Ejecutar grep gate A11 acotado → debe dar 0 matches
7. `test/features/vehicles/presentation/vehicle_documents_badges_test.dart` — crear widget tests
8. `dart analyze` — verificar sin nuevos warnings
9. `flutter gen-l10n` + `dart run build_runner build` si aplica

---

## Superficie de regresión

- `vehicle_detail_page.dart`: BlocListener<VehicleCubit> odómetro (sin tocar)
- `vehicle_document_card.dart`: `_SoatDocumentCardBody` 4 estados (leer-only)
- Flujo form alta de vehículo: `vehicle_form_docs_section.dart`, `vehicle_soat_form_slot.dart`, `vehicle_form_view.dart` (sin tocar)
- Tests existentes SOAT: `test/features/vehicles/presentation/cubit/vehicle_form_cubit_soat_test.dart` (sin tocar)

---

## Fuera de alcance

- Eliminar getIt del `BlocProvider.create` de `vehicle_document_card.dart` (deuda de Fase 1, no gate A11)
- Desacoplar `vehicle_form_docs_section.dart` de `soat/` (ADR-E pendiente, Fase distinta)
- Unificación de strings SOAT↔RTM (Fase 1/3)
- Promoción de `home_garage_soat_badge.dart` al genérico (deuda conocida de Fase 1)
- Backend, migraciones, notificaciones push (Fases 2/5)
