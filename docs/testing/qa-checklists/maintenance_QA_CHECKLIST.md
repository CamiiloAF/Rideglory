# Checklist de QA — Feature Maintenance (mantenimientos de vehículo)

**Feature:** CRUD de mantenimientos (`lib/features/maintenance/`) — modo completado vs programado, scoping por vehículo activo, orden por urgencia, próximo servicio/kilometraje
**Fases cubiertas:** N/A (feature ya en `main`; checklist de QA general, no ligado a una fase de `rg-exec`)
**Estado:** Pendiente de corrida

---

> **Nota sobre "🤖✅ Auto-PASS":** este checklist es un documento de *planificación* de QA, no un reporte de una corrida específica. La marca "🤖✅ Auto-PASS" significa **"existe un test automatizado que cubre este caso puntual y hoy pasa en verde"**, verificado leyendo el test citado — NO significa "se ejecutó en esta corrida de QA". Para confirmar que sigue en verde al momento de usar este checklist, corré `flutter test` (ver 9.1). Las marcas "👤 Manual" indican casos sin cobertura automatizada que requieren verificación humana (podrían automatizarse a futuro); las marcas "🚫" indican casos intrínsecamente no automatizables (verificación visual subjetiva, apertura de intents externos del SO, etc.).

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Una cuenta de piloto (`qa1@gmail.com` o equivalente) con **al menos dos vehículos** no archivados, para poder probar el scoping por vehículo activo y el selector `MaintenanceVehicleSelector`.
- [ ] Uno de esos vehículos con **kilometraje actual conocido** (por ejemplo 10.000 km) para poder crear registros con kilometraje mayor/menor y verificar el banner de actualización de odómetro.
- [ ] Un vehículo **sin ningún mantenimiento previo** (recién agregado al garage), para probar el estado vacío de la lista.
- [ ] Un vehículo con al menos:
  - 1 mantenimiento `scheduled` **vencido** (`nextOdometer` o `nextDate` ya superado por el kilometraje/fecha actual).
  - 1 mantenimiento `scheduled` **próximo** (dentro del umbral de 500 km o 30 días).
  - 1 mantenimiento `scheduled` **al día** (fuera de ambos umbrales).
  - 1 mantenimiento `completed` (servicio ya realizado).
  - Esto permite verificar el orden por urgencia (overdue → next → upToDate → completed) en una sola lista.
- [ ] Acceso a la app en modo dev/staging con Dio logging habilitado, para poder ver el body/query real de las requests `GET/POST/PATCH/DELETE /maintenances/...` en consola.

---

## 1. Crear mantenimiento completado

> Desde "Mantenimientos" (vía menú de Perfil o desde el detalle de un vehículo), toca el botón "+".

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Toca "+" y selecciona un tipo (ej. "Cambio de aceite") en el wizard, luego "Continuar" | Se abre el formulario en modo **"Completado"** por defecto | 🤖✅ Auto-PASS (`integration_test/maintenance_crud_patrol_test.dart`) | |
| 1.2 | Completa kilometraje, taller y notas; deja la fecha precargada; guarda con "Guardar Registro" | El registro se crea y aparece en la lista con el kilometraje ingresado como marcador | 🤖✅ Auto-PASS (`integration_test/maintenance_crud_patrol_test.dart`; `test/features/maintenance/domain/use_cases/add_maintenance_use_case_test.dart`) | |
| 1.3 | Repite el flujo pero ahora además llena "próximo kilometraje" (ej. 5.000 km) o "próxima fecha" antes de guardar | El backend puede devolver 2 registros (el completado + un `scheduled` auto-creado); ambos deben reflejarse en la lista sin necesidad de refrescar manualmente | 🤖✅ Auto-PASS (`test/features/maintenance/domain/use_cases/add_maintenance_use_case_test.dart` — camino feliz retorna lista; `test/features/maintenance/presentation/cubit/maintenances_cubit_test.dart` TC-maint-5 `addMaintenanceLocally`) | |
| 1.4 | Guarda un mantenimiento completado **sin** próximo kilometraje ni próxima fecha | Solo se crea 1 registro (sin scheduled asociado); no aparece ningún registro "fantasma" en la lista | 👤 Manual (requiere inspección visual de la lista tras guardar; no hay assert automatizado del conteo exacto de tarjetas nuevas) | |
| 1.5 | Deja el campo de kilometraje vacío e intenta guardar | El formulario bloquea el guardado y marca el campo como requerido (no se envía la request) | 👤 Manual (no se encontró test de validación de campo requerido en `maintenance_form_cubit_test.dart`) | |
| 1.6 | Guarda un mantenimiento completado con costo y notas vacíos (campos opcionales) | Se guarda exitosamente sin exigir esos campos | 👤 Manual (campos opcionales; no hay test explícito de "guardar sin costo/notas") | |

