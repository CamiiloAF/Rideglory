# Fix Issues #17 y #21

## Issue #17 — SOAT y documentos no se guardan al crear vehículo (🟠 Alto)

Al crear un vehículo nuevo y adjuntar el SOAT u otros documentos, los documentos **no se persisten**: al ver el detalle del vehículo o editarlo, las tarjetas de SOAT y documentos aparecen vacías. El usuario tiene que re-adjuntar los documentos después de guardar.

**Pasos para reproducir:**
1. Ir al garaje → crear vehículo
2. En la sección de documentos, adjuntar SOAT
3. Guardar el vehículo
4. Abrir el detalle del vehículo → las tarjetas de documentos aparecen vacías

**Comportamiento esperado:** Al crear un vehículo con documentos, estos deben mostrarse en el detalle y en la edición posterior.

## Issue #21 — Selector de vehículo vacío en inscripciones (🔴 Crítico)

Al intentar inscribirse en un evento que permite todas las marcas, la pantalla de inscripción muestra "No tienes vehículos disponibles para esta inscripción" aunque el usuario SÍ tiene vehículos registrados.

**Pasos para reproducir:**
1. Ingresar a un evento que permite todas las marcas
2. Presionar "Inscribirme"
3. La sección de vehículo muestra estado vacío

**Comportamiento esperado:** El usuario debe poder seleccionar cualquiera de sus vehículos para la inscripción.

## Contexto técnico conocido

- Rama activa: `fix/github-issues`
- Los fixes simples (#20 filtro eventos, #16 tarjeta SOAT) ya fueron aplicados en esta rama
- Para #17: el flujo pasa por `VehicleFormCubit` → `VehicleRepositoryImpl` → `VehicleService`. El SOAT se guarda localmente como `soatLocalPath` pero puede no incluirse en el payload de creación
- Para #21: `RegistrationFormContent` usa `context.read<VehicleCubit>().availableVehicles` dentro de un `BlocBuilder`. Si los vehículos no han cargado aún o `availableVehicles` retorna lista vacía, se muestra el estado vacío
