# Fase 3 — Registrar, ver, editar y borrar la RTM desde la app

> **Slug:** `tecnomecanica-rtm` · **Fase:** 3 · **Generado:** 2026-06-04T13:18:05Z
> **Rol que escribe:** Tech Lead / PO · **Nivel rg-exec:** `normal`
> **Depende de:** Fase 1 (abstracción `vehicle_documents/` + refactor SOAT), Fase 2 (backend RTM en `rideglory-api`).
> **PR:** #3 (RTM front + notifs; comparte corte con Fases 4–5).
> **Insumos:** `05-sintesis.md` (ADR-A..F, criterios Fase 3), `01-scan.md` (inventario SOAT como plantilla 1:1), `03-architect-review.md` (contratos + decisiones).

---

## Objetivo

El conductor captura **manualmente** los datos de su Revisión Técnico-Mecánica (RTM / tecnomecánica) de un vehículo, los **guarda**, los **consulta**, los **edita** y los **borra**; ve el **estado** del documento (sin documento / vigente / por vencer / vencido) y la **fecha de vencimiento**. Todo el flujo es espejo fino del SOAT pero **sin OCR** y montado sobre los genéricos limpios extraídos en la Fase 1.

Valor entregado: paridad funcional de captura/consulta/edición/borrado de RTM respecto a SOAT, cumpliendo Clean Architecture, Pattern B y la regla de "write payloads vía DTO `.toJson()`".

---

## Alcance (entra / no entra)

### Entra
- Feature nuevo `lib/features/tecnomecanica/` con sus tres capas (domain / data / presentation).
- `TecnomecanicaModel with VehicleDocumentExpiry implements VehicleDocumentModel` (mixin + interfaz de Fase 1).
- `TecnomecanicaDto extends TecnomecanicaModel` (Pattern B) + `CreateTecnomecanicaRequestDto` con `.toJson()` (payload de escritura vía DTO, **nunca** `Map` a mano).
- `TecnomecanicaService` Retrofit separado: `GET/POST/DELETE /api/vehicles/:vehicleId/tecnomecanica`. `404 → Right(null) → ResultState.empty()`.
- `TecnomecanicaRepository` (interfaz) + `TecnomecanicaRepositoryImpl`.
- Use cases: `GetTecnomecanicaUseCase`, `SaveTecnomecanicaUseCase`, `DeleteTecnomecanicaUseCase`. **No** hay `ScanTecnomecanicaUseCase` ni `ParseTecnomecanicaTextUseCase` (sin OCR).
- `TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel>` (ADR-C), con `ResultState`, `empty` en 404, hook de analytics propio.
- Páginas: `TecnomecanicaStatusPage` (ver estado + acciones editar/borrar) y `TecnomecanicaManualCapturePage` (formulario de captura/edición). Orquestador de entrada `TecnomecanicaEntryFlow.start(context, vehicle)`.
- Rutas go_router nuevas: `/tecnomecanica/status` y `/tecnomecanica/manual-capture`.
- Formulario con campos: `certificateNumber` (requerido), `cdaName` (requerido), `cdaCode` (opcional), `startDate` (opcional), `expiryDate` (**requerido**), `documentUrl` (opcional, captura manual de URL si aplica — sin uploader OCR).
- Editar una RTM existente (precargar el formulario con los datos actuales) y borrarla (con `ConfirmationDialog`).
- **Nota informativa de exención <2 años** como **info chip no bloqueante** (nunca error ni gate de guardado): si `vehicle.purchaseDate != null && now.difference(purchaseDate) < 2 años` → mostrar nota; fallback a `vehicle.year` si `purchaseDate` es null.
- Strings `tecnomecanica_*` nuevas en `lib/l10n/app_es.arb` (claves SOAT intactas). **Copy legal propio de RTM vencida**, no el literal del SOAT.
- Eventos analytics `tecnomecanica_*` (snake_case, ≤40 chars), claves propias (no reusar las de SOAT).
- Registro DI (`@injectable` cubit/use cases/repo, `@singleton` service) + code-gen (`build_runner`).

