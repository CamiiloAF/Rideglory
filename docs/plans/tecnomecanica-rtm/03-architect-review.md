# 03 — Architect Review — Tecnomecánica (RTM)

**Slug:** `tecnomecanica-rtm`
**Generado:** 2026-06-04T13:07:08Z
**Rol:** Architect (validación de viabilidad, contratos, riesgos, ajustes)
**Insumos:** `00-intake.md`, `01-scan.md`, `02-po-proposal.md` + verificación directa de código (Flutter + rideglory-api).

> Sesión de planeación. No se modifica código. **Valido el stack existente, no elijo desde cero.** SOAT es plantilla 1:1 y línea base de regresión cero. Veredicto: **ok_con_ajustes**.

---

## Validacion por fase

### Fase 1 — Abstracción `vehicle_documents/` + refactor SOAT (regresión cero) — **Complejidad: ALTA**

Viable, pero es la fase de mayor riesgo arquitectónico de todo el plan. No es trabajo nuevo de UI: es un refactor estructural con criterio de regresión cero.

**Verificado:**
- `SoatModel` (`lib/features/soat/domain/models/soat_model.dart`) es **clase pura no-freezed**, con la lógica de estado dentro (`status`, `daysUntilExpiry`, umbral `<= 30`, `< 0` → vencido). `expiryDate` es **non-null**; resto opcional.
- `SoatDto extends SoatModel` (Pattern B) + `extension SoatModelToRequest.toRequestJson()` que construye un `Map` a mano omitiendo nulos.
- **Duplicado confirmado:** `lib/features/vehicles/domain/models/soat_model.dart` es un **segundo `SoatModel` con forma distinta** (`startDate`/`insurer` **requeridos**, sin lógica de status, sin `createdAt/updatedAt`). Lo consumen `vehicle_soat_form_slot.dart`, `vehicle_repository_impl`, `vehicle_service`. **Colisión de nombre real:** dos clases `SoatModel` en namespaces distintos.

**Decisiones de Architect (bloquean la fase):**
- **ADR-A — Forma de la abstracción:** NO convertir `SoatModel` a freezed (rompería Pattern B `DTO extends Model` + el `==`/`copyWith` manual y los consumidores). Se extrae la **lógica** a un `mixin VehicleDocumentExpiry` (getters `daysUntilExpiry`, `status` sobre un `DateTime get expiryDate` abstracto) + una **interfaz `abstract class VehicleDocumentModel`** (contrato: `expiryDate`, `vehicleId`, `kind`). `SoatModel with VehicleDocumentExpiry implements VehicleDocumentModel`. Esto preserva la firma pública de `SoatModel` (mitiga riesgo de consumidores) y mantiene `SoatDto extends SoatModel` intacto. El enum genérico `VehicleDocumentStatus { none, valid, expiringSoon, expired }` reemplaza a `SoatStatus` con un alias/`typedef` o mapeo 1:1 para no tocar analytics (`soat.status.name`).
- **ADR-B — Payload de escritura:** **NO migrar a un DTO de request en esta fase.** El `toRequestJson()` manual es legacy y la regla de memoria "write payloads vía DTO `.toJson()`" aplica a código nuevo; tocarlo aquí amplía el blast radius del refactor sin valor para el usuario. Se documenta como deuda. RTM (fase 3) **sí** nace con un `CreateTecnomecanicaRequestDto` (Pattern: request-only DTO con `.toJson()`), cumpliendo la regla en lo nuevo sin reabrir SOAT.
- **ADR-C — Cubit genérico:** NO forzar un `Cubit<ResultState<VehicleDocumentModel>>` parametrizado que obligue a SOAT a cambiar su tipo `ResultState<SoatModel>` (rompería todos los `BlocBuilder<SoatCubit, ResultState<SoatModel>>` y los tests). En su lugar, extraer una **clase base genérica abstracta** `VehicleDocumentCubit<T extends VehicleDocumentModel>` con `load/save/delete` + hook de analytics; `SoatCubit extends VehicleDocumentCubit<SoatModel>` conservando su tipo concreto. Los `BlocBuilder` de SOAT no cambian.
- **ADR-D — Widgets compartidos:** promover a `lib/features/vehicle_documents/presentation/widgets/` los **genéricos puros** (`validity_card`, `detail_row`, `section_header`, `empty_state`, `status_view`, `data_view`) parametrizados por modelo/copy. Los OCR-específicos (`autofill_banner`, `upload_option_card`, etc.) **se quedan en `soat/`**. SOAT reapunta sus imports.
- **ADR-E — Duplicado `vehicles/SoatModel`:** **aislar, no migrar a la abstracción en fase 1.** Es la forma de *captura-en-alta-de-vehículo* (otro caso de uso). Renombrar a `VehicleSoatFormData` (o moverlo a `vehicles/presentation/form/`) para eliminar la colisión de nombre. NO se le añade lógica de status (no la necesita). Decisión: esta clase **no** implementa `VehicleDocumentModel`.

