# 01 — System Scan — Tecnomecánica (RTM)

**Slug:** `tecnomecanica-rtm`
**Generado:** 2026-06-04T13:01:33Z
**Rol:** System Scanner (gap-analysis para planeación)
**Lente:** `docs/plans/tecnomecanica-rtm/00-intake.md`

> Sesión de planeación. No se modificó código. Inventario por nombres + gap vs objetivo (paridad RTM con SOAT + extracción de abstracción `VehicleDocument`).

---

## Inventario Flutter

### `lib/features/soat/` (referencia a generalizar) — completo y maduro

**Domain**
- `domain/models/soat_model.dart` — `SoatModel` (clase pura, no freezed; `copyWith`, `==`/`hashCode` manuales) + `enum SoatStatus { noSoat, valid, expiringSoon, expired }`. **Aquí vive la lógica candidata a compartir:** getters `status` y `daysUntilExpiry` (umbral 30d). `expiryDate` es **no-null**; `startDate`, `policyNumber`, `insurer`, `documentUrl` opcionales.
- `domain/models/soat_extraction.dart`, `soat_scan_result.dart` — modelos del flujo OCR (fuera de alcance RTM).
- `domain/repository/soat_repository.dart` — interfaz `getSoat`/`saveSoat`/`deleteSoat`.
- `domain/usecases/` — `get_soat_usecase` (`Either<…, SoatModel?>`), `save_soat_usecase` (`{vehicleId, soat}`), `delete_soat_usecase`, `parse_soat_text_usecase`, `scan_soat_usecase` (los dos últimos = OCR, **no se replican**).

**Data**
- `data/dto/soat_dto.dart` (+ `.g.dart`) — **Pattern B**: `SoatDto extends SoatModel`, `fromJson`/`toJson` generados (`apiJsonDateTimeConverters`), y `extension SoatModelToRequest.toRequestJson()` para el payload POST (omite nulos). Nota: el payload de escritura usa un `Map` construido a mano dentro de la extensión, no un `*RequestDto`.
- `data/repository/soat_repository_impl.dart` — `getSoat` mapea **404 → `Right(null)`** (= "sin documento"); `saveSoat`/`deleteSoat` envueltos en `executeService`.
- `data/service/soat_service.dart` (+ `.g.dart`) — Retrofit `@singleton`: `GET/POST/DELETE {vehicles}/{vehicleId}/soat`. POST recibe `Map<String,dynamic>`.
- `data/parser/` — `soat_parser`, `soat_insurer_rules`, `soat_pdf_rasterizer` (OCR, fuera de alcance).

**Presentation**
- `presentation/cubit/soat_cubit.dart` — `Cubit<ResultState<SoatModel>>`, `load`/`save`/`delete`; emite `empty` cuando no hay documento; loguea analytics. **Plantilla directa del cubit genérico parametrizado por `kind`.**
- `presentation/cubit/soat_upload_cubit.dart` — flujo de selección de imagen/PDF (OCR; no se replica).
- `presentation/pages/` — `soat_status_page.dart`, `soat_manual_capture_page.dart` + `soat_manual_capture_params.dart`.
- `presentation/scan/` — `soat_entry_flow.dart` (orquestador estático `SoatEntryFlow.start(context, vehicle)` → navega a manual capture / status), `soat_document_picker.dart`.
- `presentation/widgets/` — candidatos a genérico: `soat_validity_card`, `soat_detail_row`, `soat_document_section`, `soat_empty_state`, `soat_status_view`, `soat_data_view`, `soat_action_tile`. Específicos de OCR: `soat_autofill_banner`, `soat_not_recognized_warning`, `soat_manual_option_card`, `soat_upload_option_card`, `soat_add_document_sheet`, `soat_vehicle_options_sheet`.

### `lib/features/vehicles/` — punto de inyección del badge + DUPLICADO legacy

- **Badge/entrada en el detalle del vehículo:** `presentation/garage/widgets/vehicle_soat_card.dart`. Es un `StatefulWidget` que **llama `getIt<GetSoatUseCase>()` directo** (no usa `SoatCubit`), pinta 4 estados con `_statusColor`/`_statusLabel`, y en tap entra a `SoatEntryFlow.start` o `AppRoutes.soatStatus`. **Este es el widget al que hay que añadir el "segundo badge" RTM.** Acoplado al feature `soat/` concreto.
  - También: `vehicle_soat_section.dart`, `garage_vehicle_status_badge.dart` (este último es de mantenimientos, NO SOAT — no confundir).