### No entra
- **Nada de OCR**: sin `autofill_banner`, sin `scan overlay` (`Stack` de cámara), sin "no reconocido", sin `ScanSoatUseCase`/equivalente, sin `image_picker`/`file_picker`/`pdfx`/ML Kit, sin `TecnomecanicaUploadCubit`.
- El **segundo badge** RTM en el detalle del vehículo → **Fase 4** (`VehicleDocumentCard` genérico). En Fase 3 la entrada al flujo es vía `TecnomecanicaEntryFlow.start` / rutas, no vía badge en `vehicles/`.
- **Backend** (`rideglory-api`): contrato, migración Prisma, RPC, controller → **Fase 2** (ya cerrada). Esta fase consume el contrato fijado.
- **Recordatorios push / notificaciones** RTM → **Fase 5**.
- Cualquier cambio en el feature SOAT más allá de **consumir** los genéricos ya extraídos en Fase 1 (esta fase no toca `soat/`).
- Promover/crear genéricos en `vehicle_documents/`: ya existen desde Fase 1; aquí solo se **consumen**.

---

## Que se debe hacer (pasos concretos y ordenados)

1. **Confirmar la base de Fase 1 disponible.** Verificar que existen `VehicleDocumentModel` (abstract), `VehicleDocumentExpiry` (mixin), `VehicleDocumentStatus`/`VehicleDocumentKind` (enums) y `VehicleDocumentCubit<T>` en `lib/features/vehicle_documents/`, y los widgets genéricos puros (`validity_card`, `detail_row`, `section_header`, `empty_state`, `status_view`, `data_view`). Si falta algo, es bloqueo de dependencia (no improvisar genéricos aquí).

2. **Domain — modelo.** Crear `TecnomecanicaModel` (clase pura, **no freezed**, espejo de `SoatModel`): campos `vehicleId`, `certificateNumber`, `cdaName`, `cdaCode?`, `startDate?`, `expiryDate` (**non-null**), `documentUrl?`, `createdAt?`, `updatedAt?`. `with VehicleDocumentExpiry implements VehicleDocumentModel`; expone `expiryDate`, `vehicleId`, `kind => VehicleDocumentKind.tecnomecanica`. `copyWith`, `==`/`hashCode` manuales. La lógica de `status`/`daysUntilExpiry` la aporta el mixin (no reimplementar).

3. **Domain — repositorio + use cases.** Crear `TecnomecanicaRepository` (interfaz: `getTecnomecanica(vehicleId)`, `saveTecnomecanica({vehicleId, tecnomecanica})`, `deleteTecnomecanica(vehicleId)`, todos `Either<DomainException, …>`). Crear los tres use cases (`Get`/`Save`/`Delete`), espejo de los SOAT, sin los de OCR.

4. **Data — DTO + request DTO (Pattern B).** Crear `TecnomecanicaDto extends TecnomecanicaModel` con `fromJson` generado y `extension TecnomecanicaModelExtension.toJson()` (companion). Crear `CreateTecnomecanicaRequestDto` (request-only) con `.toJson()` que serializa el payload POST omitiendo nulos. **El payload de escritura se construye con `.toJson()` del DTO, nunca con un `Map<String,dynamic>` a mano** (corrige la deuda que SOAT tiene en `toRequestJson()`). Usar `apiJsonDateTimeConverters` como SOAT para fechas ISO.

5. **Data — service Retrofit.** Crear `TecnomecanicaService` (`@singleton`) con `@GET/@POST/@DELETE '{vehicles}/{vehicleId}/tecnomecanica'`. El POST recibe el `Map` resultante de `CreateTecnomecanicaRequestDto.toJson()`. Generar `.g.dart`.

6. **Data — repository impl.** Crear `TecnomecanicaRepositoryImpl` (`@Injectable(as: TecnomecanicaRepository)`): `getTecnomecanica` mapea **404 → `Right(null)`**; `save`/`delete` envueltos en `executeService` (mismos mapeos de error que SOAT, mensajes en español). Sin Firebase Storage (no hay upload de imagen/PDF).

7. **Presentation — cubit.** Crear `TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel>` (`@injectable`): `load`/`save`/`delete` heredando la base de Fase 1; emite `ResultState.empty()` en 404; loguea eventos `tecnomecanica_*` propios vía el hook de analytics de la base. Conservar `ResultState<TecnomecanicaModel>` como tipo concreto.

