# PO Proposal — archive-vehicle-soft-delete

_Generated: 2026-06-16T16:10:11Z_

---

## Fases propuestas

| # | Título | Goal | Repositorio(s) |
|---|--------|------|----------------|
| 1 | Backend: soft-delete e integridad de datos | El usuario puede eliminar un vehículo sin perder el historial de inscripciones ni mantenimientos. | `vehicles-ms`, `api-gateway`, `rideglory-contracts` |
| 2 | Diseño Pencil: garaje con sección de archivados | El diseñador (y el PO) aprueba la UX de archivado antes de que se toque una sola línea de Flutter. | `rideglory.pen` |
| 3 | Flutter: archivar y restaurar vehículos | El usuario puede mover un vehículo al archivo y restaurarlo desde la sección de archivados del garaje. | `Rideglory` (Flutter) |
| 4 | Flutter: eliminación permanente desde archivados | El usuario puede eliminar definitivamente un vehículo archivado, con confirmación explícita. | `Rideglory` (Flutter) |
| 5 | Flutter: vehículo principal siempre coherente | El vehículo principal que se muestra en la pantalla de inicio refleja en todo momento el que el usuario tiene seleccionado, sin requerir reiniciar la app. | `Rideglory` (Flutter) |

---

### Fase 1 — Backend: soft-delete e integridad de datos

**Goal:** El usuario puede eliminar un vehículo sin perder el historial de inscripciones ni mantenimientos.

El endpoint `DELETE /api/vehicles/:id` deja de borrar el registro físico y en su lugar lo marca como eliminado lógicamente (`isDeleted: true`). Los listados del garaje excluyen vehículos archivados y eliminados. Los eventos y mantenimientos históricos que referenciaban ese vehículo permanecen intactos. Si el vehículo eliminado era el principal, el backend promueve automáticamente el siguiente vehículo activo y no archivado como nuevo principal.

**Historias de usuario:**

- **US-1-1:** Como propietario, cuando elimino un vehículo, mis inscripciones a eventos pasados siguen mostrando el nombre y datos correctos del vehículo.
- **US-1-2:** Como propietario, si elimino mi vehículo principal, el sistema me asigna automáticamente otro como principal (o ninguno si no quedan activos).
- **US-1-3:** Como propietario, los vehículos que he archivado o eliminado no aparecen mezclados con los activos en mi garaje.

**Criterios de aceptación:**
- `GET /api/vehicles/my` no devuelve vehículos con `isArchived: true` ni con `isDeleted: true`.
- `DELETE /api/vehicles/:id` responde con éxito sin borrar la fila de la base de datos (verificable consultando directo a Prisma con `findUnique` incluyendo `isDeleted: true`).
- Llamar a `getVehicleById` con el id de un vehículo eliminado sigue devolviendo el nombre (para eventos históricos).
- `dart analyze` y `flutter test` pasan en verde (sin cambios Flutter en esta fase).

---

### Fase 2 — Diseño Pencil: garaje con sección de archivados

**Goal:** El diseñador (y el PO) aprueba la UX de archivado antes de que se toque una sola línea de Flutter.

Diseñar en `rideglory.pen` (archivo único de diseño del proyecto) los siguientes estados de la pantalla de garaje:

1. **Garaje con vehículos archivados:** sección colapsable "Archivados (N)" al pie de la lista activa.
2. **Menú contextual — vehículo activo:** opción "Archivar" en lugar de "Eliminar".
3. **Menú contextual — vehículo archivado:** opciones "Restaurar" y "Eliminar permanentemente".
4. **Confirmación de archivado:** diálogo/bottom-sheet explicando que el vehículo se ocultará pero el historial se conserva.
5. **Confirmación de eliminación permanente:** diálogo de advertencia destructiva (acción irreversible).

Esta fase no produce código. Produce frames aprobados en Pencil que las fases 3 y 4 implementan.

**Criterios de aceptación:**
- Los frames están en `rideglory.pen` con nombres claros.
- El PO (usuario) los revisa y da aprobación explícita por escrito antes de continuar.

---

### Fase 3 — Flutter: archivar y restaurar vehículos

**Goal:** El usuario puede mover un vehículo al archivo y restaurarlo desde la sección de archivados del garaje.

Implementar la UI aprobada en Fase 2. El usuario ve una sección colapsable "Archivados (N)" al pie del garaje. Desde el menú contextual de un vehículo activo puede archivarlo (con confirmación). Desde el menú de un archivado puede restaurarlo. El estado del garaje se actualiza instantáneamente sin recargar la pantalla.

