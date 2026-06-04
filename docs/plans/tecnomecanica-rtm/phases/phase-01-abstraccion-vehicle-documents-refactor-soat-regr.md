# Fase 1 — Abstracción vehicle_documents/ + refactor SOAT (regresión cero)

**Slug:** `tecnomecanica-rtm`
**Fase:** 1 de 6
**Generado:** 2026-06-04T13:22:47Z
**Nivel rg-exec:** `full`
**dependsOn:** [] (es la fundación; ninguna otra fase puede arrancar sin ella)
**Corte commit-able:** PR #1 (Flutter, el corte más pesado, independiente del backend)

> Sesión de planeación. No se modifica código de la app. Este archivo es la fuente de verdad ejecutable de la Fase 1. Implementa los ADR-A..F fijados en `05-sintesis.md` y validados en `03-architect-review.md`. **Criterio rector: regresión cero en SOAT.**

---

## Objetivo

El conductor ve y gestiona su SOAT **exactamente igual que hoy** (mismos 4 estados, mismo badge, mismo flujo de captura, mismas notificaciones, misma serialización), pero el código que lo soporta pasa a vivir sobre una **base reutilizable** (`lib/features/vehicle_documents/`) lista para montar un segundo documento (RTM) como capa fina. **Sin un solo cambio visible para el usuario.**

Esta fase paga la deuda estructural que el scan reveló en SOAT antes de duplicarla:
- `SoatModel` duplicado en `vehicles/` que colisiona de nombre con el `SoatModel` de `soat/` (verificado: `grep "class SoatModel" lib/` devuelve **2** resultados — `lib/features/vehicles/domain/models/soat_model.dart:1` y `lib/features/soat/domain/models/soat_model.dart:3`).
- Badge (`vehicle_soat_card.dart`) con `getIt<GetSoatUseCase>()` dentro del widget (L38) + `bool _isLoading` (L24) + literales hardcodeados (`'Vigente'` L195, `'Por vencer'` L197, `'Vence {fecha}'` L154).
- Lógica de estado (4 niveles, `daysUntilExpiry`, umbral 30d) atrapada dentro del `SoatModel` de `soat/`.

---

## Alcance (entra / no entra)

### Entra
- **ADR-E (primer paso):** renombrar el `SoatModel` **duplicado** de `vehicles/` a `VehicleSoatFormData` (elimina la colisión de nombre). NO implementa `VehicleDocumentModel`. **No toca `SoatStatus`** (ese enum vive en `soat/` y lo consumen otros features; ver "No entra").
- **ADR-A:** crear `lib/features/vehicle_documents/domain/`: `mixin VehicleDocumentExpiry` (extrae `daysUntilExpiry` + `status`), `abstract class VehicleDocumentModel` (contrato `expiryDate`/`vehicleId`/`kind`), `enum VehicleDocumentStatus { none, valid, expiringSoon, expired }`, `enum VehicleDocumentKind`. `SoatModel with VehicleDocumentExpiry implements VehicleDocumentModel`, preservando su firma pública y `SoatDto extends SoatModel` (Pattern B intacto).
- **ADR-C:** crear `abstract class VehicleDocumentCubit<T extends VehicleDocumentModel>` con `load/save/delete` + hook de analytics. `SoatCubit extends VehicleDocumentCubit<SoatModel>` conservando `Cubit<ResultState<SoatModel>>` (ningún `BlocBuilder`/test SOAT cambia).
- **ADR-D:** promover a `lib/features/vehicle_documents/presentation/widgets/` solo los **genéricos puros** (`validity_card`, `detail_row`, `section_header`, `empty_state`, `status_view`, `data_view`), parametrizados por modelo/copy inyectado por parámetro. SOAT reapunta sus imports.
- **ADR-F:** reescribir `vehicle_soat_card.dart` como `VehicleDocumentCard` genérico parametrizado por `kind`, alimentado por un cubit `@injectable` + `ResultState` (elimina `getIt` en widget y `bool _isLoading`). El contrato del genérico **soporta N badges desde el inicio** (cubit/loader parametrizado por `kind`).
- Reapuntar el **único** consumidor del card al nuevo `VehicleDocumentCard`: `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` (L59, hoy instancia `VehicleSoatCard(vehicle: vehicle)`).
- Mover **solo los 3 literales hardcodeados** del card (`'Vigente'`, `'Por vencer'`, `'Vence {fecha}'`) a `app_es.arb`, **reutilizando las claves ya existentes** (ver "Cambios de datos / l10n").
- Regenerar code-gen (`build_runner`) y l10n.

