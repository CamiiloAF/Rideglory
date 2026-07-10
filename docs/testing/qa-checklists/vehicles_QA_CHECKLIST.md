# Checklist de QA — Vehicles (Garage)

**Feature:** Gestión de vehículos del usuario ("garage"): CRUD, vehículo principal, archivado/desarchivado, eliminación permanente (soft-delete), integración SOAT/RTM en creación, sincronización de sesión.
**Referencia:** `docs/features/vehicles.md` (actualizada 2026-07-04)
**Estado:** Pendiente de corrida (checklist recién planificado)

> **Semántica de "Auto-PASS":** significa que existe un test automatizado (`flutter test`) que ya cubre ese comportamiento y corre en verde como parte de la suite `test/features/vehicles/` — **no** significa que el caso se haya verificado en esta corrida específica de Patrol/manual. Los casos marcados como "Patrol (pendiente de corrida)" dependen de `integration_test/*_patrol_test.dart`, que requieren device + seed + backend real y **no** se ejecutan con `flutter test`; su resultado real está pendiente hasta que se corran explícitamente (ver sección 11).

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Una cuenta con sesión Firebase válida que llegue a Home sin fricciones (`qa1@gmail.com` / `qa2@gmail.com`, password `Test123.`).
- [ ] Al menos 2 vehículos **activos** (no archivados): uno marcado como principal (`isMainVehicle: true`) y al menos un "otro vehículo".
- [ ] Al menos 1 vehículo **archivado** para probar la sección "Archivados" y el flujo de restaurar.
- [ ] Una cuenta (o momento) sin ningún vehículo registrado, para probar el estado vacío del garage (puede ser una cuenta nueva de prueba o requiere borrar todos los vehículos de una cuenta secundaria).
- [ ] Al menos un vehículo con SOAT vigente/por vencer/vencido asignado, para revisar los badges de documentos en el detalle.
- [ ] La marca "Honda" (u otra) presente en `ColombiaMotosBrandsData.brands` (`lib/core/data/colombia_motos_brands_data.dart`) para el autocomplete de marca.
- [ ] Un vehículo con mantenimientos registrados (para el detalle: último completado / próximo programado).
- [ ] Acceso a 2 cuentas distintas para probar `VehicleSessionSync` (logout de una, login de otra, sin reiniciar la app).

---

## 1. Agregar vehículo — campos requeridos y opcionales

> Desde Home → tab Garaje → botón "Agregar" (o CTA del estado vacío) → formulario de creación.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Abre el formulario de creación sin llenar ningún campo y toca "Guardar moto" | El formulario no guarda; se marcan como inválidos los campos requeridos (nombre, marca, modelo, año, kilometraje) | | |
| 1.2 | Llena únicamente los campos requeridos (nombre, marca vía autocomplete seleccionando una sugerencia, modelo, año, kilometraje) y guarda | Snackbar de éxito, vuelve al garage y el vehículo nuevo aparece en la lista (como principal si es el primero, o en "Otros vehículos") | 🤖 Patrol (`integration_test/vehicles_add_edit_patrol_test.dart`, pendiente de corrida con seed, ver sección 11) | |
| 1.3 | En el campo de marca, escribe texto libre SIN seleccionar ninguna sugerencia del autocomplete y trata de guardar | El validador rechaza el guardado (ej. "Selecciona una opción válida"); no se crea el vehículo | | |
| 1.4 | Llena además los campos opcionales (placa, VIN, color, motor, potencia, torque, peso, fecha de compra, foto de portada) y guarda | El vehículo se crea con todos esos datos visibles luego en el detalle | | |
| 1.5 | Sube una foto de portada durante la creación | La imagen se sube a Firebase Storage (`vehicles/{vehicleId}/cover.jpg`) y se ve en la tarjeta del garage y en el detalle | | |
| 1.6 | Ingresa un kilometraje inválido (negativo o con letras) en el campo de kilometraje actual | El campo muestra error de validación y no permite guardar | | |
| 1.7 | Ingresa un año fuera de rango razonable (ej. futuro lejano o muy antiguo, si el campo valida rango) | El formulario valida o acepta según las reglas definidas; no debe crashear | | |