**Historias de usuario:**

- **US-3-1:** Como propietario, puedo archivar un vehículo desde el menú del garaje para ocultarlo de mi lista activa, con un mensaje de confirmación que me explica que el historial se conserva.
- **US-3-2:** Como propietario, veo mis vehículos archivados en una sección colapsable al pie del garaje y puedo expandirla para revisarlos.
- **US-3-3:** Como propietario, puedo restaurar un vehículo archivado para que vuelva a mi lista activa.
- **US-3-4:** Como propietario, si archivo mi vehículo principal, el sistema selecciona automáticamente otro activo como principal (o ninguno si no quedan).

**Criterios de aceptación:**
- Al archivar, el vehículo desaparece de la lista activa y aparece bajo "Archivados (N)" en la misma sesión sin navegar.
- Al restaurar, el vehículo vuelve a la lista activa de inmediato.
- El contador "(N)" en el encabezado de archivados refleja el número real.
- Si el vehículo archivado era el principal, el garaje muestra el nuevo principal correctamente.
- `dart analyze` y `flutter test` pasan en verde.

---

### Fase 4 — Flutter: eliminación permanente desde archivados

**Goal:** El usuario puede eliminar definitivamente un vehículo archivado, con confirmación explícita.

El menú contextual de un vehículo archivado expone "Eliminar permanentemente". Al tocar esta opción aparece un diálogo de advertencia destructiva. Si el usuario confirma, el vehículo se elimina del backend (soft-delete de Fase 1) y desaparece del garaje. Esta acción depende del endpoint creado en Fase 1.

**Historias de usuario:**

- **US-4-1:** Como propietario, puedo eliminar permanentemente un vehículo archivado desde su menú contextual, después de confirmar una advertencia que me avisa que la acción es irreversible.
- **US-4-2:** Como propietario, al intentar eliminar permanentemente, si cancelo el diálogo de confirmación, el vehículo permanece archivado sin cambios.

**Criterios de aceptación:**
- El botón "Eliminar permanentemente" solo es visible en vehículos archivados (nunca en activos).
- El diálogo de confirmación describe la acción como irreversible y muestra el nombre del vehículo.
- Tras confirmar, el vehículo desaparece de la sección de archivados en la misma sesión.
- `dart analyze` y `flutter test` pasan en verde.

---

### Fase 5 — Flutter: vehículo principal siempre coherente

**Goal:** El vehículo principal que se muestra en la pantalla de inicio refleja en todo momento el que el usuario tiene seleccionado, sin requerir reiniciar la app.

`HomeGarageSection` deja de depender del prop `mainVehicle` pasado desde `HomeLoaded` (que puede quedar stale) y lee siempre de `VehicleCubit` como única fuente de verdad. Esto elimina el escenario en que el inicio muestra un vehículo principal desactualizado tras un cambio de main en el garaje.

**Historias de usuario:**

- **US-5-1:** Como propietario, cuando establezco un vehículo como principal en el garaje, la pantalla de inicio refleja ese cambio de inmediato sin necesidad de cerrar y reabrir la app.
- **US-5-2:** Como propietario, si archivo o elimino mi vehículo principal, la pantalla de inicio actualiza el vehículo mostrado (o lo oculta si no hay ninguno activo) en la misma sesión.

**Criterios de aceptación:**
- Después de cambiar el vehículo principal en el garaje y regresar al inicio, la sección de inicio muestra el nuevo principal.
- Después de archivar el vehículo principal y regresar al inicio, la sección de inicio ya no muestra ese vehículo.
- No se introducen llamadas HTTP adicionales al backend para lograr esto (es puramente estado en memoria).
- `dart analyze` y `flutter test` pasan en verde.

---

## Supuestos