8. **Presentation — params + entry flow + rutas.** Crear `TecnomecanicaManualCaptureParams`, `TecnomecanicaEntryFlow.start(context, vehicle)` (orquestador estático que decide a qué página navegar según haya o no documento), y registrar `AppRoutes.tecnomecanicaStatus` (`/tecnomecanica/status`) y `AppRoutes.tecnomecanicaManualCapture` (`/tecnomecanica/manual-capture`) en `app_routes.dart` + `app_router.dart`, espejo de las rutas SOAT (líneas ~372–381).

9. **Presentation — páginas y widgets (un widget por archivo).** Crear:
   - `TecnomecanicaStatusPage`: consume `TecnomecanicaCubit`, pinta loading/empty/data/error con los **genéricos** (`status_view`, `data_view`, `validity_card`, `detail_row`, `empty_state`) parametrizados con copy RTM; ofrece acciones **editar** (navega a manual-capture con datos precargados) y **borrar** (`ConfirmationDialog` → `cubit.delete`). Copy legal propio de RTM vencida vía genérico parametrizado.
   - `TecnomecanicaManualCapturePage`: formulario con `AppTextField`/`AppDatePicker`/`AppButton` de `shared/widgets/form/`. Validación: `certificateNumber`, `cdaName`, `expiryDate` requeridos; resto opcional. En "guardar" construye `CreateTecnomecanicaRequestDto` y llama `cubit.save`. Soporta modo **crear** y **editar** (precarga desde params).
   - `TecnomecanicaExemptionNotice` (o nombre equivalente): **info chip no bloqueante** que aparece cuando el vehículo tiene <2 años (por `purchaseDate`, fallback `year`). Su propia clase widget, su propio archivo. Nunca bloquea el botón de guardar.
   - Cada pieza de Uia (header, fila de detalle, tarjeta de validez, acción) es su **propia clase widget** o reusa el genérico de Fase 1. **Cero métodos `Widget _buildX()`.**

10. **Strings.** Añadir claves `tecnomecanica_*` en `app_es.arb`: título de pantalla, labels de campos (`tecnomecanica_certificateNumber`, `tecnomecanica_cdaName`, `tecnomecanica_cdaCode`, `tecnomecanica_startDate`, `tecnomecanica_expiryDate`), estados (vigente/por vencer/vencido/sin documento), **copy legal propio de RTM vencida**, copy de la nota de exención, labels de botones (editar, borrar, guardar). **Cero literales hardcodeados.** No tocar claves SOAT.

11. **Analytics.** Añadir constantes `tecnomecanica_*` en `analytics_events.dart` (y params si aplica en `analytics_params.dart`), snake_case, **≤40 chars** cada una. Mínimo: vista de estado, guardado manual, borrado (espejo de `soat_status_viewed`/`soat_manual_saved`, con claves propias — p. ej. `tecnomecanica_status_viewed`, `tecnomecanica_manual_saved`, `tecnomecanica_deleted`). Verificar longitud de cada string.

12. **DI + code-gen.** Marcar anotaciones (`@injectable`/`@singleton`/`@Injectable(as:)`), ejecutar `dart run build_runner build --delete-conflicting-outputs` para `TecnomecanicaDto.g.dart`, `TecnomecanicaService.g.dart` y el grafo DI. **Sin dependencias nuevas.**

13. **Verificación.** `dart analyze` sin nuevos warnings; `dart format lib/`; widget tests de las páginas y test unit del cubit (ver §Pruebas).

---

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

> La estructura espeja `lib/features/soat/` **menos** todo lo de OCR (`scan/`, `parser/`, `*_upload_cubit`, `*_autofill_*`, `*_not_recognized_*`, `*_option_card`, `*_picker`).

### Crear — domain
- `lib/features/tecnomecanica/domain/models/tecnomecanica_model.dart` — modelo puro `with VehicleDocumentExpiry implements VehicleDocumentModel`.
- `lib/features/tecnomecanica/domain/repository/tecnomecanica_repository.dart` — interfaz get/save/delete.
- `lib/features/tecnomecanica/domain/usecases/get_tecnomecanica_usecase.dart` — `Either<…, TecnomecanicaModel?>`.
- `lib/features/tecnomecanica/domain/usecases/save_tecnomecanica_usecase.dart` — `{vehicleId, tecnomecanica}`.
- `lib/features/tecnomecanica/domain/usecases/delete_tecnomecanica_usecase.dart` — borrado por `vehicleId`.

