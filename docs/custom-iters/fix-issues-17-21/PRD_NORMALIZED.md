# PRD Normalizado — Fix Issues #17 y #21

## § 1 Título

Corregir persistencia de documentos SOAT en creación de vehículo (#17) y selector de vehículo vacío en inscripciones (#21)

---

## § 2 Goal

Garantizar que el SOAT adjuntado durante la creación de un vehículo nuevo sea guardado en el backend mediante una llamada separada post-creación, y que el selector de vehículo en el formulario de inscripción muestre correctamente los vehículos del usuario cuando el evento permite todas las marcas.

---

## § 3 Tipo y Severidad

| Propiedad | Valor |
|-----------|-------|
| Tipo | fix |
| Severidad | high (Issue #17) + critical (Issue #21) |
| Rama activa | `fix/github-issues` |

---

## § 4 Áreas afectadas

| Área | Archivo | Comportamiento actual | Comportamiento esperado |
|------|---------|----------------------|------------------------|
| SOAT save on vehicle create | `lib/features/vehicles/presentation/form/vehicle_form_page.dart` | `_saveVehicle()` llama `cubit.saveVehicle()` con solo `localImagePath`; `soatLocalPath` del estado del cubit nunca se usa en el flujo de guardado | Después de crear el vehículo con éxito, si `state.soatLocalPath != null`, llamar automáticamente `SoatFormCubit.submit()` (o el equivalente en repositorio) con la imagen local y el `vehicleId` recién creado |
| SOAT state management | `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart` | `soatLocalPath` se almacena en estado (`VehicleFormState`) pero `_createNewVehicle()` / `saveVehicle()` no usa ese campo para hacer nada con él | `saveVehicle()` debe exponer el `soatLocalPath` para que la capa de presentación lo use post-creación, o el cubit debe orquestar la llamada SOAT después de crear el vehículo |
| Vehicle form docs section | `lib/features/vehicles/presentation/form/widgets/vehicle_form_docs_section.dart` | Para vehículos sin `id` (nuevos), `_onSoatTap` muestra `VehicleSoatOptionsSheet`; si el usuario elige "subir", guarda la ruta en `VehicleFormCubit.soatLocalPath`. La ruta queda en el estado pero nunca se envía al backend. | El camino feliz debe terminar en una llamada real a `POST /api/vehicles/:vehicleId/soat` con la imagen seleccionada, usando el `vehicleId` que retorna la creación |
| Inscription vehicle selector | `lib/features/event_registration/presentation/registration_form_content.dart` | `availableVehicles` se calcula como `context.read<VehicleCubit>().availableVehicles.where((v) => !v.isArchived)`. Si `VehicleCubit` todavía está en `ResultState.loading()` o `ResultState.initial()` cuando se renderiza el `BlocBuilder`, `_vehicles` es lista vacía y muestra el estado vacío. Además, `BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>` reconstruye correctamente, pero `context.read<VehicleCubit>().availableVehicles` (lectura directa, no del snapshot) puede retornar lista vacía si el cubit aún no terminó de cargar | Mostrar un indicador de carga mientras `VehicleCubit` está en estado `loading`/`initial`, y mostrar los vehículos disponibles una vez que el estado sea `data` |
| Event allowed brands filter | `lib/features/event_registration/presentation/registration_form_content.dart` (líneas 78–82) | `availableBrands` filtra `allowedBrands` eliminando entradas vacías y el wildcard `'*'`. Si el evento permite todas las marcas y `allowedBrands = ['*']`, `availableBrands` queda vacía, lo que hace que la validación de marca sea omitida — esto es correcto. El problema real es que el selector de vehículo muestra lista vacía antes de que los vehículos carguen | La lógica de filtrado por marca es correcta; el bug es la ausencia de estado de carga en el selector |

---

## § 5 Fuera de alcance

- Implementar SOAT para la revisión técnica (`techReviewLocalPath`): mismo patrón pero no reportado como bug activo.
- Cambios en el backend (`rideglory-api`): los endpoints `POST /api/vehicles/:vehicleId/soat` ya existen (iter-2).
- OCR auto-fill del SOAT (deferred post-MVP).
- Cambios en el diseño visual de ninguna pantalla.
- Cualquier cambio en `docs/PRD.md`, `docs/PLAN.md`, `workflow/state.json`.

---

## § 6 Criterios de aceptación

1. **AC-1 (Issue #17 — Creación):** Al crear un vehículo nuevo con un documento SOAT adjuntado, el SOAT aparece correctamente en el detalle del vehículo después de guardar (badge distinto de "Sin SOAT").
2. **AC-2 (Issue #17 — Detalle):** Al abrir el detalle del vehículo recién creado con SOAT adjuntado, la tarjeta de SOAT muestra el badge de estado correcto (Vigente / Por vencer / Vencido) según la fecha de vencimiento.
3. **AC-3 (Issue #17 — Sin SOAT):** Al crear un vehículo sin adjuntar SOAT, el flujo de creación funciona exactamente igual que antes (sin regresión).
4. **AC-4 (Issue #17 — Error handling):** Si la carga del SOAT falla después de que el vehículo fue creado, el vehículo sigue existiendo y se muestra un SnackBar de error de SOAT (el vehículo no se pierde).
5. **AC-5 (Issue #21 — Evento todas las marcas):** Al abrir el formulario de inscripción de un evento con `allowedBrands = ['*']` o lista vacía, el selector de vehículo muestra los vehículos del usuario (no el estado vacío) cuando el usuario tiene vehículos registrados.
6. **AC-6 (Issue #21 — Loading state):** Mientras `VehicleCubit` está cargando, el selector de vehículo muestra un indicador de carga en lugar del estado vacío.
7. **AC-7 (Issue #21 — Sin vehículos reales):** Si el usuario realmente no tiene vehículos (no es un falso negativo por timing), el estado vacío con CTA "Crear vehículo" sigue mostrándose correctamente.
8. **AC-8 (Lint):** `dart analyze` pasa sin nuevas violaciones tras los cambios.

---

## § 7 Guardianes de regresión

| Área | Guardian | Verificación |
|------|----------|-------------|
| Edición de vehículo con SOAT existente | El flujo de edición no debe re-guardar el SOAT ni sobrescribirlo | Editar nombre del vehículo y guardar; verificar que el SOAT no cambia |
| Creación sin SOAT | El flujo de creación termina correctamente en `ResultState.data` | Crear vehículo sin adjuntar documentos; verificar éxito |
| Inscripción en evento con marcas restringidas | La validación de marca sigue funcionando | Intentar inscribirse a evento con marca restringida usando moto de marca no permitida |
| `VehicleCubit` ya cargado | Si los vehículos ya están en memoria, el selector los muestra inmediatamente | Abrir inscripción cuando `VehicleCubit` ya está en `Data` |
| `VehicleCubit` `Empty` state | Estado vacío real sigue apareciendo correctamente | Probar con usuario sin vehículos |
| `dart analyze` | Sin nuevas violaciones | Correr `dart analyze` antes de finalizar |

---

## § 8 Dependencias y supuestos

- El endpoint `POST /api/vehicles/:vehicleId/soat` ya existe en el backend (`rideglory-api`) y funciona según el contrato de iter-2. No se requieren cambios en el backend.
- `VehicleCubit` es un `@singleton` registrado en el `MultiBlocProvider` raíz de `main.dart`. Puede estar en estado `loading` cuando `RegistrationFormContent` se monta si la navegación fue muy rápida.
- La imagen local del SOAT es una ruta de archivo en el dispositivo (`soatLocalPath`). Se debe subir a Firebase Storage antes de llamar al backend — `SoatFormCubit.submit()` ya hace esto.
- No hay cambios de diseño: no se requiere consultar rideglory.pen.
- Branch de trabajo: `fix/github-issues` (los fixes #16 y #20 ya fueron aplicados en esta rama).

---

## § 9 Preguntas abiertas para el humano

Ninguna. El contexto técnico del issue note y el código son suficientes para proceder.

---