---

## 2. Crear mantenimiento programado (scheduled)

> Desde el wizard de tipo, en el formulario cambia el toggle a modo "Programado".

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Selecciona un tipo, continúa, y cambia `MaintenanceStatusToggle` a "Programado" | El formulario oculta los campos exclusivos de completado (fecha de servicio, kilometraje de servicio, taller) y solo pide próximo kilometraje/próxima fecha | 🤖✅ Auto-PASS (`test/features/maintenance/presentation/form/widgets/maintenance_form_content_test.dart` — grupo "MaintenanceFormContent — visibilidad de campos por modo": verifica que en modo Completado se muestran `AppDatePicker`/`AppMileageField`/taller, que al tocar "Programado" desaparecen, y que reaparecen al volver a "Completado") | |
| 2.2 | Completa solo "próximo kilometraje" (sin próxima fecha) y guarda | Se crea 1 registro `scheduled` con `nextOdometer` calculado (kilometraje base del vehículo + el relativo ingresado) | 🤖✅ Auto-PASS (`test/features/maintenance/domain/use_cases/add_maintenance_use_case_test.dart`) | |
| 2.3 | Completa solo "próxima fecha" (sin kilometraje) y guarda | Se crea 1 registro `scheduled` con `nextDate`, sin exigir kilometraje | 👤 Manual (no hay test que cubra explícitamente "solo fecha, sin km" en el form cubit) | |
| 2.4 | Verifica el registro recién creado en la lista | Aparece agrupado según su urgencia calculada (ver sección 6), no simplemente al final o al inicio por fecha de creación | 👤 Manual (requiere ver el resultado visual de `_compareByUrgency` en la lista real) | |

---

## 3. Editar mantenimiento

> Desde el detalle de un mantenimiento (completado o programado), toca "Editar".

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Abre el detalle de un mantenimiento existente y toca "Editar" | Se abre el formulario precargado con los datos actuales (tipo, modo, fecha, kilometraje, taller, notas) | 🤖✅ Auto-PASS (`integration_test/maintenance_crud_patrol_test.dart`) | |
| 3.2 | Cambia las notas y guarda | El detalle refleja el cambio inmediatamente al volver, sin necesidad de refrescar la lista completa | 🤖✅ Auto-PASS (`integration_test/maintenance_crud_patrol_test.dart`; `test/features/maintenance/domain/use_cases/update_maintenance_use_case_test.dart`) | |
| 3.3 | Cambia el tipo de mantenimiento (ej. de "Cambio de aceite" a "Revisión de frenos") | El cambio se guarda y la lista refleja el nuevo tipo, ícono y color asociados | 👤 Manual (no hay test de widget que verifique el ícono/color tras editar el tipo) | |
| 3.4 | Cambia el modo de "Completado" a "Programado" (o viceversa) en la edición | El formulario ajusta los campos visibles y guarda correctamente el nuevo modo | 👤 Manual (test de form cubit cubre el toggle de modo aislado, pero no un flujo completo de edición cambiando de modo) | |
| 3.5 | Edita un mantenimiento y cancela sin guardar (botón atrás) | Los cambios no se persisten; el detalle sigue mostrando los datos originales | 👤 Manual (no hay test automatizado del flujo de cancelación) | |

---

## 4. Eliminar mantenimiento

> Desde el detalle de un mantenimiento, toca "Eliminar".

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Toca "Eliminar" en el detalle | Aparece un `ConfirmationDialog` pidiendo confirmar | 🤖✅ Auto-PASS (`integration_test/maintenance_crud_patrol_test.dart`) | |
| 4.2 | Confirma la eliminación | El registro desaparece de la lista al volver; `MaintenanceDeleteCubit` emite `success(deletedId)` | 🤖✅ Auto-PASS (`integration_test/maintenance_crud_patrol_test.dart` para el flujo e2e; `test/features/maintenance/presentation/cubit/maintenance_delete_cubit_test.dart` grupo "MaintenanceDeleteCubit — máquina de estados", TC-maint-del-s1: verifica `loading` → `success(deletedId: 'maint-99')` con el id correcto) | |
| 4.3 | Cancela el diálogo de confirmación | El registro NO se elimina; se mantiene visible en el detalle y en la lista | 👤 Manual (no hay assert del camino de cancelación en `maintenance_delete_cubit_test.dart`, solo se testea el camino de éxito/error del cubit) | |
| 4.4 | Elimina un registro sin conexión (o forzando un error del backend) | Se muestra un error legible; el registro NO desaparece de la lista local | 🤖✅ Auto-PASS parcial (`test/features/maintenance/presentation/cubit/maintenance_delete_cubit_test.dart` TC-maint-del-s2: verifica `loading` → `error(message: 'No se pudo borrar')` con mensaje legible del `DomainException` propagado). 👤 Manual/gap restante: no hay assert de que el registro siga en la lista local en `MaintenancesPage` — eso depende del listener en la UI, no cubierto por widget test | |
| 4.5 | Elimina el registro `completed` que tiene un `scheduled` auto-creado asociado | Verificar qué pasa con el `scheduled` asociado (¿se elimina en cascada en backend o queda huérfano?) — comportamiento a confirmar con backend | 👤 Manual (no documentado ni testeado; requiere verificación de negocio) | |