**Criterio de cierre:** `flutter test` (suite SOAT) verde sin tocar acceptance; `dart analyze` sin nuevos warnings; `dart run build_runner build` sin conflictos (los `.g.dart` de DTO no cambian de forma).

### Fase 2 — Backend: persistencia y consulta RTM — **Complejidad: BAJA-MEDIA**

Viable, alta plantilla. `soat.service.ts` es copia mecánica. La única fricción real es operativa (migración Prisma) y de contrato (campos required/optional).

**Verificado:**
- `SoatService extends PrismaClient` con `upsertSoat` (`validateVehicleOwnership` + `parseDate` + `expiry > start`), `findSoatByVehicle`, `deleteSoat` (404), `findSoatsExpiringIn` (ventana UTC día-exacto). Plantilla directa de `TecnomecanicaService`.
- **Hallazgo de contrato:** `CreateSoatDto` exige `startDate` y `insurer` **non-null** (`@IsDateString` sin `@IsOptional`, `@IsNotEmpty`), pero el Flutter `toRequestJson()` los **omite cuando son null**. Para SOAT funciona porque la UI los hace obligatorios. **Para RTM hay que fijar el contrato explícitamente** (ver §Contratos): qué campos son required server-side y client-side deben coincidir, o el upsert falla con 400 silencioso.

**Decisión:** tabla **separada** `Tecnomecanica` (no tabla genérica con discriminador `kind`) — alineado con la decisión del PRD y con servicios Retrofit separados. Migración Prisma local → validación humana → remoto (regla de proyecto). La fase 2 **no se cierra** hasta la validación humana local.

### Fase 3 — Registrar y ver RTM desde la app — **Complejidad: MEDIA**

Viable. Espejo fino sobre los genéricos de fase 1. Depende del contrato de fase 2 (puede desarrollarse contra contrato/mock mientras se valida la migración remota).

