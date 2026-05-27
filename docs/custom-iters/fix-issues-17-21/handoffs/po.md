# PO Handoff — Fix Issues #17 y #21

## Goal

Corregir dos bugs de alta prioridad: (1) los documentos SOAT adjuntados durante la creación de un vehículo nuevo no se persisten en el backend; (2) el selector de vehículo en el formulario de inscripción muestra estado vacío aunque el usuario tenga vehículos, cuando el evento permite todas las marcas.

---

## Source quote

> ## Issue #17 — SOAT y documentos no se guardan al crear vehículo (🟠 Alto)
>
> Al crear un vehículo nuevo y adjuntar el SOAT u otros documentos, los documentos **no se persisten**: al ver el detalle del vehículo o editarlo, las tarjetas de SOAT y documentos aparecen vacías. El usuario tiene que re-adjuntar los documentos después de guardar.
>
> ## Issue #21 — Selector de vehículo vacío en inscripciones (🔴 Crítico)
>
> Al intentar inscribirse en un evento que permite todas las marcas, la pantalla de inscripción muestra "No tienes vehículos disponibles para esta inscripción" aunque el usuario SÍ tiene vehículos registrados.
>
> ## Contexto técnico conocido
> - Para #17: el flujo pasa por `VehicleFormCubit` → `VehicleRepositoryImpl` → `VehicleService`. El SOAT se guarda localmente como `soatLocalPath` pero puede no incluirse en el payload de creación
> - Para #21: `RegistrationFormContent` usa `context.read<VehicleCubit>().availableVehicles` dentro de un `BlocBuilder`. Si los vehículos no han cargado aún o `availableVehicles` retorna lista vacía, se muestra el estado vacío

---

## Interpretation

**Issue #17:** El flujo de creación de vehículo tiene una etapa de UI que permite adjuntar el SOAT (`VehicleFormDocsSection` → `VehicleSoatOptionsSheet` → guarda `soatLocalPath` en `VehicleFormState`). Sin embargo, `VehicleFormPage._saveVehicle()` solo llama a `cubit.saveVehicle(vehicleToSave, localImagePath: ...)` — que maneja solo la imagen de portada. El `soatLocalPath` queda en el estado del cubit pero **nunca se usa** para hacer una llamada al backend. El fix correcto es: después de que `_createNewVehicle` retorne con éxito y tengamos el `vehicleId`, hacer una segunda llamada a `VehicleRepository.upsertSoat()` si `state.soatLocalPath != null`.

**Issue #21:** El bug tiene dos causas entrelazadas:
1. `BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>` reconstruye correctamente cuando el estado cambia, pero dentro del builder se hace `context.read<VehicleCubit>().availableVehicles` — si el estado es `loading` o `initial`, `_vehicles` es lista vacía, y se muestra el estado vacío.
2. No hay manejo de estado `loading` ni `initial` en el selector — todo estado que no sea `data` con lista no vacía cae al "sin vehículos".

El fix es diferenciar en el `BlocBuilder` entre: estado de carga (mostrar spinner), estado vacío real (mostrar CTA crear vehículo), y estado con datos (mostrar selector).

---

## Affected areas — current state