---

## 5. Ver detalle de mantenimiento

> Toca cualquier tarjeta de la lista de mantenimientos.

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Abre el detalle de un mantenimiento `completed` | Se muestra fecha de servicio, kilometraje, taller, costo y notas (si existen); título "Detalle de mantenimiento" | 🤖✅ Auto-PASS (`integration_test/maintenance_crud_patrol_test.dart`) | |
| 5.2 | Abre el detalle de un mantenimiento `scheduled` | Se muestra la tarjeta de "próximo servicio" con la fecha/kilometraje objetivo; no se muestran campos exclusivos de completado (taller, costo) | 👤 Manual (no hay widget test de `maintenance_detail_view.dart` / `maintenance_next_service_card.dart`) | |
| 5.3 | Abre el detalle de un mantenimiento `scheduled` vencido (`overdue`) | El estado visual indica claramente que está vencido (color/ícono de alerta) | 🚫 No automatizable (verificación visual subjetiva de color/ícono de alerta; no hay widget test de `maintenance_type_card`/`maintenance_next_service_card` para el estado overdue) | |
| 5.4 | Abre el detalle de un mantenimiento sin notas ni taller (campos opcionales vacíos) | La pantalla no muestra secciones vacías raras ni texto "null"; oculta o muestra un placeholder adecuado | 👤 Manual (no hay test de widget para el caso de campos nulos en el detalle) | |

---

## 6. Ver lista ordenada por urgencia

> Entra a "Mantenimientos" de un vehículo con registros overdue, next, upToDate y completed simultáneamente (ver pre-condiciones).

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6.1 | Revisa el orden de la lista | El orden es: vencidos (`overdue`) primero, luego próximos (`next`), luego al día (`upToDate`), y los `completed` siempre al final — sin importar su fecha | 👤 Manual (`_compareByUrgency` de `MaintenancesCubit` no tiene test unitario dedicado; solo hay tests de `calculateStatus` aislado, TC-maint-8/9) | |
| 6.2 | Dentro del mismo grupo de urgencia (ej. dos "next"), revisa el desempate | Se ordenan por fecha más reciente primero (`serviceDate ?? nextDate ?? createdDate` descendente) | 👤 Manual (mismo gap que 6.1 — no hay test de `_compareByUrgency`) | |
| 6.3 | Verifica que un mantenimiento `completed` reciente no aparezca antes que uno `scheduled` overdue más viejo | El `completed` siempre queda después de todos los `scheduled`, sin importar la fecha | 👤 Manual (mismo gap — falta test unitario de la función de comparación) | |
| 6.4 | Aplica un filtro de "Solo vencidos" (`statusFilter`) desde el bottom sheet de filtros | La lista se re-filtra localmente (sin nueva request HTTP) y solo muestra los `overdue` | 👤 Manual (no hay widget test de `maintenance_filters_bottom_sheet.dart` ni assert de que no dispare HTTP) | |
| 6.5 | Busca por nombre de tipo en el buscador (ej. "aceite") | Filtra correctamente por el label del tipo; confirma que NO filtra por taller, notas ni kilometraje (limitación conocida) | 🤖✅ Auto-PASS solo para el filtrado positivo por tipo (`test/features/maintenance/presentation/cubit/maintenances_cubit_test.dart` TC-maint-7 — verifica que buscar "aceite" retorna solo registros `oilChange`). 👤 Manual para la parte negativa: el test NO verifica que la búsqueda ignore taller, notas o kilometraje | |

---

## 7. Scoping por vehículo activo (usuario con varios vehículos)