### No entra
- **`home_garage_soat_badge.dart` queda FUERA de alcance.** Es un **segundo badge SOAT** que se pinta en la tarjeta de garage del home. Verificado: es un `StatelessWidget` que recibe `VehicleModel` y lee `vehicle.soatStatus` (`SoatStatus`); **no usa `getIt`** y **no es** el card del detalle. No se toca aquí: su unificación con el genérico `VehicleDocumentCard` (o su conversión a capa fina) no es necesaria para la paridad SOAT de esta fase y ampliaría el blast radius. Se documenta como deuda conocida; el genérico "soporta N badges" se refiere al card del detalle (Fase 4 monta el segundo badge RTM ahí), **no** a este badge del home. Este widget **depende de que `SoatStatus` se preserve** (ver siguiente punto).
- **`SoatStatus` se PRESERVA, no se elimina.** El enum `SoatStatus { noSoat, valid, expiringSoon, expired }` (en `lib/features/soat/domain/models/soat_model.dart`) es consumido por un blast radius real verificado por grep: `home_garage_soat_badge.dart`, `vehicle_cubit.dart`, `app_router.dart`, `vehicle_form_docs_section.dart`, `vehicle_soat_form_slot.dart`, `soat_status_page.dart`, `soat_data_view.dart`, `soat_status_view.dart`, `vehicle_soat_card.dart`, `vehicle_soat_section.dart`, `vehicle_model.dart` (más `vehicle_dto.g.dart` generado). `VehicleDocumentStatus` se mapea 1:1 con él, pero `SoatStatus` se mantiene como capa de mapeo para no tocar esos consumidores ni los analytics. El rename ADR-E (`vehicles/SoatModel` → `VehicleSoatFormData`) **no debe tocar `SoatStatus`**.
- **No** se migra el `toRequestJson()` manual de SOAT a un DTO de request (**ADR-B**: deuda documentada; RTM nacerá cumpliendo la regla en la Fase 3). No se reabre el payload de escritura de SOAT.
- **No** se convierte `SoatModel` a freezed (rompería Pattern B + `==`/`copyWith` manuales).
- **No** se promueven los widgets OCR-específicos (`soat_autofill_banner`, `soat_not_recognized_warning`, `soat_manual_option_card`, `soat_upload_option_card`, `soat_add_document_sheet`, `soat_vehicle_options_sheet`, `soat_action_tile`): se quedan en `soat/`.
- **No** se crea `lib/features/tecnomecanica/` (Fase 3) ni se añade el segundo badge real al detalle del vehículo (Fase 4 monta la segunda instancia).
- **No** se toca el backend (`rideglory-api`), ni el scheduler de notificaciones, ni `NotificationType`.
- **No** se cambia ningún assertion de un test SOAT existente (si hiciera falta, es regresión).

### Sobre `vehicle_soat_section.dart` (aclaración de alcance)
`lib/features/vehicles/presentation/garage/widgets/vehicle_soat_section.dart` es **otro widget** del flujo garage/form (no es el card del detalle y no es consumidor de `VehicleSoatCard`). Consume `SoatStatus` (y el modelo duplicado de `vehicles/`). En esta fase **solo** se toca por el rename ADR-E (`SoatModel` → `VehicleSoatFormData`) en sus imports/tipos. **No** se reescribe, **no** se le quita su propio `getIt` si lo tuviera, **no** se reapunta al `VehicleDocumentCard`. Cualquier limpieza de su patrón queda fuera de esta fase.

---

## Que se debe hacer (pasos concretos y ordenados)

> El orden importa: ADR-E primero elimina la colisión de nombre; luego se construye la abstracción; luego SOAT la consume; el badge se reescribe al final.