| Área | Archivo | Líneas clave | Comportamiento actual | Comportamiento esperado |
|------|---------|-------------|----------------------|------------------------|
| Save trigger | `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | L107–118 (`_saveVehicle`) | Llama `cubit.saveVehicle(vehicleToSave, localImagePath: imageCubit.selectedLocalImagePath)`. No pasa `soatLocalPath` ni lo procesa. | Tras la creación exitosa, si `cubit.state.soatLocalPath != null`, disparar una llamada separada al repositorio SOAT con el nuevo `vehicleId`. |
| Form listener | `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | L144–174 (`_formListener`) | En `data:` branch: llama `addVehicleLocally(savedVehicle)`, muestra SnackBar y hace `context.pop(savedVehicle)`. No hace nada con SOAT. | En `data:` branch (solo creación): si `state.soatLocalPath != null`, primero subir SOAT y luego hacer pop. |
| VehicleFormCubit | `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart` | L65–87 (`saveVehicle`) | Solo maneja imagen de portada. `soatLocalPath` existe en `VehicleFormState` pero no se propaga. | Exponer `soatLocalPath` del estado para que la página lo use post-creación, o que el cubit orqueste la llamada SOAT. |
| VehicleFormState | `lib/features/vehicles/presentation/cubit/vehicle_form_state.dart` | L12 | `soatLocalPath: String?` existe en estado. | Sin cambio en el modelo — ya está correcto. |
| VehicleFormDocsSection | `lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart` | L105–123 (`_onSoatTap`) | Para vehículos sin id (nuevos): muestra `VehicleSoatOptionsSheet`. Si usuario elige "upload", llama `setSoatFromLocalPath(result.image.path)`. Ruta queda en estado pero no se envía al backend. | Sin cambio aquí — ya guarda la ruta correctamente. El fix está en el flujo de save. |
| Registration vehicle selector | `lib/features/event_registration/presentation/registration_form_content.dart` | L407–478 (`BlocBuilder` para vehículo) | `BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>` reconstruye, pero el cuerpo hace `context.read<VehicleCubit>().availableVehicles`. Si `_vehicles` está vacío (cargando o sin datos), muestra el empty state. No hay rama para `loading`/`initial`. | Agregar rama para `loading`/`initial`: mostrar `CircularProgressIndicator`. Rama `empty` real: mostrar CTA. Rama `data` con vehículos: mostrar selector. |
| VehicleCubit | `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` | L27–28 (`availableVehicles`) | `availableVehicles` retorna `_vehicles` que es `[]` hasta que `fetchMyVehicles()` completa. | Sin cambio en el cubit — el fix está en cómo el consumer maneja los estados intermedios. |

---

## Acceptance criteria

1. **AC-1:** Al crear un vehículo nuevo con SOAT adjuntado, el SOAT aparece en el detalle del vehículo después de guardar (badge distinto de "Sin SOAT").
2. **AC-2:** Al abrir el detalle del vehículo recién creado con SOAT adjuntado, la tarjeta muestra el badge de estado correcto según la fecha de vencimiento.
3. **AC-3:** Al crear un vehículo sin adjuntar SOAT, el flujo funciona exactamente igual que antes.
4. **AC-4:** Si la carga del SOAT falla después de que el vehículo fue creado, el vehículo sigue existiendo y se muestra un SnackBar de error (el vehículo no se pierde).
5. **AC-5:** Al abrir el formulario de inscripción de un evento con `allowedBrands = ['*']` o lista vacía, el selector de vehículo muestra los vehículos del usuario cuando el usuario tiene vehículos registrados.
6. **AC-6:** Mientras `VehicleCubit` está cargando, el selector de vehículo muestra un indicador de carga.
7. **AC-7:** Si el usuario realmente no tiene vehículos, el estado vacío con CTA "Crear vehículo" sigue mostrándose correctamente.
8. **AC-8:** `dart analyze` pasa sin nuevas violaciones.

---

## Regression guardrails

| Guardian | Qué probar | Cómo verificar |
|----------|-----------|----------------|
| Edición de vehículo con SOAT existente | El flujo de edición no re-guarda ni sobreescribe el SOAT | Editar solo el nombre de un vehículo con SOAT; abrir detalle y confirmar que SOAT no cambió ni desapareció |
| Creación sin SOAT | El flujo de creación retorna `ResultState.data` sin errores | Crear vehículo sin adjuntar documentos; verificar SnackBar de éxito y redirección |
| Inscripción en evento con marcas restringidas | La validación de marca sigue funcionando | Intentar inscribirse a evento con marcas restringidas usando moto de marca no permitida; verificar SnackBar de error de marca |
| `VehicleCubit` ya en estado `Data` | Si los vehículos ya están en memoria, el selector los muestra de inmediato sin flicker | Abrir inscripción después de haber visitado el garaje en la misma sesión |
| `VehicleCubit` `Empty` state real | Estado vacío real aparece para usuarios sin vehículos | QA: confirmar con usuario sin vehículos en staging |
| `dart analyze` | Sin regresión de lint | Correr `dart analyze` y comparar con baseline (0 errores/0 warnings) |