> Entra a "Mantenimientos" desde el menú de Perfil (sin `initialVehicleId`) con una cuenta que tenga 2+ vehículos.

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 7.1 | Abre la lista sin filtro de vehículo (todos) | Se ven mantenimientos de todos los vehículos, con fan-out de requests (`getMaintenancesByUserId`) | 🤖✅ Auto-PASS (`test/features/maintenance/domain/use_cases/get_maintenance_list_use_case_test.dart` — grupo "sin vehicleId") | |
| 7.2 | Usa `MaintenanceVehicleSelector` para filtrar a un único vehículo | Se dispara un único `GET /maintenances/vehicle/{id}` (no fan-out); el header muestra la `summary` de ese vehículo (último servicio, próximo servicio) | 🤖✅ Auto-PASS (`test/features/maintenance/domain/use_cases/get_maintenance_list_use_case_test.dart` — grupo "con vehicleId"; `test/features/maintenance/presentation/cubit/maintenances_cubit_test.dart` cubre el filtrado pero no el header de summary con widget test) | |
| 7.3 | Con el filtro acotado a 2+ vehículos específicos (no todos, pero más de 1) | Vuelve a hacer fan-out (múltiples requests), y el header de summary NO se muestra (solo aplica para exactamente 1 vehículo) | 👤 Manual (no hay test explícito para exactamente "2 de N" vehículos seleccionados en el filtro) | |
| 7.4 | Entra a "Mantenimientos" desde el detalle de un vehículo específico (`initialVehicleId` en la ruta) | El selector de vehículo NO se muestra; la lista ya viene preacotada a ese vehículo | 👤 Manual (no hay widget test de `MaintenancesPage(initialVehicleId: ...)`; solo documentado en código) | |
| 7.5 | Agrega un mantenimiento nuevo mientras el filtro está acotado a un vehículo | Se invalida la `summary` cacheada de ese vehículo (`_summariesByVehicleId.remove`) y el header se recalcula en el siguiente fetch | 👤 Manual (no hay test unitario que verifique la invalidación de la summary tras `addMaintenanceLocally`) | |

---

## 8. Casos de borde

### 8A. Vehículo sin mantenimientos previos

> Entra a "Mantenimientos" de un vehículo recién agregado, sin ningún registro.

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8A.1 | Abre la lista de ese vehículo | Se muestra un estado vacío (`EmptyStateWidget` o similar) invitando a crear el primer mantenimiento, sin errores en consola | 🤖✅ Auto-PASS (`test/features/maintenance/presentation/cubit/maintenances_cubit_test.dart` TC-maint-4 — emite `ResultState.empty()`) | |
| 8A.2 | Crea el primer mantenimiento desde ese estado vacío | El flujo de creación funciona igual que con vehículos que ya tienen historial | 👤 Manual (flujo de creación desde estado vacío no cubierto explícitamente por el patrol test, que usa el vehículo principal ya existente) | |

### 8B. Kilometraje inconsistente

> Ingresa valores de kilometraje que no tienen sentido cronológico o físico.

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8B.1 | Crea un mantenimiento `completed` con `odometerAtService` MENOR al kilometraje actual del vehículo | Verificar si el form/backend bloquea o solo advierte (banner de actualización de odómetro se dispara solo si el nuevo valor es MAYOR) | 👤 Manual/gap — el test citado (`test/features/maintenance/presentation/form/cubit/maintenance_form_cubit_test.dart`, grupo `shouldChangeVehicleMileage`, "retorna false si el nuevo kilometraje es igual o menor") solo prueba el helper puro `shouldChangeVehicleMileage(a, b)` que decide si mostrar el banner; NO responde si el formulario o el backend bloquean el guardado de un odómetro menor al actual — eso no está cubierto | |
| 8B.2 | Crea un mantenimiento `completed` con kilometraje MAYOR al actual del vehículo | Se muestra el `MaintenanceMileageUpdateBanner` sugiriendo actualizar el kilometraje del vehículo | 🤖✅ Auto-PASS (`test/features/maintenance/presentation/form/cubit/maintenance_form_cubit_test.dart` — "retorna true si el nuevo kilometraje es mayor") | |
| 8B.3 | Acepta la sugerencia del banner de actualización de kilometraje | El kilometraje del vehículo se actualiza en el feature `vehicles` (verificar en garage/detalle del vehículo) | 👤 Manual (integración cross-feature; no cubierto por tests de `maintenance`) | |
| 8B.4 | Crea un `scheduled` con `nextOdometer` MENOR al kilometraje actual del vehículo (próximo servicio "en el pasado") | Verificar que se calcule como `overdue` inmediatamente al guardarlo, sin crashear | 🤖✅ Auto-PASS (`test/features/maintenance/presentation/cubit/maintenances_cubit_test.dart` TC-maint-8 `calculateStatus` — overdue cuando el odómetro excede `nextOdometer`) | |
| 8B.5 | Ingresa un kilometraje negativo o con caracteres no numéricos en el campo de kilometraje | El campo rechaza el valor / muestra error de validación, no se envía la request | 👤 Manual (no hay test de validación de formato del campo `currentMileage`) | |