**Verificado/decisiones:**
- `TecnomecanicaModel with VehicleDocumentExpiry implements VehicleDocumentModel`; `TecnomecanicaDto extends TecnomecanicaModel` (Pattern B). `TecnomecanicaService` Retrofit separado (GET/POST/DELETE `/tecnomecanica`), 404 → `Right(null)` → `ResultState.empty()`.
- `TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel>` (ADR-C). Eventos `tecnomecanica_*` (≤40 chars, snake_case) propios — no reusar claves SOAT.
- **Nota de exención <2 años:** viable solo-UI. `VehicleModel` expone `purchaseDate` (`DateTime?`) y `year` (`int?`). Regla: si `purchaseDate != null && now.difference(purchaseDate) < 2 años` → banner informativo **no bloqueante**. Fallback con `year` si `purchaseDate` es null. No bloquea el guardado.
- **Strings (pregunta abierta #4):** **mantener claves SOAT existentes intactas y añadir `tecnomecanica_*` en paralelo.** NO unificar a `document_status_*` en esta iteración (riesgo de regresión SOAT > valor). El copy genérico compartido en widgets se inyecta por parámetro, no por clave ARB compartida.

### Fase 4 — Doble badge en detalle del vehículo — **Complejidad: MEDIA**

Viable. Es el **punto de acoplamiento crítico** y arrastra un anti-patrón a corregir.

**Verificado:** `vehicle_soat_card.dart` es `StatefulWidget` que llama **`getIt<GetSoatUseCase>()` directo dentro del widget** (anti-patrón confirmado, líneas 38-44) con `bool _isLoading` (viola "no boolean loading flags") y dos strings hardcodeados (`'Vigente'`, `'Por vencer'`, línea 154 `'Vence …'`). Está acoplado a `soat/`.

**Decisión (ADR-F):** introducir `VehicleDocumentCard` genérico parametrizado por `kind`, alimentado por un **cubit** (no `getIt` en el widget) con `ResultState` (no `bool`). `vehicles/` muestra N badges sin acoplarse a features concretos: el card recibe un `VehicleDocumentKind` + un loader inyectado (o un cubit-por-kind provisto en el árbol). El detalle del vehículo monta **dos** instancias (SOAT + RTM). **Reescribir `vehicle_soat_card` como `VehicleDocumentCard` corrige los 3 defectos** (getIt-en-widget, bool flag, strings hardcodeados) → este trabajo es parte del valor de la fase, no solo "añadir un segundo badge".

### Fase 5 — Recordatorios push + centro de notificaciones RTM — **Complejidad: MEDIA**

Viable. El deep-linking ya funciona (verificado: `route` payload → `AppRouter.pushDeepLink`). El refactor del scheduler es el grueso.

**Verificado:** `sendSoatReminders(daysUntilExpiry, type)` con los mensajes FCM **hardcodeados en un `Record<string,…>` por `type`** (líneas 285-298) y `route: 'rideglory://garage'`. `NotificationType` es un **string-union duplicado en 2 paquetes** (`api-gateway/.../notifications.service.ts` y `notifications-ms/.../notifications.service.ts`) — confirmado, incluye `SOAT_30D|7D|DAY_OF`.

**Decisiones:**
- Refactor `sendSoatReminders` → `sendDocumentExpiryReminders(kind, days, notificationType)`: el `kind` selecciona el RPC (`findSoatsExpiringIn` vs `findTecnomecanicasExpiringIn`) y el bloque de copy. Mantener los 3 crons SOAT funcionando (regresión cero backend) + 3 crons RTM nuevos.
- 3 valores `TECNOMECANICA_30D|7D|DAY_OF` añadidos en **ambos** archivos `NotificationType` (checklist obligatorio — propenso a desincronización).
- `route` RTM: **`rideglory://garage`** (igual que SOAT). El deep-link lleva al garage/detalle; no requiere ruta nueva. (Si el PO quiere abrir directamente el detalle de la moto por id, se necesitaría una ruta `detail-by-id` — confirmar; SOAT hoy no lo hace, así que **paridad = `garage`**.)

### Fase 6 — Calidad, regresión y documentación — **Complejidad: BAJA**

Viable y necesaria. Tests unit de la lógica de estado a nivel `VehicleDocumentExpiry` (4 estados, casos SOAT **y** RTM), test del cubit base parametrizado, widgets compartidos probados una vez. Docs `tecnomecanica.md`, update `soat.md`, registrar `vehicle_documents/` en `CLAUDE.md`. **Sin objeción.**

---

## Contratos

### rideglory-api — nuevas rutas REST (api-gateway, espejo de SOAT)

| Método | Path | Auth | Request body | Success | Errores |
|--------|------|------|--------------|---------|---------|
| `POST` | `/api/vehicles/:vehicleId/tecnomecanica` | Firebase ID token | `CreateTecnomecanicaDto` (ver abajo) | `200` `TecnomecanicaResponse` | `400` (fechas inválidas / `expiry<=start` / validación), `403` (no es dueño), `404` (vehículo no existe) |
| `GET` | `/api/vehicles/:vehicleId/tecnomecanica` | Firebase ID token | — | `200` `TecnomecanicaResponse` \| `null` | `404` → cliente lo mapea a `Right(null)` → `empty` |
| `DELETE` | `/api/vehicles/:vehicleId/tecnomecanica` | Firebase ID token | — | `200` `{ success: true }` | `404` (no hay RTM), `403` |

### RPC `@MessagePattern` (vehicles-ms, espejo)

`upsertTecnomecanica`, `findTecnomecanicaByVehicle`, `deleteTecnomecanica`, `findTecnomecanicasExpiringIn` — copia mecánica de `tecnomecanica.service.ts` desde `soat.service.ts` (misma `validateVehicleOwnership`, `parseDate`, `expiry>start`, ventana UTC día-exacto).

### `CreateTecnomecanicaDto` (vehicles-ms) — **contrato a fijar explícitamente**

| Campo | Tipo | Required? | Validador NestJS | Notas |
|-------|------|-----------|------------------|-------|
| `certificateNumber` | string | **Sí** | `@IsString @IsNotEmpty` | nº del certificado RTM |
| `cdaName` | string | **Sí** | `@IsString @IsNotEmpty` | nombre del CDA, texto libre |
| `cdaCode` | string | No | `@IsString @IsOptional` | código del CDA |
| `startDate` | string ISO | **decidir** | `@IsDateString` | ver hallazgo abajo |
| `expiryDate` | string ISO | **Sí** | `@IsDateString @IsNotEmpty` | non-null garantizado cuando existe RTM |
| `documentUrl` | string | No | `@IsString @IsOptional` | sin OCR; opcional |

**Hallazgo crítico de contrato:** en SOAT, `CreateSoatDto.startDate` e `insurer` son **required** server-side, pero el Flutter `toRequestJson()` los omite si son null. Funciona solo porque la UI SOAT los obliga. **Para RTM, alinear explícitamente:** si `startDate` es opcional en la UI RTM, debe ser `@IsOptional` en el DTO; si es required, la UI debe validarlo antes del POST. **No replicar el mismatch latente de SOAT.** Recomendación: `expiryDate` required, `startDate` opcional (la app calcula estado solo desde `expiryDate`, que es non-null — igual que `SoatModel`).

### Prisma — `model Tecnomecanica` (vehicles-ms, tabla separada + migración)

Campos: `id`, `vehicleId @unique`, `certificateNumber`, `cdaName`, `cdaCode?`, `startDate?`, `expiryDate`, `documentUrl?`, `createdAt`, `updatedAt`. Relación con `Vehicle` igual que `Soat`. **Migración:** `prisma migrate dev` local → validación humana → remoto (regla de proyecto; la fase 2 no cierra hasta la validación local).

### `NotificationType` (string-union, **2 archivos**)

Añadir `'TECNOMECANICA_30D' | 'TECNOMECANICA_7D' | 'TECNOMECANICA_DAY_OF'` en:
- `api-gateway/src/notifications/notifications.service.ts`
- `notifications-ms/src/notifications/notifications.service.ts`

Sin cambio de modelo de datos en `notifications-ms`. Checklist obligatorio (desincronización es el riesgo).

### Flutter — modelos / DTOs / DI

| Nombre | Capa | Ruta | Notas |
|--------|------|------|-------|
| `VehicleDocumentModel` (abstract) + `VehicleDocumentExpiry` (mixin) | domain | `lib/features/vehicle_documents/domain/` | ADR-A; contrato `expiryDate`/`vehicleId`/`kind` + lógica de status |
| `VehicleDocumentStatus`, `VehicleDocumentKind` (enums) | domain | `lib/features/vehicle_documents/domain/` | `status` 1:1 con `SoatStatus` |
| `VehicleDocumentCubit<T>` (abstract base) | presentation | `lib/features/vehicle_documents/presentation/` | ADR-C; `SoatCubit`/`TecnomecanicaCubit` extienden |
| `TecnomecanicaModel` | domain | `lib/features/tecnomecanica/domain/models/` | `implements VehicleDocumentModel` |
| `TecnomecanicaDto extends TecnomecanicaModel` + `CreateTecnomecanicaRequestDto` | data | `lib/features/tecnomecanica/data/dto/` | Pattern B + request-DTO con `.toJson()` (ADR-B) |
| `TecnomecanicaService` (Retrofit `@singleton`) | data | `lib/features/tecnomecanica/data/service/` | GET/POST/DELETE `/tecnomecanica`, separado |
| `VehicleDocumentCard` (genérico) | presentation | `lib/features/vehicles/presentation/garage/widgets/` | ADR-F; reemplaza `vehicle_soat_card`, parametrizado por `kind`, cubit + `ResultState` |
| `VehicleSoatFormData` (renombrado) | presentation/domain | `lib/features/vehicles/` | ADR-E; elimina colisión con el `SoatModel` duplicado |

**Code-gen:** `dart run build_runner build` para `TecnomecanicaDto.g.dart` + `TecnomecanicaService.g.dart` (Retrofit) + DI (`@injectable` cubits, `@singleton` service). **Sin dependencias nuevas** (no OCR, no ML Kit, no FCM nuevo). **Sin cambios de plataforma** (Android/iOS). **Sin WebSocket.**

**l10n:** claves `tecnomecanica_*` nuevas en `app_es.arb`. Claves SOAT intactas (pregunta abierta #4 resuelta: paralelo, no unificación).

---

## Riesgos

| # | Riesgo | Severidad | Mitigación |
|---|--------|-----------|------------|
| R1 | **Refactor SOAT rompe Pattern B / consumidores** al genéricar model+cubit+widgets. | Alta | ADR-A (mixin+interfaz, no freezed) + ADR-C (base genérica, `SoatCubit` mantiene `ResultState<SoatModel>`). Firma pública de `SoatModel` intacta. Criterio duro: suite SOAT verde sin cambiar acceptance. |
| R2 | **Colisión de nombre `SoatModel`** (soat/ vs vehicles/). | Media | ADR-E: renombrar el de `vehicles/` a `VehicleSoatFormData` **antes** de introducir la abstracción. No implementa `VehicleDocumentModel`. |
| R3 | **Mismatch de contrato required/optional** (latente en SOAT: server exige `startDate`/`insurer`, cliente los omite). | Media | Fijar `CreateTecnomecanicaDto` explícitamente; alinear UI ↔ validador. Recomendación: `expiryDate` required, `startDate` opcional. No replicar el patrón latente. |
| R4 | **Anti-patrón en el badge** (`getIt` en widget + `bool _isLoading` + strings hardcodeados). | Media | ADR-F: `VehicleDocumentCard` con cubit + `ResultState`, strings ARB. Corregirlo es parte del valor de fase 4, no opcional. |
| R5 | **`NotificationType` duplicado en 2 paquetes** → desincronización. | Media | Checklist en fase 5 que toque ambos archivos + test que cubra los 3 tipos RTM. |
| R6 | **Fricción migración Prisma remota** bloquea front contra entorno real. | Baja-Media | Front fase 3 contra contrato/mock mientras se valida local. Fase 2 no cierra sin validación humana local. |
| R7 | **`route` del deep-link RTM** asumido `rideglory://garage`. Si PO quiere detalle-por-id, falta ruta. | Baja | Paridad SOAT = `garage`. Confirmar con PO si se requiere `detail-by-id`; no es bloqueante para paridad. |
| R8 | **Deuda payload manual `toRequestJson`** no migrada en SOAT. | Baja | ADR-B: aceptada como deuda documentada; RTM nace cumpliendo la regla con request-DTO. No reabrir SOAT en este alcance. |

---

## Ajustes

1. **Fase 1 — fijar las decisiones de arquitectura antes de codificar (ADR-A..E).** Mixin `VehicleDocumentExpiry` + interfaz `VehicleDocumentModel` (NO freezed), base genérica `VehicleDocumentCubit<T>` (SOAT mantiene `ResultState<SoatModel>`), promover solo widgets genéricos puros, **renombrar el `SoatModel` duplicado de `vehicles/` a `VehicleSoatFormData`** como primer paso de la fase.
2. **Fase 1/3 — payload de escritura (ADR-B):** NO migrar `SoatModel.toRequestJson()` a DTO en esta iteración (deuda documentada). RTM nace con `CreateTecnomecanicaRequestDto` + `.toJson()`, cumpliendo la regla en lo nuevo.
3. **Fase 2 — fijar el contrato `CreateTecnomecanicaDto` con required/optional explícitos** y alinear UI↔validador (recomendación: `expiryDate` required, `startDate` opcional). Documentar el mismatch latente de SOAT para no replicarlo.
4. **Fase 3 — strings en paralelo, no unificar** (`tecnomecanica_*` nuevas; claves SOAT intactas). El copy compartido en widgets se inyecta por parámetro, no por clave ARB común. Resuelve pregunta abierta #4.
5. **Fase 4 — reencuadrar como "reescritura del badge a `VehicleDocumentCard`"**, no "añadir un segundo badge". Corregir los 3 defectos (getIt-en-widget, `bool` flag, strings hardcodeados) es parte del valor, con cubit + `ResultState`.
6. **Fase 5 — confirmar `route` del deep-link RTM** con PO: paridad = `rideglory://garage`. Solo si se pide abrir el detalle por id se necesita ruta `detail-by-id` nueva.
7. **Split de PRs confirmado viable:** fase 1 = corte refactor-SOAT independiente; fases 2 (backend) y 3-5 (RTM front+notifs) = corte RTM. Fase 2 es repo separado (`rideglory-api`) → PR propio por repositorio. Umbral ~40 archivos respetado (fase 1 es la más pesada en Flutter; fase 2 es mecánica en backend).