---

## 2. Editar vehículo

> Desde el garage, abre las opciones de un vehículo existente → "Editar vehículo".

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Abre "Editar vehículo" sobre un vehículo activo, cambia el nombre y guarda | Snackbar de éxito, el garage refleja el nuevo nombre inmediatamente sin recargar manualmente | 🤖 Patrol (`integration_test/vehicles_add_edit_patrol_test.dart`, pendiente de corrida con seed, ver sección 11) | |
| 2.2 | Cambia otros campos (marca, modelo, año, placa, specs) y guarda | Los cambios persisten y se ven reflejados en el detalle del vehículo | | |
| 2.3 | Abre "Editar vehículo" sobre un vehículo **archivado** | Aparece un diálogo de advertencia indicando que el vehículo está archivado | 👤 Manual (diálogo de advertencia visual; requiere confirmar copy exacto en pantalla real) | |
| 2.4 | Continúa editando ese vehículo archivado y guarda sin revertir el archivado explícitamente | El vehículo queda **desarchivado automáticamente** tras guardar (auto-unarchive silencioso, sin segunda confirmación) | | |
| 2.5 | Reemplaza la foto de portada de un vehículo ya existente | La nueva imagen sobrescribe la anterior en Storage y se refleja en la UI | | |
| 2.6 | Cambia el kilometraje del vehículo a un valor MENOR al actual desde el formulario de edición | Verificar comportamiento: el formulario de edición permite escribir cualquier valor (a diferencia de `VehicleCubit.updateMileage`, que solo se usa para actualizaciones rápidas desde mantenimiento) — confirmar si el backend/API acepta o rechaza el retroceso | | |

---

## 3. Marcar como principal

> Desde el garage, en un vehículo activo que NO sea el principal, abre sus opciones → "Marcar como principal".

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Marca un "otro vehículo" activo como principal | La tarjeta principal del garage pasa a ser ese vehículo; el anterior principal aparece ahora en "Otros vehículos" | 🤖 Patrol (`integration_test/vehicles_archive_setmain_patrol_test.dart`, pendiente de corrida con seed, ver sección 11) | |
| 3.2 | Verifica en otros features que consumen `currentVehicle` (Home, selector de inscripción a evento, mantenimiento) tras el cambio | El nuevo vehículo principal aparece como el sugerido por defecto en esos flujos (dentro de la misma sesión de la app, sin reiniciar) | 👤 Manual (requiere navegar a 3 features distintos y confirmar visualmente) | |
| 3.3 | Verifica que un vehículo archivado NO tenga la opción "Marcar como principal" disponible | El bottom sheet de un vehículo archivado solo muestra "Restaurar" y "Eliminar permanentemente" | | |

---

## 4. Archivar