1. **(ADR-E) Renombrar el duplicado.** Renombrar la clase `SoatModel` de `lib/features/vehicles/domain/models/soat_model.dart` a `VehicleSoatFormData` (renombrar también el archivo a `vehicle_soat_form_data.dart`). Renombrar consistentemente su DTO en `lib/features/vehicles/data/dto/soat_dto.dart` (la clase y, si aplica, el archivo) manteniendo Pattern B (`XDto extends XModel` + `XModelExtension.toJson()`). Reapuntar **todos** los consumidores verificados por grep: `vehicle_repository_impl.dart`, `vehicle_service.dart`, `vehicle_repository.dart`, `vehicle_model.dart`, `vehicle_form_view.dart`, `vehicle_form_docs_section.dart`, `vehicle_soat_form_slot.dart`, `vehicle_soat_section.dart`. Regenerar `.g.dart`. NO añadir lógica de status a esta clase. NO tocar `SoatStatus`. Verificar que esta clase **no** implementa `VehicleDocumentModel`.

2. **(ADR-A) Crear el dominio genérico** en `lib/features/vehicle_documents/domain/`:
   - `vehicle_document_kind.dart` → `enum VehicleDocumentKind { soat, tecnomecanica }` (el valor `tecnomecanica` se prevé para que el genérico ya tenga el shape de N kinds; RTM lo consume en Fase 3).
   - `vehicle_document_status.dart` → `enum VehicleDocumentStatus { none, valid, expiringSoon, expired }` (mapeo 1:1 con `SoatStatus { noSoat, valid, expiringSoon, expired }`).
   - `vehicle_document_expiry.dart` → `mixin VehicleDocumentExpiry` sobre un `DateTime get expiryDate` abstracto, con `int get daysUntilExpiry` y `VehicleDocumentStatus get status` (umbral `<= 30` → `expiringSoon`, `< 0` → `expired`) — copiando exactamente la lógica actual del `SoatModel` de `soat/`.
   - `vehicle_document_model.dart` → `abstract class VehicleDocumentModel` (contrato: `DateTime get expiryDate`, `String get vehicleId`, `VehicleDocumentKind get kind`).

3. **(ADR-A) Conectar `SoatModel` a la abstracción** en `lib/features/soat/domain/models/soat_model.dart`:
   - `class SoatModel with VehicleDocumentExpiry implements VehicleDocumentModel`.
   - Mover `daysUntilExpiry`/`status` al mixin (ya no se redeclaran en `SoatModel`). **Importante:** `status` debe seguir devolviendo el mismo enum que hoy consumen los `SoatStatus`-clientes, o existir un getter de compatibilidad. Decisión: **mantener `SoatStatus` y exponer `SoatStatus get status`** en `SoatModel` (mapeando desde `VehicleDocumentStatus` del mixin) para no tocar `home_garage_soat_badge`, `soat_status_view`, `soat_data_view`, `app_router`, etc.
   - Añadir `VehicleDocumentKind get kind => VehicleDocumentKind.soat;`.
   - **Preservar la firma pública** (constructor, `copyWith`, `==`/`hashCode`, getters) para no romper consumidores. `SoatDto extends SoatModel` queda intacto.

4. **(ADR-C) Crear la base de cubit genérica** en `lib/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart`: `abstract class VehicleDocumentCubit<T extends VehicleDocumentModel> extends Cubit<ResultState<T>>` con `load(vehicleId)`, `save(...)`, `delete(vehicleId)` y un hook de analytics (`logEvent`/`trackXxx`) que las subclases concretan. La base emite `loading`/`data`/`empty`/`error` igual que el `SoatCubit` actual.

5. **(ADR-C) Refactor `SoatCubit`** en `lib/features/soat/presentation/cubit/soat_cubit.dart`: `class SoatCubit extends VehicleDocumentCubit<SoatModel>`, conservando `ResultState<SoatModel>`, sus usecases inyectados (`GetSoatUseCase`, `SaveSoatUseCase`, `DeleteSoatUseCase`) y sus eventos analytics `soat_*` exactos. Los `BlocBuilder<SoatCubit, ResultState<SoatModel>>` no cambian.

6. **(ADR-D) Promover widgets genéricos puros** a `lib/features/vehicle_documents/presentation/widgets/`: extraer de `soat_validity_card`, `soat_detail_row`, `soat_document_section` (section header), `soat_empty_state`, `soat_status_view`, `soat_data_view` sus versiones genéricas (`validity_card.dart`, `detail_row.dart`, `section_header.dart`, `empty_state.dart`, `status_view.dart`, `data_view.dart`), recibiendo el modelo y el copy por parámetro. Reapuntar los imports de SOAT a los nuevos widgets (o dejar wrappers finos en `soat/` que inyecten el copy SOAT). Un widget por archivo; cero métodos `Widget _buildX()`.