### Crear — data
- `lib/features/tecnomecanica/data/dto/tecnomecanica_dto.dart` — `TecnomecanicaDto extends TecnomecanicaModel` + `extension …toJson()` (Pattern B).
- `lib/features/tecnomecanica/data/dto/create_tecnomecanica_request_dto.dart` — request-only DTO con `.toJson()` (payload POST, sin `Map` a mano).
- `lib/features/tecnomecanica/data/service/tecnomecanica_service.dart` — Retrofit `@singleton` GET/POST/DELETE `/tecnomecanica`.
- `lib/features/tecnomecanica/data/repository/tecnomecanica_repository_impl.dart` — `@Injectable(as: …)`; 404→Right(null); `executeService`.

### Crear — presentation
- `lib/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit.dart` — `extends VehicleDocumentCubit<TecnomecanicaModel>`, `ResultState`, empty en 404, analytics propio.
- `lib/features/tecnomecanica/presentation/pages/tecnomecanica_status_page.dart` — ver estado + acciones editar/borrar.
- `lib/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_page.dart` — formulario crear/editar.
- `lib/features/tecnomecanica/presentation/pages/tecnomecanica_manual_capture_params.dart` — params de navegación (vehicle + documento a editar).
- `lib/features/tecnomecanica/presentation/flow/tecnomecanica_entry_flow.dart` — `TecnomecanicaEntryFlow.start(context, vehicle)`.
- `lib/features/tecnomecanica/presentation/widgets/tecnomecanica_exemption_notice.dart` — info chip no bloqueante <2 años.
- `lib/features/tecnomecanica/presentation/widgets/` — widgets propios adicionales que no sean genéricos de Fase 1 (cada uno su archivo; reusar lo genérico siempre que exista).

### Modificar
- `lib/l10n/app_es.arb` — añadir claves `tecnomecanica_*` (SOAT intactas; copy legal propio de RTM vencida).
- `lib/core/services/analytics/analytics_events.dart` — añadir constantes `tecnomecanica_*` (≤40 chars).
- `lib/core/services/analytics/analytics_params.dart` — params nuevos solo si el evento RTM lo requiere.
- `lib/shared/router/app_routes.dart` — `tecnomecanicaStatus`, `tecnomecanicaManualCapture`.
- `lib/shared/router/app_router.dart` — registrar las 2 rutas RTM (espejo de las SOAT ~líneas 372–381).

### Generados (no editar a mano)
- `lib/features/tecnomecanica/data/dto/tecnomecanica_dto.g.dart`
- `lib/features/tecnomecanica/data/service/tecnomecanica_service.g.dart`
- Salida DI de `injection.config.dart` (regenerada por `build_runner`).

---

## Contratos / API rideglory-api (o "ninguno")

**Esta fase NO modifica el contrato — lo consume.** El contrato fue fijado en la Fase 2 (`03-architect-review.md` §Contratos):

- `POST /api/vehicles/:vehicleId/tecnomecanica` — body = `CreateTecnomecanicaRequestDto.toJson()`; éxito `200 TecnomecanicaResponse`; errores `400` (fechas inválidas / `expiry<=start` / validación), `403` (no dueño), `404` (vehículo no existe).
- `GET /api/vehicles/:vehicleId/tecnomecanica` — éxito `200 TecnomecanicaResponse`; **`404` cuando no existe documento** → el cliente lo mapea a `Right(null)` → `ResultState.empty()`.
- `DELETE /api/vehicles/:vehicleId/tecnomecanica` — éxito `200 { success: true }`; `404` si no hay RTM, `403` si no es dueño.

**Campos del payload (deben coincidir con el validador NestJS de Fase 2):** `certificateNumber` (requerido), `cdaName` (requerido), `cdaCode?`, `startDate?`, `expiryDate` (**requerido, non-null**), `documentUrl?`. La UI **debe validar `certificateNumber`, `cdaName` y `expiryDate` antes del POST** para no replicar el mismatch latente de SOAT (donde el server exige campos que el cliente omite). `startDate` es opcional en UI y en validador.

Mientras la migración remota de Fase 2 se valida, el front puede desarrollarse contra el contrato/mock (R6).

---

## Cambios de datos / migraciones (o "ninguno")