> Desde el garage, en un vehículo activo, abre sus opciones → "Archivar" → confirmar en el modal.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Archiva un vehículo que NO es el principal | Confirmación en modal, snackbar "Vehículo archivado", desaparece de la lista activa y aparece en la sección "Archivados" | 🤖✅ Auto-PASS para la invocación del use case de archivado Y el snackbar "Vehículo archivado" (`test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart` — TC-bs-1, extendido: verifica que confirmar el modal invoca `archiveUseCase` y que aparece `find.text('Vehículo archivado')` tras `archiveSuccess`; `test/features/vehicles/presentation/delete/cubit/vehicle_action_cubit_test.dart` — grupo `archiveVehicle` verifica el cambio de `isArchived` en el cubit aislado) + 👤 Manual SOLO para la transición visual en el garage completo (desaparece de la lista activa / aparece en "Archivados" — ningún test renderiza el garage completo con ambas secciones a la vez) + 🤖 Patrol (`integration_test/vehicles_archive_setmain_patrol_test.dart`, pendiente de corrida con seed, ver sección 11) | |
| 4.2 | Archiva el vehículo que SÍ es el principal | El backend/`VehicleCubit.archiveLocally` promueve automáticamente otro vehículo activo como principal; ya no queda ningún vehículo sin principal si hay al menos uno activo | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` — TC-veh-13, TC-veh-16, `_promoteNewMain`) | |
| 4.3 | Archiva el ÚNICO vehículo activo que queda (sin ningún otro vehículo activo) | El garage debe manejar el caso sin principal disponible sin errores (revisar si queda vacío o muestra el estado correspondiente) | | |
| 4.4 | Cancela el diálogo de confirmación de archivado | El vehículo NO se archiva, sigue en la lista activa | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart` — TC-bs-2) | |
| 4.5 | Verifica que un vehículo archivado se muestra correctamente en el detalle en modo "solo lectura" | El detalle de un vehículo archivado no permite editar campos ni acciones sobre mantenimiento; las tarjetas de SOAT/RTM se muestran pero no son tocables si están vacías | 🤖✅ Auto-PASS SOLO para las tarjetas de SOAT/RTM en modo archivado (`test/features/vehicles/presentation/vehicle_documents_archived_mode_test.dart` — con datos navegan, vacías no son tocables) + 👤 Manual para "el detalle no permite editar campos ni acciones sobre mantenimiento" (`vehicle_detail_nav_test.dart` — TC-nav-1/2/3 solo verifica la visibilidad del botón "Editar" según `isArchived`, no bloquea acciones de mantenimiento ni ningún otro campo editable) | |

---

## 5. Desarchivar