### 8C. Auto-creación de scheduled tras completed (respuesta con 2 registros)

| # | Acción | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8C.1 | Al guardar un completado con próximo recordatorio, revisa el pop de la pantalla de formulario | Se hace pop con la lista completa (1 o 2 registros), no solo el primero — evita perder el `scheduled` auto-creado | 🤖✅ Auto-PASS (`test/features/maintenance/domain/use_cases/add_maintenance_use_case_test.dart` — retorna `List<MaintenanceModel>` completa) | |
| 8C.2 | Verifica en la lista que ambos registros (completed + scheduled auto-creado) aparecen sin duplicados ni pérdidas | `addMaintenancesLocally` inserta ambos correctamente | 👤 Manual (no hay test unitario de `addMaintenancesLocally` con lista de 2 elementos; solo existe `addMaintenanceLocally` con 1 elemento, TC-maint-5) | |

---

## 9. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código, logs o consola de desarrollo.

| # | Verificación | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 9.1 | Correr `flutter test test/features/maintenance/` | Todos los tests del feature pasan en verde | |
| 9.2 | Correr `dart analyze` | Sin issues nuevos en `lib/features/maintenance/` | |
| 9.3 | Revisar el body de `POST /maintenances/vehicle/{vehicleId}` en el log de Dio al crear un completado con próximo recordatorio | Incluye `nextKmInterval` Y `nextOdometer` (ambos, ver `_buildCreateBody()`) | |
| 9.4 | Revisar la query de `GET /maintenances/vehicle/{vehicleId}` al aplicar filtros de tipo y rango de fechas | `types` viaja como array de `JsonValue` strings (ej. `OIL_CHANGE`), `startDate`/`endDate` en ISO8601 UTC | |
| 9.5 | Confirmar en consola que el filtro `MaintenanceFilters.sortBy` no tiene ningún efecto real en el orden mostrado | Es un campo vestigial (documentado en `docs/features/maintenance.md` §12); si alguna UI lo expone, no cambia el orden — riesgo de confundir al usuario | |
| 9.6 | Correr `integration_test/maintenance_crud_patrol_test.dart` con datos de seed reales (`qa1@gmail.com`, vehículo principal) | El flujo completo de crear → editar → eliminar pasa sin timeouts | |
| 9.7 | Revisar que `AnalyticsEvents.maintenanceHistoryViewed/maintenanceAdded/maintenanceUpdated/maintenanceDeleted` se disparan con los params correctos y sin datos sensibles (ej. sin notas completas) | Confirmado por `test/features/maintenance/presentation/cubit/maintenance_analytics_test.dart` | |
| 9.8 | Revisar logs al crear/editar un mantenimiento con `nextOdometer`/`nextDate` ambos nulos | No debe aparecer ningún error de "Null check operator used on a null value" en consola | |

---

## Fixes requeridos

Ambos gaps priorizados en la auditoría anterior de este checklist ya fueron resueltos con tests automatizados nuevos:

1. ~~**[Alta] `MaintenanceDeleteCubit` sin test directo de su máquina de estados**~~ — Resuelto. `test/features/maintenance/presentation/cubit/maintenance_delete_cubit_test.dart` ahora tiene un grupo dedicado "MaintenanceDeleteCubit — máquina de estados" (TC-maint-del-s1/s2/s3) que asserta `loading` → `success(deletedId)` en el camino feliz, `loading` → `error(message)` en el camino de falla, y el error directo (sin `loading`) cuando falta el id. Filas 4.2/4.4 actualizadas a Auto-PASS.
2. ~~**[Media] Falta widget test de `MaintenanceStatusToggle` en modo "Programado"**~~ — Resuelto. Nuevo `test/features/maintenance/presentation/form/widgets/maintenance_form_content_test.dart` monta `MaintenanceFormView` real con `MaintenanceFormCubit`/`VehicleCubit` provistos y verifica que los campos de fecha de servicio, kilometraje y taller se ocultan al cambiar a "Programado" y reaparecen al volver a "Completado". Fila 2.1 actualizada a Auto-PASS.

No quedan gaps de alta/media prioridad pendientes de este checklist; los restantes marcados 👤 Manual son de menor severidad (validaciones de formato, integraciones cross-feature, casos visuales subjetivos) o 🚫 no automatizables.

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–4 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (secciones 6–8), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3 o 4 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