7. **(ADR-F) Reescribir el badge.** Crear `VehicleDocumentCard` (genérico, parametrizado por `VehicleDocumentKind`) en `lib/features/vehicles/presentation/garage/widgets/` (reemplaza `vehicle_soat_card.dart`):
   - Alimentado por un **cubit `@injectable` + `ResultState`** provisto en el árbol (`BlocProvider` / `context.read`); **sin `getIt<...>()` dentro del widget**, **sin `bool _isLoading`**.
   - Los 4 estados se derivan de `VehicleDocumentStatus` (de `ResultState`/modelo), no de un `_statusLabel`/`_statusColor` local con literales.
   - **Solo** los 3 literales `'Vigente'`/`'Por vencer'`/`'Vence {fecha}'` se mueven a `context.l10n.<key>` reusando claves existentes. Los estados `expired` y `noSoat` **ya** consumen `context.l10n` hoy (`maintenance_expired_label` y `vehicle_soat_tap_to_add`) — se preservan tal cual, no se duplican ni se renombran.
   - El contrato acepta `kind` para que la misma clase pinte SOAT hoy y RTM en Fase 4 (N badges). El detalle del vehículo sigue montando **solo la instancia SOAT** en esta fase (paridad visual exacta).
   - El tap sigue navegando al mismo destino que hoy (`SoatEntryFlow.start` / `AppRoutes.soatStatus`) para SOAT.
   - Reapuntar `vehicle_detail_view.dart` (L59) de `VehicleSoatCard(vehicle: vehicle)` a `VehicleDocumentCard(kind: VehicleDocumentKind.soat, vehicle: vehicle)` (firma exacta a definir en implementación; preservar paridad).

8. **l10n + code-gen.** Reusar las claves ARB existentes (ver "Cambios de datos / l10n"). Si la firma de la clave de "Vence {fecha}" no soporta el placeholder requerido por el card, añadir **una** clave con placeholder `{date}`; documentar por qué. Ejecutar `flutter gen-l10n` (o `build_runner`) y `dart run build_runner build --delete-conflicting-outputs`.

9. **Validación de regresión cero.** `flutter test` (suite SOAT) sin tocar acceptance; `dart analyze` sin nuevos warnings; confirmar que los `.g.dart` de `SoatDto` no cambian de forma (Pattern B intacto); grep de imports / `getIt` / literales en el card.

---

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