---

## Decisions needed from downstream agents

### Para el Arquitecto

1. **Issue #17 — Orquestación SOAT post-creación:** ¿Debe el `VehicleFormCubit` orquestar la llamada SOAT después de crear el vehículo (requiere inyectar `VehicleRepository` directamente en el cubit, o un use case `UpsertSoatUseCase`), o debe la página (`VehicleFormPage`) hacerlo leyendo el `soatLocalPath` del estado y usando `SoatFormCubit` por separado? Recomendación PO: centralizar en `VehicleFormCubit` para mantener la responsabilidad del guardado en un solo lugar.

2. **Issue #17 — Error handling:** Si el vehículo se crea con éxito pero el SOAT falla, ¿se hace `pop()` de todos modos (preservando el vehículo y mostrando error de SOAT separado), o se queda en la pantalla? Recomendación PO: hacer `pop()` del vehículo creado y mostrar SnackBar de error de SOAT separado (vehículo no se pierde).

3. **Issue #21 — `fetchMyVehicles` en inscripción:** Si `VehicleCubit` está en `loading`/`initial` al montar el formulario, ¿basta con mostrar un spinner y esperar al `BlocBuilder`, o se debe también llamar `fetchMyVehicles()` si el cubit está en `initial`? Revisar si hay una garantía de que `VehicleCubit` siempre carga antes de que el usuario llegue a inscripción.

### Para el Frontend

1. El `BlocBuilder` en `registration_form_content.dart` (línea 407) usa el snapshot del estado correctamente para reconstruir. Sin embargo, la lectura interna `context.read<VehicleCubit>().availableVehicles` puede retornar lista vacía aunque el snapshot del builder sea `Data`. Confirmar si este es el comportamiento observado o si el bug se reproduce en un estado diferente.

2. Para Issue #17: el `SoatFormCubit` ya existe y tiene el método `submit(vehicleId, {XFile? documentImage})` que sube la imagen y llama al backend. Se puede reutilizar directamente con `getIt<SoatFormCubit>()` o inyectarlo en el `VehicleFormCubit`.

---

## Open questions for the human

Ninguna. El contexto técnico es suficiente para proceder.

---

## Suggested phase plan

- `needsDesign: no` — No hay cambios visuales. Los estados de carga del selector de vehículo usan componentes existentes (CircularProgressIndicator o similar ya en uso en la app).
- `needsBackend: no` — Los endpoints `POST /api/vehicles/:vehicleId/soat` ya existen.
- `needsFrontend: yes` — Cambios en `vehicle_form_page.dart`, `vehicle_form_cubit.dart` (posiblemente), y `registration_form_content.dart`.
- `needsDb: no`

Fases recomendadas: **architect → frontend → qa**

---

## Notes for orchestrator

- La rama activa es `fix/github-issues`. Los fixes #16 y #20 ya están aplicados — no tocar esas partes.
- Issue #21 es marcado como Crítico (bloquea flujo de negocio core: inscripción a eventos).
- Issue #17 es Alto (datos silenciosamente perdidos).
- El `SoatFormCubit` en `lib/features/vehicles/presentation/soat/cubit/soat_form_cubit.dart` ya tiene la lógica completa de upload + backend call. El fix de #17 debe reusar ese cubit o su lógica, no duplicarla.
- `dart analyze` debe pasar con 0 errores/0 warnings antes de dar por cerrado el fix.
- No hay cambios de ARB necesarios (los strings de error ya existen o se usan los genéricos de la app).