> Desde la sección "Archivados" del garage, abre las opciones de un vehículo archivado → "Restaurar".

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Desarchiva un vehículo cuando YA existe otro vehículo activo marcado como principal | Snackbar "Vehículo restaurado"; el vehículo vuelve a la lista activa como "otro vehículo" (NO se convierte en principal, porque ya hay uno) | 🤖✅ Auto-PASS para "NO se convierte en principal cuando ya hay uno" (`test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` — TC-veh-15, grupo `unarchiveLocally`: arma el escenario con otro vehículo activo como principal y confirma que se preserva) Y para el snackbar "Vehículo restaurado" (`test/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet_test.dart` — "Fila 5.1: tapping 'Restaurar'...": stubea `unarchiveUseCase` con éxito, toca la opción "Restaurar" y confirma `find.text('Vehículo restaurado')` tras `unarchiveSuccess`) + 🤖 Patrol (`integration_test/vehicles_archive_setmain_patrol_test.dart`, pendiente de corrida con seed, ver sección 11) | |
| 5.2 | Desarchiva un vehículo cuando NO existe ningún otro vehículo activo con `isMainVehicle: true` | El vehículo recién desarchivado se promueve automáticamente a principal | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` — grupo `unarchiveLocally`) | |
| 5.3 | Tras desarchivar, revisa el botón de edición y las tarjetas de documentos en el detalle | Vuelven a ser interactuables (ya no en modo solo lectura) | | |

---

## 6. Eliminar permanentemente (soft-delete)

> Desde la sección "Archivados" (un vehículo debe estar archivado primero), abre sus opciones → "Eliminar permanentemente".

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6.1 | Toca "Eliminar permanentemente" sobre un vehículo archivado | Se muestra `ConfirmationDialog` con el nombre del vehículo en el mensaje | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/delete/vehicle_permanent_delete_dialog_test.dart` — TC-perm-A) | |
| 6.2 | Cancela el diálogo | El vehículo NO se elimina; el use case de borrado no se invoca | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/delete/vehicle_permanent_delete_dialog_test.dart` — TC-perm-C) | |
| 6.3 | Confirma la eliminación | Snackbar de éxito (verde), el vehículo desaparece de toda la UI (incluida la sección "Archivados"); `VehicleCubit.deleteLocally` se invoca con el id correcto | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/delete/vehicle_permanent_delete_flow_test.dart` — TC-3-1, TC-3-2, TC-3-4 para el snackbar de éxito y la invocación de `deleteLocally` sobre un cubit mockeado; `test/features/vehicles/presentation/garage/garage_archived_delete_full_test.dart` — TC-arch-delete-1 renderiza el garage COMPLETO con un `VehicleCubit` real (no mockeado), elimina permanentemente el vehículo archivado a través del flujo real de UI (bottom sheet → `ConfirmationDialog` → confirmar) y verifica que desaparece de la sección "Archivados", que la sección colapsa por completo al quedar vacía, y que el vehículo activo no se ve afectado) | |
| 6.4 | Simula un error de red durante la eliminación | Se muestra un snackbar de error; el vehículo NO se elimina de la lista local (`deleteLocally` no se llama) | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/delete/vehicle_permanent_delete_flow_test.dart` — TC-7B) | |
| 6.5 | Verifica en la base de datos (o vía backend) tras eliminar un vehículo con mantenimientos asociados | El backend hace soft-delete del vehículo (`isDeleted: true`, fila conservada) y de sus mantenimientos relacionados; las inscripciones a eventos que referencian ese vehículo vía `vehicleSummary` mantienen su snapshot congelado (no se rompen) | 👤 Manual (requiere acceso a BD/backend para verificar el soft-delete real, no solo la UI) | |
| 6.6 | Verifica que NO existe forma de eliminar un vehículo directamente desde la lista activa (sin archivarlo primero) | El bottom sheet de un vehículo activo no ofrece "Eliminar permanentemente"; esa opción solo aparece tras archivar | | |

---

## 7. Ver garage (modo lectura general)

> Desde Home → tab Garaje, con una cuenta con vehículos en distintos estados.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 7.1 | Abre el garage con al menos 1 vehículo principal, 1 "otro vehículo" activo y 1 archivado | Se ve el header "Mi Garaje", la tarjeta principal destacada, la lista de "Otros vehículos" y la sección colapsable "Archivados" con el conteo correcto | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/garage/garage_full_layout_test.dart` — TC-garage-1: renderiza `GaragePageView` COMPLETO (no la sección de archivados en aislamiento) con 1 vehículo principal + 1 otro vehículo activo + 1 archivado a la vez, y verifica el header "Mi Garaje", `GarageMainVehicleCard`, la sección "OTROS VEHÍCULOS" y la sección "ARCHIVADOS" con conteo=1, todo en el mismo árbol) | |
| 7.2 | Expande/colapsa la sección "Archivados" | Se despliegan/ocultan correctamente los vehículos archivados sin afectar la lista activa | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart` — TC-arch-3 cubre "expande"; TC-arch-6 (nuevo) toca el header una segunda vez y verifica que la sección COLAPSA de nuevo, ocultando otra vez la lista de vehículos archivados) | |
| 7.3 | Toca la tarjeta de un vehículo (principal u otro) | Navega al detalle del vehículo (`VehicleDetailPage`) mostrando specs, último mantenimiento, próximo programado y tarjetas de documentos (SOAT/RTM) | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/garage/garage_navigate_to_detail_test.dart` — TC-nav-detail-1: desde el garage completo, toca la tarjeta principal, verifica la navegación real vía `go_router` a `VehicleDetailPage`, y confirma que se renderizan las specs (marca/modelo), el último mantenimiento completado y el próximo programado (con datos de un `VehicleMaintenancesCubit` real conectado a un use case mockeado) y las tarjetas SOAT/RTM ambas en estado "Vigente") | |
| 7.4 | Vuelve del detalle al garage | El garage hace refresh y refleja cualquier cambio hecho en el detalle (ej. mantenimiento agregado, kilometraje actualizado) | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/garage/garage_navigate_to_detail_test.dart` — TC-nav-detail-2: navega al detalle, invoca `VehicleCubit.updateMileage` sobre el MISMO `VehicleCubit` real compartido por ambas pantallas (simulando un cambio de kilometraje), vuelve al garage con el botón "atrás", y confirma que la tarjeta principal del garage muestra el kilometraje actualizado) + `test/features/vehicles/presentation/vehicle_detail_odometer_listener_test.dart` — C7a/C7b complementa verificando la actualización in-situ dentro del propio detalle | |

---

## 8. Integración SOAT/RTM en la creación de vehículo

> Durante el formulario de creación de un vehículo nuevo, en la sección de documentos (slots SOAT y RTM).

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8.1 | Crea un vehículo adjuntando solo una foto/documento de SOAT (sin llenar los demás datos manuales) | Al guardar, navega a `SoatManualCapturePage` (flujo "con imagen") en lugar de crear el SOAT directamente | 👤 Manual (el grupo `soatLocalPath state` de `vehicle_form_cubit_soat_test.dart` solo cubre el estado del campo `soatLocalPath` — initial null, `setSoatFromLocalPath`, `clearSoatDocument`, `isEditing` — sin ninguna mención de `SoatManualCapturePage` ni de la navegación) | |
| 8.2 | Crea un vehículo llenando los datos manuales de SOAT (aseguradora, fechas) sin adjuntar imagen | Al guardar el vehículo, se crea también el SOAT vía `upsertSoat` sin imagen, y el usuario ve un snackbar de éxito antes de volver al garage | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/form/widgets/vehicle_form_pending_documents_test.dart` — "8.2/8.4": empuja un estado `VehicleFormState` con `vehicleResult.data` + `pendingManualSoat` al `VehicleFormCubit` mockeado dentro de un `VehicleFormView` real, y verifica que `VehicleRepository.upsertSoat` se invoca con el `vehicleId` del vehículo recién creado y que aparece el snackbar "Guardado exitosamente") | |
| 8.3 | Crea un vehículo llenando los datos manuales de RTM (CDA, fechas) sin adjuntar imagen | Al guardar el vehículo, se crea también la RTM vía `SaveTecnomecanicaUseCase`; el detalle del vehículo muestra el badge/estado RTM correspondiente | 🤖✅ Auto-PASS SOLO para la invocación de `SaveTecnomecanicaUseCase` con el `vehicleId` correcto (`test/features/vehicles/presentation/form/widgets/vehicle_form_pending_documents_test.dart` — "8.3/8.4") + 👤 Manual para "el detalle del vehículo muestra el badge/estado RTM correspondiente" (no ejercitado en este test, ver 8.6 para badges) | |
| 8.4 | Crea un vehículo con SOAT Y RTM pendientes al mismo tiempo (ambos con datos manuales) | Ambos documentos se guardan en el mismo paso post-creación (`_savePendingDocumentsAndPop`) y ambos aparecen en el detalle | 🤖✅ Auto-PASS SOLO para "ambos documentos se guardan en el mismo paso" (`test/features/vehicles/presentation/form/widgets/vehicle_form_pending_documents_test.dart` — "8.4": con `pendingManualSoat` y `pendingRtm` simultáneos, verifica que tanto `upsertSoat` como `SaveTecnomecanicaUseCase` se invocan exactamente una vez cada uno) + 👤 Manual para "ambos aparecen en el detalle" (requiere navegar al detalle tras crear, no cubierto) | |
| 8.5 | Simula que la subida de la imagen del documento (SOAT o RTM) falla, pero los datos del documento sí se guardan | El documento se guarda SIN `documentUrl` (catch silencioso); se muestra una advertencia genérica, sin especificar cuál subida falló | 👤 Manual (requiere forzar un fallo de red específico en la subida de imagen a Firebase Storage) | |
| 8.6 | Revisa las tarjetas de SOAT y RTM en el detalle del vehículo con distintos estados (vigente, por vencer, vencido, sin documento) | Cada tarjeta muestra el badge correspondiente sin bloquear la carga de la otra (carga independiente) | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/vehicle_documents_badges_test.dart`) | |
| 8.7 | Toca la tarjeta de SOAT/RTM con datos existentes | Navega a `AppRoutes.soatStatus` / `AppRoutes.tecnomecanicaStatus` respectivamente | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/vehicle_documents_tap_navigation_test.dart`) | |
| 8.8 | Toca la tarjeta de SOAT vacía (sin documento) | Se abre el flujo `SoatEntryFlow.start` (bottom sheet), no una navegación directa a `soatStatus` | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/vehicle_documents_tap_navigation_test.dart` — C6b) | |
| 8.9 | En un vehículo archivado, toca las tarjetas de SOAT/RTM vacías | No son tocables (modo solo lectura); con datos, sí navegan | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/vehicle_documents_archived_mode_test.dart`) | |