- **⚠️ Duplicado legacy:** existe un **segundo `SoatModel`** en `vehicles/domain/models/soat_model.dart` (forma distinta: `startDate`/`insurer` requeridos, sin lógica de status) y un `vehicles/data/dto/soat_dto.dart`. Usados por `vehicle_repository_impl`, `vehicle_service`, `vehicle_repository` y `vehicle_form_view`/`vehicle_soat_form_slot` (SOAT capturado dentro del alta de vehículo). **Riesgo de confusión / colisión de nombres** al introducir la abstracción.
- `vehicle_model.dart` — **expone `DateTime? purchaseDate` y `int? year`** → la nota de exención <2 años es viable sin tocar backend (resuelve la pregunta abierta #3 del intake).
- Widgets de slot de documento reutilizables ya existentes: `vehicle_document_upload_slot`, `vehicle_document_icon_slot`, `vehicle_document_upload_button`.

### `lib/features/notifications/` — centro de notificaciones + deep link YA funciona

- `notification_model` / `notification_dto` exponen `payload` (Map) y derivan `route` de `payload['route']`.
- `notifications_data_view.dart` navega con `AppRouter.pushDeepLink(notification.route!)`.
- `core/services/fcm_service.dart` ya cablea deep links externos/foreground vía `route` payload → `AppRouter.pushDeepLink`. **Resuelve pregunta abierta #5: el deep-linking existe y funciona; las notifs RTM solo necesitan un `route` válido** (SOAT hoy usa `rideglory://garage`).

### Genéricos NO existentes (a crear)
- `lib/features/vehicle_documents/` → **NOT STARTED**.
- `lib/features/tecnomecanica/` → **NOT STARTED**.

---

## Dependencias (pubspec.yaml — relevantes)

- Estado: `flutter_bloc`, `bloc` (Cubit + `ResultState<T>`).
- Codegen: `freezed`, `json_serializable`, `injectable`/`get_it`, `retrofit`/`dio`. (Nota: `SoatModel` NO usa freezed — es clase pura; la abstracción debe decidir freezed vs. clase pura/mixin.)
- HTTP: `retrofit ^…`, `dio`, `dartz` (Either).
- Notifs: `firebase_messaging ^16.2.0`, `flutter_local_notifications ^18.0.1`.
- Storage/captura (solo OCR SOAT, no RTM): `firebase_storage ^13.1.0`, `image_picker ^1.2.1`, `file_picker ^11.0.2`, `pdfx ^2.9.2`.
- **Sin dependencias nuevas requeridas para RTM** (no OCR, no ML Kit).

---

## Superficie rideglory-api

Monorepo NestJS de microservicios (`api-gateway` + `*-ms` con `@MessagePattern` RPC sobre transport). MS de interés: `vehicles-ms`, `notifications-ms`; cron vive en `api-gateway`.

### `vehicles-ms` (datos SOAT — espejo a crear para RTM)
- **Prisma `model Soat`** (`vehicles-ms/prisma/schema.prisma`): `id, vehicleId @unique, policyNumber, startDate, expiryDate, insurer, documentUrl?, createdAt, updatedAt`. RTM necesita su **tabla separada `Tecnomecanica`** con campos propios (`certificateNumber`, `cdaName`, `cdaCode?`) + migración.
- `src/vehicles/soat.service.ts` — `SoatService extends PrismaClient`: `upsertSoat` (con `validateVehicleOwnership` + `parseDate` + regla `expiry > start`), `findSoatByVehicle` (`findUnique by vehicleId`), `deleteSoat` (404 si no existe), `findSoatsExpiringIn(days)` (ventana UTC día-exacto). **Plantilla directa de `TecnomecanicaService`.**
- `src/vehicles/vehicles.controller.ts` — handlers RPC: `upsertSoat`, `findSoatByVehicle`, `deleteSoat`, `findSoatsExpiringIn`, + `getVehicleById` (usado por el cron). RTM = nuevos patterns espejo (`upsertTecnomecanica`, etc.).
- `src/vehicles/dto/create-soat.dto.ts` — DTO de escritura. RTM necesita `create-tecnomecanica.dto.ts`.
- Tests: `soat.service.spec.ts` (plantilla para `tecnomecanica.service.spec.ts`).

### `api-gateway` (REST público + cron)
- `src/vehicles/vehicles.controller.ts`:
  - `POST /api/vehicles/:vehicleId/soat` → RPC `upsertSoat`
  - `GET /api/vehicles/:vehicleId/soat` → RPC `findSoatByVehicle` (retorna `soat ?? null`)
  - `DELETE /api/vehicles/:vehicleId/soat` → RPC `deleteSoat`
  - Todos con Firebase Auth guard + `ownerId` del user. RTM = 3 rutas espejo `/tecnomecanica`.
- `src/scheduler/notification-scheduler.service.ts` — `NotificationSchedulerService`:
  - 3 crons SOAT (`soatReminder30Days/7Days/DayOf`, `0 9 * * *` `America/Bogota`) → privado `sendSoatReminders(daysUntilExpiry, type)`: RPC `findSoatsExpiringIn` → `getVehicleById` → `findOneUser` → `createNotification` + `sendFcm` (mensajes por tipo, `route: 'rideglory://garage'`).
  - **El intake pide refactorizar `sendSoatReminders` → genérico `sendDocumentExpiryReminders(kind, days, notificationType)` + 3 crons RTM.** Resuelve pregunta abierta #8: el patrón RPC ya existe; RTM necesita su propio `findTecnomecanicasExpiringIn` en `vehicles-ms`.
  - Mensajes FCM hoy están hardcodeados por `type` en un `Record` — el genérico debe parametrizar copy por `kind`.

### `notifications-ms` (+ copia de tipo en gateway)
- `NotificationType` (string-union TS) declarado en **dos lugares**: `notifications-ms/src/notifications/notifications.service.ts` y `api-gateway/src/notifications/notifications.service.ts` — incluye `SOAT_30D | SOAT_7D | SOAT_DAY_OF`. RTM añade `TECNOMECANICA_30D | _7D | _DAY_OF` en **ambos archivos**. Sin cambio de modelo de datos (confirma intake).

---

## Gap analysis (vs. objetivo: paridad RTM + abstracción compartida)

| Pieza | Estado | Qué falta |
|---|---|---|
| Lógica de estado (4 estados, `daysUntilExpiry`, umbral 30d) | **partial** | Existe sólo dentro de `SoatModel`. Falta extraerla a `VehicleDocumentExpiryLogic` (mixin/helper) reutilizable. |
| Abstracción `VehicleDocumentModel` + enums `VehicleDocumentStatus/Kind` | **not started** | Crear módulo `vehicle_documents/`. Decisión pendiente (clase pura vs freezed) por reconciliar con Pattern B. |
| Cubit genérico parametrizado por `kind` | **not started** | `SoatCubit` es plantilla 1:1; generalizar sin romper analytics SOAT. |
| Widgets compartidos (validity card, badge, detail row, section header, empty state) | **partial** | Existen como `soat_*`; falta promoverlos a genéricos y reconectar SOAT (regresión cero). |
| Feature `tecnomecanica/` (pages Upload/ManualCapture/Confirmation/Status) | **not started** | Espejo fino sobre genéricos; campos `certificateNumber`/`cdaName`/`cdaCode?`. |
| 2º badge RTM en detalle del vehículo | **not started** | Hoy `vehicle_soat_card.dart` está acoplado a `soat/`. Necesita patrón para 2 badges sin acoplar `vehicles/` a ambos features (pregunta abierta #7). |
| Retrofit `TecnomecanicaService` | **not started** | Espejo de `SoatService` (GET/POST/DELETE `/tecnomecanica`). Servicios separados (no cliente unificado). |
| Nota exención <2 años | **partial → viable** | `vehicle_model.purchaseDate` ya existe; solo falta UI informativa no bloqueante. |
| Backend `Tecnomecanica` (Prisma + service + controller + DTO + RPC) | **not started** | Tabla separada + migración (local→remoto). Plantilla `soat.service.ts`. |
| Backend cron RTM + helper genérico | **partial** | Refactor `sendSoatReminders`→`sendDocumentExpiryReminders`; 3 crons RTM; `findTecnomecanicasExpiringIn`. |
| `NotificationType` RTM (gateway + ms) | **not started** | 3 valores en 2 archivos. |
| Deep link tap-notif → detalle | **implemented** | `route` payload + `AppRouter.pushDeepLink` ya funcionan; RTM solo provee `route`. |
| Strings `tecnomecanica_*` / `document_*` (ARB) | **not started** | Decisión copy genérico vs específico (pregunta abierta #4) afecta regresión SOAT. |
| Docs (`tecnomecanica.md`, update `soat.md`, `CLAUDE.md`) | **not started** | — |

---

## Patrones (a respetar)

- **Pattern B obligatorio**: DTO `extends` Model + `extension XModelExtension.toJson()`. ⚠️ `SoatModel` NO es freezed (clase pura con `copyWith`/`==` manuales); la abstracción debe elegir un esquema que no rompa la herencia DTO. El payload de escritura SOAT usa un `Map` a mano en la extensión — colisiona con la regla de memoria "API write payloads deben usar DTO `.toJson()`", a revisar por Architect.
- **`ResultState<T>` + Cubit `@injectable`** (BlocProvider en el árbol, no singleton/getIt — excepto AuthCubit). ⚠️ `vehicle_soat_card` viola esto: usa `getIt<GetSoatUseCase>()` directo en un widget. No replicar el anti-patrón para RTM.
- **404 = "sin documento"** → `Right(null)` en repo, `ResultState.empty()` en cubit. RTM hereda esta convención.
- **Un widget por archivo; no métodos que retornan Widget; usar shared/widgets/form/.** Texto oscuro sobre primario. Switch unificado.
- **Backend:** RPC `@MessagePattern` ms ↔ gateway REST con Firebase guard; `validateVehicleOwnership`; ventanas UTC día-exacto para vencimientos; cron `America/Bogota`. `NotificationType` duplicado en 2 paquetes.
- **Migración Prisma:** local primero → validación humana → remoto (regla de proyecto).
- **Analytics:** eventos `soat_*` (≤40 chars, snake_case); RTM necesitará eventos propios `tecnomecanica_*`.

---

## Implicaciones para el plan

1. **Orden forzado:** primero extraer `vehicle_documents/` y refactorizar SOAT para consumirlo (regresión cero, todos los tests SOAT pasan), y SÓLO después montar `tecnomecanica/` como espejo fino. Esto habilita el split de PRs (pregunta abierta #6: corte refactor-SOAT vs corte-RTM).
2. **Limpiar el duplicado `SoatModel`/`SoatDto` en `vehicles/`** (o aislarlo) antes de introducir la abstracción, para evitar colisión de nombres y confusión sobre cuál es la fuente de verdad. Decisión de Architect.
3. **El badge es el punto de acoplamiento crítico:** `vehicle_soat_card` está hoy en `vehicles/` y acoplado a `soat/`; el 2º badge RTM exige un patrón (widget genérico parametrizado por `kind` + un usecase genérico) que evite que `vehicles/` dependa de dos features concretos. Resolver pregunta abierta #7 en arquitectura.
4. **Riesgo Pattern-B + no-freezed:** reconciliar `SoatModel implements VehicleDocumentModel` con DTO-extends-Model y el `.toRequestJson()` manual es el punto técnico más delicado. Decidir clase-base-abstracta vs mixin de lógica + interfaz, y si el payload de escritura migra a `.toJson()` de un DTO de request.
5. **Backend es de bajo riesgo / alta plantilla:** `Tecnomecanica` es copia mecánica de `Soat` (tabla separada por decisión del PRD) + helper de cron genérico + 6 valores de `NotificationType` en 2 archivos. Lo único con fricción operativa es la migración Prisma (local→humano→remoto) y que `NotificationType` vive duplicado. Deep-linking ya resuelto: no es trabajo nuevo.

---

## Bullets clave (resumen)

- **SOAT está completo y es plantilla 1:1** (model con lógica de status, cubit `ResultState`, repo 404→null, Retrofit GET/POST/DELETE, 3 crons backend). RTM es mayormente espejo mecánico; `vehicle_documents/` y `tecnomecanica/` están **not started**.
- **Hay un `SoatModel`/`SoatDto` DUPLICADO en `vehicles/`** (forma distinta, sin lógica de status) usado por el alta de vehículo — riesgo de colisión al introducir la abstracción; debe aislarse/limpiarse primero.
- **El 2º badge RTM es el punto de acoplamiento crítico:** `vehicle_soat_card.dart` vive en `vehicles/`, llama `getIt<GetSoatUseCase>()` directo (anti-patrón) y está atado a `soat/`. La abstracción debe permitir N badges sin acoplar `vehicles/` a features concretos.
- **Dos preguntas abiertas del intake quedan resueltas por el scan:** `purchaseDate` SÍ existe en `VehicleModel` (nota de exención viable sin backend, #3); deep-linking de notificaciones YA funciona (`route` payload + `pushDeepLink`, #5).
- **Riesgo técnico #1:** reconciliar `SoatModel implements VehicleDocumentModel` con Pattern B (DTO extends Model) dado que `SoatModel` es clase pura no-freezed y su payload de escritura es un `Map` manual (choca con la regla "write payloads via DTO `.toJson()`"). Decisión de Architect.
