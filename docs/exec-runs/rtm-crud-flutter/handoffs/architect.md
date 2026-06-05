# Architect handoff — rtm-crud-flutter

**Date:** 2026-06-04T18:47:15Z
**Status:** done

---

## Decisiones

| # | Decisión | Razón |
|---|----------|-------|
| A-1 | `TecnomecanicaModel with VehicleDocumentExpiry implements VehicleDocumentModel` — clase Dart pura, no freezed | Espejo exacto del patrón `SoatModel`; coherencia de codebase |
| A-2 | `TecnomecanicaDto extends TecnomecanicaModel` (Pattern B) + `CreateTecnomecanicaRequestDto` separado con `.toJson()` para el payload de escritura | Distingue DTO de lectura (herencia) de DTO de escritura (solo los campos mutables), evita serializar campos server-managed (`id`, `createdAt`) |
| A-3 | `TecnomecanicaService` marcado `@singleton` | Misma política que `SoatService`; los Retrofit clients son stateless y singleton es correcto |
| A-4 | `TecnomecanicaCubit` marcado `@injectable` (no `@singleton`) + `BlocProvider` en `TecnomecanicaStatusPage` con `getIt<TecnomecanicaCubit>()` | Regla de memory: cubits van injectable + BlocProvider; `AuthCubit` es la excepción, no la norma |
| A-5 | `VehicleDocumentKind.rtm` añadido al enum existente en `vehicle_documents/domain/` | El enum sólo tenía `soat`; RTM es el segundo kind; la extensión es trivial y es el lugar correcto |
| A-6 | `TecnomecanicaEntryFlow` — `abstract final class` con método estático `start(context, vehicle)`, sin bottom sheet de opciones (no hay OCR) | Sin OCR no hay selección de fuente; la única acción es navegar a `TecnomecanicaManualCapturePage` |
| A-7 | `TecnomecanicaExemptionNotice` widget no bloqueante: calcula exención con `purchaseDate` (< 2 años desde hoy) o `year` como fallback | `VehicleModel` tiene ambos campos; ninguna dependencia externa |
| A-8 | `ApiRoutes.vehicleTecnomecanica(vehicleId)` helper — misma firma que `vehicleSoat` | Consistencia con el patrón de rutas dinámicas de `ApiRoutes` |
| A-9 | Cero nuevos paquetes `pubspec.yaml` | Todos los patrones y dependencias ya existen en el árbol |
| A-10 | `TecnomecanicaManualCapturePage` — `StatefulWidget` directo (no usa `SoatCubit`; save/delete vía `TecnomecanicaCubit` inyectado desde el stack con `context.read`) | Alineado con cómo `SoatManualCapturePage` usa `getIt<SaveSoatUseCase>()` — para RTM simplificamos: sin OCR ni upload, podemos usar cubit directo |