---

## 9. Sincronización con sesión (`VehicleSessionSync`)

> Requiere 2 cuentas distintas con garages diferentes.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9.1 | Inicia sesión con la cuenta A (con vehículos), navega al garage, cierra sesión y entra con la cuenta B (con otros vehículos o sin ninguno) SIN reiniciar la app | El garage de la cuenta A NO queda visible; se limpia (`clearVehicles()`) y se recarga con los vehículos de la cuenta B (`fetchMyVehicles()`) | 👤 Manual (requiere flujo completo de logout/login con 2 cuentas reales; no cubierto por Patrol tests actuales) | |
| 9.2 | Tras el logout de la cuenta A, antes de loguear la cuenta B, revisa el estado del garage/Home | No se muestra ningún vehículo residual de la cuenta anterior (ni en Home ni en el garage) | | |
| 9.3 | Inicia sesión, ve al Home directamente (sin abrir el tab Garaje) | `MainShell` dispara `fetchMyVehicles()` al montar, por lo que el vehículo principal aparece en `HomeGarageSection` sin necesidad de visitar el garage primero | | |

---

## 10. Casos de borde

### 10A. Sin vehículos (estado vacío)

> Cuenta sin ningún vehículo registrado.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 10A.1 | Abre el garage de una cuenta sin vehículos | Se muestra el estado vacío "No tienes vehículos registrados" con un CTA para agregar el primero, sin errores en pantalla | | |
| 10A.2 | Desde ese estado vacío, agrega el primer vehículo | El nuevo vehículo se selecciona automáticamente como principal (`addVehicleLocally` selecciona el primero) | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` — TC-veh-8 (nuevo), grupo `addVehicleLocally`: parte de `currentVehicle == null` con la lista vacía, agrega el primer vehículo y confirma que `currentVehicle?.id` queda apuntando a ese vehículo recién agregado) | |
| 10A.3 | Revisa el selector de vehículo en "Inscribirse a un evento" y en "Agregar mantenimiento" sin vehículos | Muestra el estado vacío correspondiente en lugar de un dropdown vacío o un crash | | |

### 10B. Catálogo de marcas

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 10B.1 | En el campo de marca, escribe una marca que SÍ existe en `ColombiaMotosBrandsData.brands` (ej. "Honda") | El autocomplete sugiere y permite seleccionar la marca | 🤖 Patrol (`integration_test/vehicles_add_edit_patrol_test.dart`, pendiente de corrida con seed, ver sección 11) | |
| 10B.2 | Escribe una marca que NO existe en el catálogo | No aparece ninguna sugerencia seleccionable; el validador impide guardar con texto libre no confirmado | | |
| 10B.3 | Escribe parcialmente el nombre de una marca (ej. "Hon") | El autocomplete filtra y muestra coincidencias parciales | | |

### 10C. Kilometraje regresivo

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 10C.1 | Desde el flujo de "Agregar mantenimiento", intenta registrar un kilometraje MENOR al `currentMileage` actual del vehículo | `VehicleCubit.updateMileage` ignora el valor porque `newMileage <= currentMileage`; el odómetro del vehículo NO retrocede | 🤖✅ Auto-PASS (`test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` — grupo `updateMileage`, TC-10C-1 y TC-10C-1b: verifican que con `newMileage` menor o igual al actual el odómetro no cambia y `UpdateVehicleUseCase` nunca se invoca) | |
| 10C.2 | Registra un kilometraje MAYOR al actual desde mantenimiento | El odómetro del vehículo se actualiza de forma optimista (local primero, luego API); si la API falla, no hay rollback visible hasta el próximo `fetchMyVehicles()` | 🤖✅ Auto-PASS para la actualización optimista y la invocación del use case (`test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` — TC-10C-2, TC-10C-2b: confirma que el estado local se actualiza de forma síncrona/optimista antes de que la llamada al use case se resuelva, usando un mock con `Future.delayed`, y TC-10C-3 cubre el caso `vehicleId` omitido) + 👤 Manual para "si la API falla, no hay rollback visible" (no simulado en estos tests; ver 10C.3) | |
| 10C.3 | Provoca una falla de red justo después de un `updateMileage` optimista exitoso localmente | El valor local queda desincronizado hasta el próximo fetch; verificar que no se muestra un error confuso al usuario | 👤 Manual (comportamiento documentado como aceptable hoy en `vehicles.md` §13; no automatizado — requeriría forzar `UpdateVehicleUseCase` a fallar y confirmar que no se muestra ningún error visible al usuario, ya que `updateMileage` no maneja el `Either` de retorno) | |

---

## 11. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código, logs o consola de desarrollo.

| # | Verificación | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 11.1 | Correr `flutter test test/features/vehicles/` | Todos los tests del feature pasan en verde | |
| 11.2 | Correr `dart analyze` | Sin issues nuevos en los archivos de `lib/features/vehicles/` | |
| 11.3 | Correr `integration_test/vehicles_add_edit_patrol_test.dart` con datos de seed reales | El flujo de agregar + editar vehículo pasa de punta a punta | |
| 11.4 | Correr `integration_test/vehicles_archive_setmain_patrol_test.dart` con datos de seed reales (≥2 vehículos activos) | El flujo de marcar principal + archivar + desarchivar pasa de punta a punta | |
| 11.5 | Correr `integration_test/vehicles_patrol_test.dart` | El login llega al garage y muestra vehículos o el estado vacío sin errores | |
| 11.6 | Revisar `VehicleRepositoryImpl._vehicleRequest()` contra el body real enviado al backend en un `PATCH /vehicles/{id}` | El body no incluye `color`, `soatStatus`, `soatExpiryDate`, `isMainVehicle`, `id`, `createdAt`, `updatedAt` (campos omitidos intencionalmente). 🤖✅ Auto-PASS SOLO para el path de CREACIÓN (`POST`), y solo para 2 de los 7 campos enumerados (`color`, `isMainVehicle`) (`test/features/vehicles/data/repository/vehicle_repository_impl_test.dart:139-141`, dentro de `group('addVehicle', ...)` — assertea `containsKey('licensePlate')`, `containsKey('color')` y `containsKey('isMainVehicle')` en `isFalse`; la aserción de `licensePlate` prueba la remoción genérica de campos nulos, no uno de los 7 campos de esta fila). El `group('updateVehicle', ...)` (el `PATCH` que esta fila describe) no tiene ninguna aserción sobre el body enviado. 👤 Manual/gap para: el path de actualización (`PATCH`) completo, y para los campos `soatStatus`, `soatExpiryDate`, `id`, `createdAt`, `updatedAt` en ambos paths | |
| 11.7 | Verificar en BD que `permanentlyDeleteVehicle` hace soft-delete (no borra la fila) y que los mantenimientos relacionados también quedan soft-deleted | El vehículo y sus mantenimientos siguen existiendo en la tabla con `isDeleted: true`, no se pierden datos | |
| 11.8 | Revisar cobertura de `VehicleCubit.updateMileage` | 🤖✅ Auto-PASS — cubierto por el grupo `updateMileage` en `test/features/vehicles/presentation/cubit/vehicle_cubit_test.dart` (TC-10C-1, TC-10C-1b, TC-10C-2, TC-10C-2b, TC-10C-3, y el caso "no current vehicle"). Ver sección 10C | |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–6 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (secciones 7–10), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 4, 5 o 6 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