### Crear
| Ruta | Qué cambia |
|------|-----------|
| `lib/features/vehicle_documents/domain/vehicle_document_kind.dart` | Nuevo `enum VehicleDocumentKind { soat, tecnomecanica }`. |
| `lib/features/vehicle_documents/domain/vehicle_document_status.dart` | Nuevo `enum VehicleDocumentStatus { none, valid, expiringSoon, expired }`. |
| `lib/features/vehicle_documents/domain/vehicle_document_expiry.dart` | `mixin VehicleDocumentExpiry` con `daysUntilExpiry`/`status` (lógica extraída del `SoatModel` de `soat/`). |
| `lib/features/vehicle_documents/domain/vehicle_document_model.dart` | `abstract class VehicleDocumentModel` (contrato `expiryDate`/`vehicleId`/`kind`). |
| `lib/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart` | `abstract class VehicleDocumentCubit<T extends VehicleDocumentModel>` base (ADR-C). |
| `lib/features/vehicle_documents/presentation/widgets/validity_card.dart` | Validity card genérica (copy por parámetro). |
| `lib/features/vehicle_documents/presentation/widgets/detail_row.dart` | Detail row genérica. |
| `lib/features/vehicle_documents/presentation/widgets/section_header.dart` | Section header genérica. |
| `lib/features/vehicle_documents/presentation/widgets/empty_state.dart` | Empty state genérico. |
| `lib/features/vehicle_documents/presentation/widgets/status_view.dart` | Status view genérica. |
| `lib/features/vehicle_documents/presentation/widgets/data_view.dart` | Data view genérica. |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` | `VehicleDocumentCard` genérico (cubit + `ResultState`, sin `getIt`/`bool`) — reemplaza `vehicle_soat_card`. |
| `lib/features/vehicles/domain/models/vehicle_soat_form_data.dart` | `VehicleSoatFormData` (renombrado del `SoatModel` duplicado, ADR-E). |

### Modificar
| Ruta | Qué cambia |
|------|-----------|
| `lib/features/soat/domain/models/soat_model.dart` | `SoatModel with VehicleDocumentExpiry implements VehicleDocumentModel`; lógica de status movida al mixin; `SoatStatus get status` (mapeo) y `kind` añadidos; firma pública preservada. **`SoatStatus` se conserva.** |
| `lib/features/soat/presentation/cubit/soat_cubit.dart` | `SoatCubit extends VehicleDocumentCubit<SoatModel>` conservando `ResultState<SoatModel>` y analytics `soat_*`. |
| `lib/features/soat/presentation/widgets/soat_validity_card.dart` | Reapunta al genérico `validity_card` (wrapper fino con copy SOAT) o se elimina si el genérico lo absorbe. |
| `lib/features/soat/presentation/widgets/soat_detail_row.dart` | Reapunta a `detail_row` genérico. |
| `lib/features/soat/presentation/widgets/soat_document_section.dart` | Reapunta a `section_header` genérico. |
| `lib/features/soat/presentation/widgets/soat_empty_state.dart` | Reapunta a `empty_state` genérico. |
| `lib/features/soat/presentation/widgets/soat_status_view.dart` | Reapunta a `status_view` genérico (sigue consumiendo `SoatStatus`). |
| `lib/features/soat/presentation/widgets/soat_data_view.dart` | Reapunta a `data_view` genérico (sigue consumiendo `SoatStatus`). |
| `lib/features/vehicles/data/dto/soat_dto.dart` | Clase DTO renombrada al par de `VehicleSoatFormData` (Pattern B preservado); `.g.dart` regenerado. |
| `lib/features/vehicles/data/repository/vehicle_repository_impl.dart` | Reapunta tipos al `VehicleSoatFormData` renombrado. |
| `lib/features/vehicles/data/service/vehicle_service.dart` | Reapunta tipos/imports al renombrado; `.g.dart` regenerado. |
| `lib/features/vehicles/domain/repository/vehicle_repository.dart` | Reapunta firmas al renombrado. |
| `lib/features/vehicles/domain/models/vehicle_model.dart` | Reapunta tipo del campo SOAT-form al renombrado (consume el duplicado). **`SoatStatus` que también referencia se conserva.** |
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_view.dart` | Reapunta import/tipo al `VehicleSoatFormData` renombrado. |
| `lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart` | Reapunta al renombrado; sigue consumiendo `SoatStatus`. |
| `lib/features/vehicles/presentation/form/widgets/vehicle_soat_form_slot.dart` | Reapunta al `VehicleSoatFormData` renombrado; sigue consumiendo `SoatStatus`. |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_section.dart` | Reapunta tipos al renombrado (ADR-E). **No** se reescribe ni se reapunta al `VehicleDocumentCard` (fuera de alcance, ver "Aclaración de alcance"). |
| `lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart` | **Consumidor real del card.** L59: cambiar `VehicleSoatCard(vehicle: vehicle)` por `VehicleDocumentCard(kind: VehicleDocumentKind.soat, vehicle: vehicle)`. Verificar con `grep "VehicleSoatCard("` antes de editar. |
| `lib/l10n/app_es.arb` | Reuso de claves existentes para los 3 literales del badge (ver "Cambios de datos / l10n"). Claves SOAT existentes intactas. |

### Eliminar
| Ruta | Qué cambia |
|------|-----------|
| `lib/features/vehicles/presentation/garage/widgets/vehicle_soat_card.dart` | Reemplazado por `vehicle_document_card.dart` (ADR-F). |
| `lib/features/vehicles/domain/models/soat_model.dart` | Renombrado a `vehicle_soat_form_data.dart` (ADR-E). |

> **Consumidores del duplicado `vehicles/SoatModel`** (rutas reales verificadas por grep `grep -rln "domain/models/soat_model.dart\|data/dto/soat_dto.dart" lib/features/vehicles/`): `data/dto/soat_dto.dart`, `data/repository/vehicle_repository_impl.dart`, `data/service/vehicle_service.dart`, `domain/repository/vehicle_repository.dart`, `domain/models/vehicle_model.dart`, `presentation/form/widgets/vehicle_form_view.dart`, `presentation/form/widgets/vehicle_soat_form_slot.dart`, `presentation/form/widgets/vehicle_form_docs_section.dart`, `presentation/garage/widgets/vehicle_soat_section.dart`. Todos se reapuntan en el paso 1. **No quedan "a confirmar durante ejecución".**

---

## Contratos / API rideglory-api (o "ninguno")

**Ninguno.** Esta fase es 100% Flutter interna. No se crea, modifica ni consume ninguna ruta de `rideglory-api`. El contrato HTTP de SOAT (GET/POST/DELETE `/soat`) y su serialización quedan **idénticos** (Pattern B intacto, `.g.dart` sin cambio de forma).

---

## Cambios de datos / migraciones (o "ninguno")

**Ninguno** a nivel persistencia/backend. No hay Prisma, ni tablas, ni cambios de serialización.

### l10n — reconciliación de claves ARB (no duplicar copy)
`lib/l10n/app_es.arb` **ya contiene** las claves para 2 de los 3 literales (verificado por grep):
- `soat_status_valid` = `"Vigente"` (L947) → **reusar** para `'Vigente'`.
- `soat_status_expiring_soon` = `"Por vencer"` (L948) → **reusar** para `'Por vencer'`.
- `vehicle_soat_status_expires_today` = `"Vence hoy"` (L769) existe para el borde "hoy", pero **no** hay una clave genérica `"Vence {fecha}"` con placeholder de fecha. Para `'Vence ${DateFormat.yMMMd(...)}'` (L154 del card) se necesita una clave con placeholder.

**Decisión:** **NO** crear claves `vehicleDocument_status*` que dupliquen `"Vigente"`/`"Por vencer"`. El card reusa `soat_status_valid` y `soat_status_expiring_soon` existentes. **Se añade una única clave nueva** con placeholder de fecha (p. ej. `vehicle_soat_expires_on` = `"Vence {date}"` con metadato `@vehicle_soat_expires_on` para el placeholder `date`) **solo si** no existe ya una equivalente; justificación: el copy "Vence {fecha}" no tiene clave con placeholder hoy (las existentes son fijas: "Vence hoy"). Si en implementación se encuentra una clave equivalente reutilizable, se reusa y no se crea ninguna. Las claves SOAT existentes quedan **intactas**.

Los estados `expired` y `noSoat` del card **ya** consumen l10n (`maintenance_expired_label` L814, `vehicle_soat_tap_to_add` L739) y **no** se tocan: no son literales y no entran en el criterio 4.

---

## Criterios de aceptacion (numerados, observables, testeables)

1. **Suite SOAT verde sin editar su acceptance:** `flutter test` pasa al 100% en todos los tests de `soat/` **sin modificar ningún assertion existente**. Si un test SOAT requiere cambiar su assertion para pasar, cuenta como regresión y la fase no cierra.
2. **`dart analyze` sin nuevos warnings** respecto a la línea base de `main` (se permiten únicamente los 2 lints preexistentes del hack local de `api_base_url_resolver.dart`).
3. **`dart run build_runner build --delete-conflicting-outputs` sin conflictos** y los `.g.dart` de `SoatDto` **no cambian de forma** (Pattern B intacto; serialización SOAT idéntica).
4. **Cero literales hardcodeados en el card, acotado a los 3 exactos:** `grep -n "'Vigente'\|'Por vencer'\|'Vence "` sobre `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` devuelve **0 resultados**; esos 3 textos provienen de `context.l10n.<key>` (reusando `soat_status_valid`, `soat_status_expiring_soon` y la clave de "Vence {fecha}"). Los estados `expired`/`noSoat` siguen usando `maintenance_expired_label`/`vehicle_soat_tap_to_add` (ya lo hacían, no entran en el criterio).
5. **Cero `getIt<...>()` dentro de un widget:** `grep -n "getIt" lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` devuelve **0 resultados**. El card consume un cubit `@injectable` vía `BlocProvider`/`context.read`. No existe `bool _isLoading` en el card (usa `ResultState`).
6. **Abstracción aplicada sin romper Pattern B:** `SoatModel with VehicleDocumentExpiry implements VehicleDocumentModel` compila; `SoatDto extends SoatModel` se mantiene; la serialización SOAT es idéntica (criterio 3).
7. **Colisión de nombre eliminada (ADR-E):** ya no existe una segunda clase llamada `SoatModel`; el duplicado de `vehicles/` se llama `VehicleSoatFormData` y **no** implementa `VehicleDocumentModel`. `grep -rn "class SoatModel" lib/` devuelve exactamente **1** resultado (el de `soat/`).
8. **`SoatStatus` preservado:** `grep -rn "enum SoatStatus" lib/` sigue devolviendo **1** resultado; sus consumidores (`home_garage_soat_badge`, `vehicle_cubit`, `app_router`, `vehicle_form_docs_section`, `vehicle_soat_form_slot`, `soat_status_page`, `soat_data_view`, `soat_status_view`, `vehicle_soat_section`, `vehicle_model`) compilan sin cambios de semántica. El rename ADR-E no tocó `SoatStatus`.
9. **Único consumidor del card reapuntado:** `grep -rn "VehicleSoatCard(" lib/` devuelve **0 resultados**; `vehicle_detail_view.dart` instancia `VehicleDocumentCard`. `home_garage_soat_badge.dart` **no** fue modificado (queda fuera de alcance).
10. **Contrato del genérico soporta N badges:** `VehicleDocumentCard` está parametrizado por `VehicleDocumentKind` y `VehicleDocumentCubit<T>` es genérico; añadir un segundo badge en Fase 4 es capa fina (la firma del card recibe `kind`; el cubit base no menciona `Soat` en su tipo).
11. **Analytics SOAT intacto:** los eventos `soat_*` y los valores de `status.name` enviados a analytics son byte-idénticos a los de `main` (verificable por inspección de `SoatCubit` y del mapeo `SoatStatus`↔`VehicleDocumentStatus`).
12. **Cero cambio visible para el usuario:** el detalle del vehículo renderiza el badge SOAT con el mismo layout, colores, 4 estados, skeleton de loading y destino de tap que hoy.

---

## Pruebas (unitarias/widget/integracion)

- **Regresión (obligatoria, gate):** correr la suite SOAT existente completa (`flutter test test/.../soat...`) **sin modificarla**. Verde = línea base preservada.
- **Unit — lógica de estado del mixin:** test nuevo de `VehicleDocumentExpiry` (vía `SoatModel` como implementación concreta) cubriendo los 4 estados: sin documento (`none`), vigente (`valid`, `daysUntilExpiry > 30`), por vencer (`expiringSoon`, `0 <= daysUntilExpiry <= 30`), vencido (`expired`, `daysUntilExpiry < 0`), incluido el borde exacto `daysUntilExpiry == 30` y `== 0`. Debe producir los mismos resultados que la lógica previa de `SoatModel`.
- **Unit — mapeo de status:** test que confirma que el mapeo `SoatStatus`↔`VehicleDocumentStatus` y `SoatModel.status.name` producen los mismos strings que hoy para analytics (criterio 11).
- **Widget — `VehicleDocumentCard`:** test que monta el card con un cubit fake emitiendo `loading` → `data(valid)` / `data(expiringSoon)` / `empty` / `error`, verificando que pinta el estado correcto, usa textos de l10n (no literales) y no llama `getIt`. (Cobertura formal completa: Fase 6.)
- **Unit — DTO renombrado:** smoke test de `fromJson`/`toJson` de `VehicleSoatFormData`/su DTO (Pattern B) para confirmar que el rename no rompió la serialización del alta de vehículo.

> La suite parametrizada completa del cubit base y de los widgets compartidos se consolida en Fase 6; esta fase solo añade lo necesario para blindar la regresión cero.

---

## Riesgos y mitigaciones

| # | Riesgo | Sev. | Mitigación |
|---|--------|------|-----------|
| R1 | Refactor rompe Pattern B o consumidores de `SoatModel` al genéricar model+cubit+widgets. | Alta | ADR-A (mixin+interfaz, no freezed) preserva la firma pública; ADR-C mantiene `ResultState<SoatModel>`. Gate: suite SOAT verde sin tocar acceptance + `.g.dart` sin cambio de forma. |
| R2 | El rename del duplicado (ADR-E) deja consumidores apuntando a un símbolo inexistente. | Media | Lista cerrada de 9 consumidores verificada por grep (paso 1); `dart analyze` como red de seguridad; smoke test de serialización. |
| R3 | El refactor toca `SoatStatus` por error y rompe `home_garage_soat_badge`/router/form al genéricar. | Media | ADR-E **no** toca `SoatStatus`; se mantiene como capa de mapeo; criterio 8 lo verifica por grep; `home_garage_soat_badge` declarado fuera de alcance. |
| R4 | `VehicleDocumentStatus.name` difiere de `SoatStatus.name` y rompe analytics silenciosamente. | Media | Mantener `SoatStatus` y exponer `SoatStatus get status`; test unit de mapeo; criterio 11 (analytics byte-idéntico). |
| R5 | Promover widgets a genéricos introduce un cambio visual sutil en SOAT. | Media | Copy y estilos inyectados por parámetro; wrappers finos en `soat/`; criterio 12 (cero cambio visible); revisión visual del detalle. |
| R6 | El nuevo `VehicleDocumentCard` con cubit altera el ciclo de carga del badge (parpadeo, doble fetch). | Media | El cubit `@injectable` se provee en el árbol; un `load(vehicleId)` al montar, replicando el skeleton actual; widget test de la transición `loading→data`. |
| R7 | Duplicar copy ARB ("Vigente"/"Por vencer") al crear claves nuevas. | Media | Reusar `soat_status_valid`/`soat_status_expiring_soon` existentes; solo crear clave nueva para "Vence {fecha}" (placeholder) y solo si no existe equivalente. |
| R8 | Ambigüedad sobre `vehicle_soat_section.dart` (¿se reescribe?). | Baja | Aclarado: solo se reapunta por el rename ADR-E; no se reescribe ni se reapunta al card. |
| R9 | Code-gen en worktree fresco falla (objective_c build hooks). | Baja | Usar `--force-jit` o copiar `pubspec.lock`/`.env`/configs Firebase de `main` (memoria de proyecto). |
| R10 | Sobre-generalización (inflar la fase metiendo widgets OCR, el badge del home o lógica RTM). | Media | ADR-D acota qué se promueve; OCR-específicos, `home_garage_soat_badge` y `tecnomecanica/` quedan explícitamente fuera de alcance. |

---

## Dependencias (fases prerequisito y por que)

**Ninguna fase prerequisito** (`dependsOn: []`). Es la fundación del plan: crea `vehicle_documents/` y fija el contrato del genérico (mixin, interfaz, cubit base, card por `kind`, N badges) del que dependen todas las demás. Bloquea a Fases 3, 4 y 6 (consumen los genéricos) y habilita el split de PRs (este es PR #1, independiente del backend de la Fase 2).

---

## Ejecucion recomendada (nivel rg-exec: full)

**Por qué `full`:** refactor estructural cross-cutting de **mayor blast radius** del plan. Toca model + cubit + widgets + badge de un feature **en producción** (SOAT), reconcilia un modelo **no-freezed** con **Pattern B** (DTO extends Model), **renombra un modelo duplicado** consumido en el alta de vehículo (9 consumidores), y **fija el contrato del genérico para N badges** del que dependen las fases posteriores. Es **difícil de revertir** (toca código vivo y la serialización de un feature en uso) y tiene un **criterio duro de regresión cero**: cualquier cambio de assertion en un test SOAT cuenta como fallo, no como ajuste.

Esto justifica el nivel `full`: **QA adversarial** (busca activamente regresiones visuales, de serialización y roturas de `SoatStatus`), **3 rondas de auditor Opus** y **fix loops** hasta que (a) la suite SOAT esté verde sin tocar acceptance, (b) `dart analyze` y `build_runner` estén limpios, (c) cero literales/`getIt`/`bool` en el card y `SoatStatus` preservado, y (d) el contrato del genérico quede verificablemente listo para N badges. Es PR commit-able #1; el working tree queda sucio para revisión humana (sin commits desde el workflow).