**Ninguno.** Toda la persistencia (tabla `Tecnomecanica`, migración Prisma) es de la Fase 2. Esta fase es 100% Flutter y consume la API. La nota de exención <2 años es **solo-UI**, derivada de `VehicleModel.purchaseDate` (`DateTime?`) / `VehicleModel.year` (`int?`) ya existentes — **no toca backend**.

---

## Criterios de aceptacion (numerados, observables, testeables)

1. **Payload vía DTO.** El cuerpo del `POST /tecnomecanica` se construye con `CreateTecnomecanicaRequestDto.toJson()`. Grep en `tecnomecanica/` no encuentra ningún `<String, dynamic>{...}` construido a mano como body de escritura.
2. **Pattern B.** `TecnomecanicaModel implements VehicleDocumentModel` (con `VehicleDocumentExpiry`) y `TecnomecanicaDto extends TecnomecanicaModel`. `build_runner` genera `tecnomecanica_dto.g.dart` sin conflictos.
3. **Cubit sobre la base genérica.** `TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel>`, usa `ResultState<TecnomecanicaModel>` y emite `ResultState.empty()` cuando el GET responde 404 (verificable con un repo fake que devuelve `Right(null)`).
4. **Registrar.** Desde la pantalla de captura, con campos válidos, al guardar se hace POST y la `StatusPage` queda en `ResultState.data` mostrando los datos guardados.
5. **Ver.** Al entrar con un vehículo que tiene RTM, la `StatusPage` muestra estado (vigente/por vencer/vencido) y fecha de vencimiento derivados del mixin `VehicleDocumentExpiry` (umbral 30 días, `<0 → vencido`).
6. **Editar.** Desde la `StatusPage` de una RTM existente, "Editar" abre el formulario **precargado** con los datos actuales; al guardar, el documento se actualiza (upsert) y la vista refleja los nuevos valores.
7. **Borrar.** Desde la `StatusPage`, "Borrar" muestra `ConfirmationDialog`; al confirmar se hace DELETE y la vista pasa a `ResultState.empty()` (estado "sin documento").
8. **Analytics.** Existen constantes `tecnomecanica_*` en snake_case, **cada una ≤40 chars** (verificable por longitud), distintas de las claves SOAT. Se emite al menos: ver estado, guardar manual, borrar.
9. **Exención no bloqueante.** Para un vehículo con `purchaseDate` < 2 años (o `year` equivalente como fallback), aparece el info chip de exención; el botón "Guardar" **sigue habilitado** y permite guardar. No se emite error ni se bloquea por la exención.
10. **Sin OCR.** No existe en `tecnomecanica/` ningún `autofill_banner`, `scan`/`Stack` de cámara, "no reconocido", `*UploadCubit`, ni import de `image_picker`/`file_picker`/`pdfx`/ML Kit (verificable por grep).
11. **Copy legal propio.** El texto de "RTM vencida" en `app_es.arb` es propio de RTM (no idéntico al literal de SOAT). Claves SOAT no modificadas.
12. **Clean Architecture + estándares.** `domain/` sin Flutter/HTTP; `data/` sin `BuildContext`/widgets; `presentation/` sin HTTP directo ni DTO expuesto. Un widget por archivo; **cero** `Widget _buildX()`. Strings vía `context.l10n.<key>`. Texto/iconos oscuros sobre primario donde aplique. `dart analyze` **sin nuevos warnings**.

---

## Pruebas (unitarias/widget/integracion)

**Unitarias (cubit / lógica):**
- `tecnomecanica_cubit_test.dart`: con repo fake — (a) GET 404 (`Right(null)`) → `ResultState.empty()`; (b) GET con dato → `ResultState.data`; (c) `save` exitoso → `data`; (d) `save` error → `ResultState.error`; (e) `delete` exitoso → `empty`. Verifica que se invoca el hook de analytics correspondiente.
- Estado derivado: a través del mixin `VehicleDocumentExpiry` sobre `TecnomecanicaModel` — `expiryDate` futura >30d → `valid`; entre 0 y 30d → `expiringSoon`; pasada → `expired`. (El test exhaustivo de los 4 estados a nivel mixin con casos SOAT+RTM es de la Fase 6; aquí basta cubrir el caso RTM concreto.)