---

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/features/vehicle_documents/domain/vehicle_document_kind.dart` | modify | Añadir `rtm` al enum | low |
| `lib/features/tecnomecanica/domain/models/tecnomecanica_model.dart` | create | Modelo de dominio puro | low |
| `lib/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart` | create | Interfaz de repositorio | low |
| `lib/features/tecnomecanica/domain/usecases/get_tecnomecanica_usecase.dart` | create | Use case de lectura | low |
| `lib/features/tecnomecanica/domain/usecases/save_tecnomecanica_usecase.dart` | create | Use case de escritura | low |
| `lib/features/tecnomecanica/domain/usecases/delete_tecnomecanica_usecase.dart` | create | Use case de borrado | low |
| `lib/features/tecnomecanica/data/dto/tecnomecanica_dto.dart` | create | DTO de lectura Pattern B + `CreateTecnomecanicaRequestDto` | low |
| `lib/features/tecnomecanica/data/dto/tecnomecanica_dto.g.dart` | create | Generado por build_runner | low |
| `lib/features/tecnomecanica/data/service/tecnomecanica_service.dart` | create | Retrofit client `@singleton` | low |
| `lib/features/tecnomecanica/data/service/tecnomecanica_service.g.dart` | create | Generado por build_runner | low |
| `lib/features/tecnomecanica/data/repository/tecnomecanica_repository_impl.dart` | create | Implementación concreta con 404→Right(null) | low |
| `lib/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart` | create | Cubit `@injectable` que extiende `VehicleDocumentCubit<TecnomecanicaModel>` | low |
| `lib/features/tecnomecanica/presentation/pages/tecnomecanica_status_page.dart` | create | Página de estado RTM con BlocProvider | low |
| `lib/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_page.dart` | create | Formulario de captura/edición RTM | med |
| `lib/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_params.dart` | create | Params objeto para go_router extra | low |
| `lib/features/tecnomecanica/presentation/flow/tecnomecanica_entry_flow.dart` | create | Orquestador de navegación sin bottom sheet | low |
| `lib/features/tecnomecanica/presentation/widgets/tecnomecanica_status_view.dart` | create | Vista principal de estado (espejo de SoatStatusView) | low |
| `lib/features/tecnomecanica/presentation/widgets/tecnomecanica_data_view.dart` | create | Vista cuando existe RTM (espejo de SoatDataView) | low |
| `lib/features/tecnomecanica/presentation/widgets/tecnomecanica_empty_state.dart` | create | Estado vacío — sin RTM registrada | low |
| `lib/features/tecnomecanica/presentation/widgets/tecnomecanica_exemption_notice.dart` | create | Info chip no bloqueante de exención (<2 años) | low |
| `lib/core/services/analytics/analytics_events.dart` | modify | Añadir constantes `tecnomecanica_*` | low |
| `lib/core/services/analytics/analytics_params.dart` | modify | Añadir `rtmStatus` param key si aplica | low |
| `lib/core/http/api_routes.dart` | modify | Añadir `vehicleTecnomecanica(vehicleId)` helper | low |
| `lib/shared/router/app_routes.dart` | modify | Añadir `tecnomecanicaStatus`, `tecnomecanicaManualCapture` | low |
| `lib/shared/router/app_router.dart` | modify | Registrar 2 rutas RTM (espejo de SOAT ~líneas 372–391) | low |
| `lib/l10n/app_es.arb` | modify | Añadir claves `tecnomecanica_*` | low |
| `lib/core/di/injection.config.dart` | create/modify | Regenerado por build_runner | low |

---

## Contratos rideglory-api

> La API fue cerrada en Fase 2. No se toca `rideglory-api/`. Este bloque es solo referencia para el Frontend al construir el Retrofit client y los DTOs.

| Method | Path | Auth | Request body | Success | Errors |
|--------|------|------|-------------|---------|--------|
| GET | `/api/vehicles/:vehicleId/tecnomecanica` | Bearer Firebase ID token | — | `200 TecnomecanicaResponse` | `404` (sin RTM → Right(null) en Flutter) |
| POST | `/api/vehicles/:vehicleId/tecnomecanica` | Bearer Firebase ID token | `CreateTecnomecanicaRequestDto.toJson()` | `200/201 TecnomecanicaResponse` | `400`, `404` |
| DELETE | `/api/vehicles/:vehicleId/tecnomecanica` | Bearer Firebase ID token | — | `204 No Content` | `404` |

### TecnomecanicaResponse (shape del GET/POST response)

```json
{
  "id": "string",
  "vehicleId": "string",
  "certificateNumber": "string",
  "cdaName": "string",
  "cdaCode": "string | null",
  "startDate": "ISO8601 | null",
  "expiryDate": "ISO8601",
  "documentUrl": "string | null",
  "createdAt": "ISO8601",
  "updatedAt": "ISO8601"
}
```

### CreateTecnomecanicaRequest (body del POST)

```json
{
  "certificateNumber": "string",       // required
  "cdaName": "string",                 // required
  "cdaCode": "string | null",          // optional
  "startDate": "ISO8601 | null",       // optional
  "expiryDate": "ISO8601",             // required
  "documentUrl": "string | null"       // optional
}
```

---

## Datos / migraciones

No hay cambios de esquema en esta fase. El contrato de backend (Prisma `Tecnomecanica`) fue cerrado en Fase 2 de `rideglory-api`. No se genera ni ejecuta ninguna migración en esta fase. Ver `docs/exec-runs/rtm-crud-flutter/analysis/` si se requieren notas adicionales.

---

## Env

Sin cambios. No se añaden variables de entorno nuevas. `pubspec.yaml` sin cambios de paquetes.

---

## Riesgos

| Riesgo | Mitigación |
|--------|-----------|
| `VehicleDocumentKind` solo tenía `soat` — añadir `rtm` puede romper switches exhaustivos en SOAT si alguno usa `switch(kind)` sin default | Grep previo de usos de `VehicleDocumentKind` antes de editar; el único uso conocido es `SoatModel.kind` que devuelve el literal, no hace switch |
| `TecnomecanicaManualCapturePage` es StatefulWidget complejo — riesgo de violar "un widget por archivo" en sub-secciones del formulario | Cada sección visual que sea widget propio va en su archivo; el QA verifica grep de `Widget _build` |
| `build_runner` conflictos si el developer no limpia antes de regenerar | Instrucción explícita en architect-for-frontend: `dart run build_runner build --delete-conflicting-outputs` |
| Backend Fase 2 puede no estar deployado — la integración real falla aunque el Flutter esté correcto | El cubit funciona con cualquier repositorio (incluyendo fake); QA puede validar con mock sin API real |

---

## Orden de implementación

1. `lib/features/vehicle_documents/domain/vehicle_document_kind.dart` — añadir `rtm` (trivial, base para todos los demás)
2. `lib/core/http/api_routes.dart` — añadir `vehicleTecnomecanica`
3. `lib/features/tecnomecanica/domain/` — modelos, repositorio, use cases (sin dependencias de Flutter)
4. `lib/features/tecnomecanica/data/` — DTOs, service, repository impl
5. `lib/features/tecnomecanica/presentation/cubit/` — cubit
6. `lib/features/tecnomecanica/presentation/widgets/` — widgets (exemption notice, empty state, data view, status view)
7. `lib/features/tecnomecanica/presentation/pages/` — páginas + params + entry flow
8. `lib/l10n/app_es.arb` — claves `tecnomecanica_*`
9. `lib/core/services/analytics/analytics_events.dart` + `analytics_params.dart`
10. `lib/shared/router/app_routes.dart` + `app_router.dart`
11. `dart run build_runner build --delete-conflicting-outputs`

---

## Superficie de regresión

- `lib/features/soat/` — no se toca; riesgo cero si el build_runner no tiene conflictos
- `lib/features/vehicle_documents/` — solo se añade un enum value; cualquier switch sin default en SOAT debe auditarse
- `lib/l10n/app_es.arb` — claves SOAT intactas; solo adiciones al final del bloque
- `lib/core/services/analytics/analytics_events.dart` — claves SOAT intactas; solo adiciones
- `lib/core/di/injection.config.dart` — regenerado; el build_runner no rompe registros existentes si los archivos fuente son correctos
- `flutter test` suite SOAT debe pasar sin modificaciones

---

## Fuera de alcance

- Badge RTM en detalle del vehículo → Fase 4
- Backend/migraciones → ya cerrado en Fase 2
- Notificaciones push de vencimiento → Fase 5
- OCR / scan / image_picker / pdfx → explícitamente excluido
- Cambios en `lib/features/soat/` o `lib/features/vehicle_documents/`
- Cambios en `rideglory-api/`