1. **Archive vía PATCH existente:** `ArchiveVehicleUseCase` y `UnarchiveVehicleUseCase` llaman a `PATCH /api/vehicles/:id` con `{ isArchived: true/false }`. Este mecanismo ya funciona en el backend y no requiere cambios en Fase 1.
2. **`isDeleted` no viaja al cliente:** Flutter no necesita el campo `isDeleted` en `VehicleModel`. Los vehículos eliminados simplemente dejan de aparecer en `GET /api/vehicles/my`.
3. **Soft-delete de mantenimientos al eliminar:** `maintenances-ms` ya tiene `softDeleteAllByVehicleId`. El api-gateway lo encadena al nuevo endpoint de soft-delete de vehículos, igual que hacía con el hard-delete.
4. **Diseño Pencil es bloqueante para Fase 3:** Ningún widget nuevo de la sección de archivados se implementa sin aprobación explícita del diseño. (Regla del proyecto: diseñar antes de implementar para UI nueva.)
5. **Fase 1 es bloqueante para Fase 4:** Sin el endpoint `DELETE /api/vehicles/:id` que haga soft-delete, la eliminación permanente desde Flutter no puede completarse.
6. **Fases 3 y 5 son independientes entre sí:** Pueden planificarse en paralelo, aunque la coherencia del vehículo principal (Fase 5) mejora la experiencia completa del flujo de archivado.
7. **Promoción automática de principal al archivar:** Si el usuario archiva su vehículo principal, el backend elige automáticamente el siguiente vehículo activo y no archivado como nuevo principal. Si no existe ninguno, el campo `isMainVehicle` queda vacío.
8. **No se necesitan nuevas dependencias de pub:** Todas las dependencias Flutter requeridas ya están en `pubspec.yaml`.

---

## Riesgos

1. **Migración `isDeleted` en producción con datos existentes:** Al agregar `isDeleted Boolean @default(false)` a Prisma, la migración en una base de datos con filas existentes debe ejecutarse primero en local y ser verificada antes de cualquier despliegue. Un fallo aquí deja el backend sin servicio. _Mitigación:_ ejecutar `prisma migrate dev` en local, revisar SQL generado, y desplegar en ventana de bajo tráfico.
2. **Ruta del endpoint cambia en Flutter (`/hard-delete/:id` → `/:id`):** `VehicleService` (Retrofit) actualmente apunta a `/api/vehicles/hard-delete/{id}`. Si el backend cambia la ruta antes de que Flutter se actualice, el botón de eliminar retorna 404. _Mitigación:_ coordinar el despliegue de Fase 1 (backend) con el release de Fase 4 (Flutter) o mantener el endpoint viejo como alias temporal.
3. **`VehicleCard.onArchive`/`onUnarchive` callbacks huérfanos:** Los callbacks existen en el widget pero ningún parent los pasa. Si en Fase 3 se decide wirearlos desde el card directamente (en lugar del bottom-sheet), puede generarse lógica duplicada. _Mitigación:_ el wiring debe centralizarse en `GarageOptionsBottomSheet`, no en `VehicleCard`.
4. **Stale del main en HomeCubit con múltiples cubits:** Si el fix de Fase 5 se demora, un usuario que cambia su vehículo principal podría ver datos inconsistentes en la pantalla de inicio hasta la próxima carga. El riesgo es bajo (la app no tiene usuarios reales aún), pero puede generar confusión durante QA. _Mitigación:_ priorizar Fase 5 inmediatamente después de Fase 3.
5. **Diseño Pencil no disponible o MCP caído:** Según las reglas del proyecto, si el MCP de Pencil está caído, la Fase 2 (y por ende Fase 3) debe bloquearse hasta restablecer el acceso. _Mitigación:_ no iniciar la implementación de Fase 3 hasta tener confirmación de diseño aprobado.
6. **Conteo de vehículos al crear incluye archivados:** El bug menor en `createVehicle` (cuenta archivados/eliminados para decidir si asignar `isMainVehicle: true`) puede llevar a que un nuevo vehículo no sea marcado como principal si el único otro vehículo del owner estaba archivado. _Mitigación:_ corregir el conteo en Fase 1 junto con los demás filtros.

---

## Criterios de éxito globales

1. **Integridad de datos garantizada:** Ningún `DELETE` desde el cliente Flutter borra físicamente una fila de vehículo. Las inscripciones y mantenimientos históricos permanecen referenciando el nombre correcto del vehículo.
2. **Ciclo de vida completo funcional:** Un vehículo puede pasar por `activo → archivado → restaurado → archivado → eliminado permanentemente` sin errores ni estados inconsistentes.
3. **Garaje limpio:** La lista activa muestra solo vehículos con `isArchived: false, isDeleted: false`. Los archivados tienen su sección separada y colapsable.
4. **Pantalla de inicio coherente:** El vehículo principal mostrado en Home siempre coincide con el seleccionado en VehicleCubit, sin requerir acciones del usuario.
5. **Sin regresiones:** `dart analyze` y `flutter test` pasan en verde al final de cada fase. No se introducen nuevas dependencias innecesarias.
6. **UX aprobada en Pencil antes de implementar:** La sección de archivados y los menús contextuales diferenciados están diseñados y aprobados antes de escribir código Flutter.