**Widget:**
- `tecnomecanica_status_page_test.dart`: renderiza loading/empty/data/error con cubit fake; verifica que "Editar" navega a manual-capture y "Borrar" abre `ConfirmationDialog`.
- `tecnomecanica_manual_capture_page_test.dart`: validación de campos requeridos (`certificateNumber`, `cdaName`, `expiryDate`); guardar deshabilitado/error si faltan; con el info chip de exención presente, "Guardar" sigue habilitado.
- `tecnomecanica_exemption_notice_test.dart`: aparece para vehículo <2 años (por `purchaseDate` y por fallback `year`), ausente para vehículo ≥2 años; nunca bloquea.

**Integración / regresión:**
- `flutter test` 100% verde. **La suite SOAT debe seguir verde sin editar su acceptance** (esta fase no toca `soat/`; si un test SOAT cambia, es regresión).
- `dart analyze` sin nuevos warnings; `dart run build_runner build` sin conflictos.

---

## Riesgos y mitigaciones

| # | Riesgo | Sev. | Mitigación |
|---|--------|------|------------|
| R3 | Mismatch de contrato required/optional (server exige campos que la UI omite → 400 silencioso). | Media | UI valida `certificateNumber`, `cdaName`, `expiryDate` antes del POST; `startDate` opcional en ambos lados. Alinear con el `CreateTecnomecanicaDto` de Fase 2. No replicar el patrón latente de SOAT. |
| Payload | Tentación de construir el body POST con `Map` a mano (como SOAT). | Media | Criterio 1: body vía `CreateTecnomecanicaRequestDto.toJson()`. Grep de control. |
| Fechas/estado | Lógica de vencimiento mal mapeada (umbral 30d, `<0` vencido, zona horaria). | Media | Reusar el mixin `VehicleDocumentExpiry` de Fase 1 (no reimplementar); tests de los estados RTM. |
| R6 | Migración remota de Fase 2 no lista bloquea pruebas contra entorno real. | Baja-Media | Desarrollar contra contrato/mock; el contrato ya está fijado. |
| OCR scope creep | Arrastrar piezas OCR del SOAT al copiar. | Media | Lista explícita de "No entra" + criterio 10 (grep de OCR). |
| Acoplamiento Fase 4 | Adelantar el badge en `vehicles/`. | Baja | El badge es Fase 4; aquí la entrada es vía `EntryFlow`/rutas, no por `VehicleDocumentCard`. |
| Strings/analytics | Romper claves SOAT o exceder 40 chars en eventos. | Baja | Claves `tecnomecanica_*` en paralelo; verificación de longitud por evento. |

---

## Dependencias (fases prerequisito y por que)

- **Fase 1 — Abstracción `vehicle_documents/` + refactor SOAT (bloqueante).** Esta fase **consume** `VehicleDocumentModel`, `VehicleDocumentExpiry`, `VehicleDocumentStatus`/`Kind`, `VehicleDocumentCubit<T>` y los widgets genéricos puros. Sin ellos no hay base sobre la cual montar el espejo fino y se reimplementaría lógica/UI (anti-objetivo). Si los genéricos no están, es bloqueo duro: no se improvisan aquí.
- **Fase 2 — Backend RTM en `rideglory-api` (bloqueante para integración real).** Fija el contrato (`CreateTecnomecanicaDto`, rutas REST, `404` sin documento, `expiry>start` server-side) y la tabla `Tecnomecanica`. El front puede codificarse contra el contrato/mock antes de la migración remota, pero la fase no se valida end-to-end sin la API. La regla `404 → empty` depende de que el GET de Fase 2 responda 404 (no `200 {data:null}`).

---

## Ejecucion recomendada (nivel rg-exec: normal)

**Por que `normal`:** Feature de UI acotada a una sola área (`lib/features/tecnomecanica/`), espejo fino sobre los genéricos ya probados en Fase 1 y consumiendo un contrato ya fijado en Fase 2. El riesgo es **medio** y bien localizado: lógica de fechas/estados (mitigada al reusar el mixin de Fase 1), payload de escritura vía DTO, y validación required/optional alineada con el backend. **No hay migraciones ni cambios de contrato propios** de esta fase, ni cross-cutting en producción, ni código difícil de revertir. La cadena Architect + Build + QA + 2 rondas + Tech Lead cubre ese riesgo de sobra; subir a `full` sería sobreingeniería (no hay blast radius estructural como en Fase 1, ni migración/crons de producción como en Fases 2/5). Bajar a `lite` dejaría sin red la lógica de estados y el contrato de escritura, que sí ameritan QA real.
