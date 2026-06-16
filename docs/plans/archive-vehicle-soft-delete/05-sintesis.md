# Síntesis final — archive-vehicle-soft-delete

_Generated: 2026-06-16T16:19:44Z_
_PO consolidation of: 02-po-proposal.md + 03-architect-review.md + 04-plan-review.md_
_Revision: Correcciones Auditor Opus aplicadas (2026-06-16)_

---

## Overview

Implementar soft-delete de vehículos con ciclo de vida completo: el usuario puede archivar, restaurar y eliminar permanentemente un vehículo sin perder el historial de inscripciones ni mantenimientos. La pantalla de inicio refleja siempre el vehículo principal vigente. El plan comprende 5 fases secuenciales con dos posibles paralelismos (Fases 1+2, y Fases 3+5 si hay capacidad).

La secuencia de ejecución recomendada para un desarrollador solo es:

```
Fase 1 (Backend)  ──────────────────────────────── bloqueante para Fase 4
Fase 2 (Diseño)   ──────────────────────────────── bloqueante para Fase 3
Fase 5 (Home coherente)  ← ejecutar primero entre Flutter; independiente, menor riesgo
Fase 3 (Archivar/restaurar)  ← requiere Fase 2 aprobada
Fase 4 (Eliminación permanente)  ← requiere Fase 1 + Fase 3
```

---

## Cambios aplicados

Los siguientes ajustes de la revisión de arquitectura (AJ), revisión de plan y correcciones del Auditor Opus fueron integrados en las fases:

| Ajuste | Origen | Integrado en |
|--------|--------|-------------|
| AJ-1: Crear `DELETE /api/vehicles/my/:vehicleId` nuevo; mantener `hard-delete/:id` como alias temporal hasta que Fase 4 salga a producción | Architect | Fase 1 |
| AJ-2: Criterio de desempate de promoción de main: `findFirst({ orderBy: { createdAt: 'desc' }, where: { isArchived: false, isDeleted: false } })`; Flutter replica este orden con tie-break determinista por `id` cuando `createdAt` es null | Architect | Fases 1 y 3 |
| AJ-3: Renombrar `VehicleRepository.deleteVehicle` → `permanentlyDeleteVehicle` en interfaz, impl y use case; actualizar `VehicleDeleteCubit` | Architect | Fase 4 |
| AJ-4: Fases 3 y 5 son independientes; orden recomendado para un solo developer: Fase 5 → Fase 3 → Fase 4 | Architect | Orden de fases |
| AJ-5: Ampliar `VehicleDeleteCubit` (cubit scoped) para manejar `archive/unarchive/permanentDelete` con estado freezed unificado; evitar `VehicleArchiveCubit` separado | Architect | Fases 3 y 4 |
| [plan] Fase 1: CA que especifica que el cubit hace re-fetch completo de la lista tras DELETE (no depender del response body para inferir la promoción de main) | Plan Reviewer | Fase 1 |
| [plan] Fase 4: Gate de entrada explícito — endpoint `DELETE /api/vehicles/my/:vehicleId` disponible y respondiendo en entorno de prueba antes de iniciar | Plan Reviewer | Fase 4 |
| [plan] Fase 4: CA — CTA de confirmar queda deshabilitado (no-op) mientras el request está en curso (estado loading del cubit) | Plan Reviewer | Fase 4 |
| [plan] Fase 5: CA — si `VehicleCubit` está en `Initial` o `Loading` cuando `HomeGarageSection` se renderiza, muestra placeholder/skeleton sin crash | Plan Reviewer | Fase 5 |
| [plan] Fase 2: Listar explícitamente los 8 estados de pantalla requeridos en Pencil, incluyendo decisión sobre "Editar"/"Agregar mantenimiento" para archivados | Plan Reviewer | Fase 2 |
| [plan] Fases 3/4: Listar en el archivo de fase las claves `app_es.arb` nuevas requeridas antes de implementar (no hardcodear strings) | Plan Reviewer | Fases 3 y 4 |
| [opus] Fase 5: `HomeLoaded` es un `sealed class` manual (home_state.dart), NO freezed. Eliminar toda mención a 'cambio freezed' o 'regenerar build_runner' en el contexto de Fase 5. El CA especifica los 4 consumidores reales en home_cubit.dart (líneas 32, 37, 52, 63) y home_scaffold.dart (línea 54) | Auditor Opus | Fase 5 |
| [opus] Fase 3: Reconciliar claves l10n con las ya existentes en app_es.arb. Reutilizar `vehicle_archiveVehicle` → "Archivar" y decidir explícitamente sobre `vehicle_unarchiveVehicle` (dice "Desarchivar" pero el label de UI es "Restaurar"). Listar solo claves realmente faltantes | Auditor Opus | Fase 3 |
| [opus] Fase 3: Especificar tie-break determinista para `createdAt null` en criterio de promoción de main local: nulls al final, luego desempate por `id` (lexicográfico asc) | Auditor Opus | Fase 3 |
| [opus] Fase 4: `ConfirmationDialog` YA soporta `DialogActionType.danger`. Fijar CA en usar `ConfirmationDialog` con `confirmType: DialogActionType.danger`. Eliminar ambigüedad "verificar si soporta tono destructivo / usar AppDialog directamente" | Auditor Opus | Fase 4 |
| [opus] Fase 3: Aclarar que `VehicleCard` ya invoca `onArchive`/`onUnarchive` vía su PopupMenu (vehicle_card.dart:258-262). El cambio es únicamente pasar los callbacks desde `GarageOptionsBottomSheet`/`GarageVehiclesContent`. No re-implementar el wiring dentro del card | Auditor Opus | Fase 3 |
| [opus] Fases 3/4/5: Agregar widget tests mínimos a los CA para que 'flutter test en verde' sea verificable y no vacuo | Auditor Opus | Fases 3, 4 y 5 |

---

## Lista final de fases

| # | Título | Nivel | Por qué ese nivel |
|---|--------|-------|-------------------|
| 1 | Backend: soft-delete e integridad de datos | **full** | Migración de datos en producción, nuevo endpoint autenticado, cambio de contrato rideglory-api (vehicles-ms + api-gateway + rideglory-contracts), blast radius alto si `isDeleted` filtra mal o promoción de main falla |
| 2 | Diseño Pencil: garaje con sección de archivados | **lite** | Fase de diseño puro — sin código de producción, sin contratos, sin migraciones; reversible; una sola herramienta (Pencil MCP) |
| 3 | Flutter: archivar y restaurar vehículos | **normal** | Feature acotada con lógica de cubit y UI (sección colapsable, bifurcación de menú, promoción de main local); riesgo medio; sin migraciones ni cambios de contrato en esta fase; usa PATCH existente |
| 4 | Flutter: eliminación permanente desde archivados | **normal** | Feature acotada que depende del nuevo endpoint de Fase 1; incluye renombrado de interfaz de dominio (`permanentlyDeleteVehicle`); riesgo medio controlado por el gate de entrada de despliegue |
| 5 | Flutter: vehículo principal siempre coherente | **lite** | Refactor de estado puro (2 archivos: home_cubit.dart + home_scaffold.dart más home_state.dart), sin nueva UI, sin contratos, sin migraciones, sin code-gen (HomeLoaded es sealed class manual); reversible; baja complejidad |

---

## Detalle de fases con ajustes integrados

### Fase 1 — Backend: soft-delete e integridad de datos

**Goal:** El usuario puede eliminar permanentemente un vehículo sin perder historial de inscripciones ni mantenimientos. El endpoint de eliminación es autenticado y verifica ownership.

**Nivel:** full

**Cambios clave vs propuesta original:**
- Se crea `DELETE /api/vehicles/my/:vehicleId` (nuevo, autenticado, owner-check) en lugar de convertir `hard-delete/:id`.
- `hard-delete/:id` se mantiene como alias temporal hasta que Fase 4 Flutter salga a producción (mitiga R-1 de despliegue descoordinado).
- Criterio de desempate de promoción de main documentado: `findFirst({ orderBy: { createdAt: 'desc' }, where: { isArchived: false, isDeleted: false } })`.
- Bug en `createVehicle` corregido: el conteo excluye `isArchived: true` y `isDeleted: true`.

**Criterios de aceptación:**
- `GET /api/vehicles/my` excluye vehículos con `isArchived: true` OR `isDeleted: true`.
- `DELETE /api/vehicles/my/:vehicleId` responde 200 sin borrar la fila (verificable vía `findUnique` con `isDeleted: true` en Prisma).
- `findByIdOrNull` (usado por events-ms) NO filtra `isDeleted` — los snapshots históricos permanecen accesibles.
- Si el vehículo eliminado era principal, el backend promueve el siguiente activo no archivado por `createdAt desc`; si no existe ninguno, `isMainVehicle` queda vacío.
- **[plan]** El response de `DELETE` no necesita incluir el nuevo `mainVehicle`: Flutter hace re-fetch completo de la lista (`fetchMyVehicles`) tras recibir 200. Esta decisión elimina la complejidad de interpretar el body del response para inferir la promoción.
- `prisma migrate dev` genera SQL no destructivo (`DEFAULT false`); migración verificada localmente antes de despliegue.
- `dart analyze` y `flutter test` pasan en verde (sin cambios Flutter en esta fase).

---

### Fase 2 — Diseño Pencil: garaje con sección de archivados

**Goal:** El diseñador (y el PO) aprueba la UX de archivado antes de que se toque una sola línea de Flutter.

**Nivel:** lite

**Cambios clave vs propuesta original:**
- Los 8 estados de pantalla a cubrir están listados explícitamente (ver abajo).
- Se requiere decisión explícita sobre "Editar" y "Agregar mantenimiento" en vehículos archivados.

**8 estados de pantalla requeridos en Pencil:**
1. Garaje sin archivados — sección "Archivados" oculta o con estado vacío.
2. Garaje con archivados, sección colapsada — header "Archivados (N)" visible, 44px mínimo de alto, área táctil completa en ancho.
3. Garaje con archivados, sección expandida — lista de VehicleCards archivadas (opacidad reducida o chip "Archivado").
4. Menú contextual vehículo activo — "Establecer como principal" (condicional), "Editar", "Agregar mantenimiento", "Archivar" (sin "Eliminar").
5. Menú contextual vehículo archivado — "Restaurar", "Eliminar permanentemente" (destructivo, `colorScheme.error`). **Decisión PO:** "Editar" y "Agregar mantenimiento" NO aparecen en vehículos archivados — un vehículo archivado no debe recibir nuevos registros.
6. Diálogo confirmación archivado — tono informativo; resaltar que el historial se conserva; CTA en color primario (naranja, texto oscuro).
7. Diálogo confirmación eliminación permanente — tono destructivo; nombrar el vehículo; describir acción como irreversible; CTA en `colorScheme.error` (texto `onError`, claro — excepción a la regla de texto oscuro sobre naranja porque `colorScheme.error` no es el primario).
8. Estado loading/error inline (skeleton en card o snackbar) para archivar y restaurar.

**Criterios de aceptación:**
- Todos los frames están en `rideglory.pen` con nombres claros.
- La decisión sobre "Editar"/"Agregar mantenimiento" en archivados está documentada en el frame o en un comentario de diseño.
- Touch targets: mínimo 44px en header colapsable, mínimo 48px por celda de menú.
- El PO da aprobación explícita por escrito antes de continuar con Fase 3.

---

### Fase 3 — Flutter: archivar y restaurar vehículos

**Goal:** El usuario puede mover un vehículo al archivo y restaurarlo desde la sección de archivados del garaje.

**Nivel:** normal

**Cambios clave vs propuesta original:**
- `VehicleDeleteCubit` se amplía (no se crea `VehicleArchiveCubit` separado) para manejar `archive`, `unarchive` y — en Fase 4 — `permanentDelete` en un estado freezed unificado. Candidato de nombre: `VehicleActionCubit`.
- Criterio de desempate de promoción de main local: `archiveLocally(id)` filtra vehículos con `isArchived: false`, ordena por `createdAt desc` (nulls al final), con tie-break por `id` lexicográfico ascendente cuando `createdAt` es null. Este orden replica exactamente el `findFirst` del backend y hace el método testeable con aserciones deterministas.
- `VehicleCard` ya invoca `onArchive`/`onUnarchive` vía su PopupMenu (vehicle_card.dart:258-262). El cambio de esta fase es únicamente pasar los callbacks desde el parent (`GarageVehiclesContent` o `GarageOptionsBottomSheet`). No se re-implementa el wiring dentro del card.
- Claves l10n reconciliadas con las ya existentes en `app_es.arb` (ver abajo).

**Claves `app_es.arb`: reconciliación con existentes**

Claves existentes que SE REUTILIZAN (no crear duplicados):
- `vehicle_archiveVehicle` → "Archivar" — usar tal cual para el label del menú de archivar.

Claves existentes que SE ACTUALIZAN (decisión de diseño):
- `vehicle_unarchiveVehicle` → actualmente "Desarchivar". El diseño (Fase 2) usa "Restaurar". **Decisión:** actualizar el valor a `"Restaurar"` para alinearse con la UX aprobada. No crear `vehicle_unarchive` duplicado.

Claves NUEVAS realmente faltantes:
```
vehicle_archivedSection            → "Archivados ({count})"
vehicle_archiveConfirmTitle        → "Archivar vehículo"
vehicle_archiveConfirmMessage      → "El vehículo se ocultará de tu garaje activo. Tu historial de mantenimientos e inscripciones se conserva."
vehicle_archiveConfirmAction       → "Archivar"
vehicle_archiveSuccess             → "Vehículo archivado"
vehicle_archiveError               → "No se pudo archivar el vehículo"
vehicle_unarchiveSuccess           → "Vehículo restaurado"
vehicle_unarchiveError             → "No se pudo restaurar el vehículo"
```

**Criterios de aceptación:**
- Al archivar, el vehículo desaparece de la lista activa y aparece bajo "Archivados (N)" en la misma sesión.
- Al restaurar, el vehículo vuelve a la lista activa de inmediato.
- El contador "(N)" refleja el número real de archivados.
- Si el vehículo archivado era el principal, `VehicleCubit` promueve el siguiente activo por `createdAt desc` (nulls al final, tie-break por `id` asc) antes de emitir estado.
- El wiring de `onArchive`/`onUnarchive` se pasa desde `GarageVehiclesContent`/`GarageOptionsBottomSheet` como callbacks al `VehicleCard`. El card no llama use cases directamente.
- `GarageArchivedSection` y `GarageArchivedHeader` son widgets en archivos propios (un widget por archivo, sin métodos privados que retornen widgets).
- `dart analyze` y `flutter test` pasan en verde.
- **[opus — tests mínimos verificables]** Existen widget tests para `GarageArchivedSection` que cubren: (a) estado vacío (sin vehículos archivados — sección oculta), (b) estado colapsado con contador correcto, (c) estado expandido listando los vehículos archivados. Existen tests para el diálogo de confirmación de archivado (flujo confirmar y flujo cancelar).

---

### Fase 4 — Flutter: eliminación permanente desde archivados

**Goal:** El usuario puede eliminar definitivamente un vehículo archivado, con confirmación explícita e irreversible.

**Nivel:** normal

**Cambios clave vs propuesta original:**
- `VehicleRepository.deleteVehicle` renombrado a `permanentlyDeleteVehicle` en la interfaz de dominio, el repositorio impl, el use case y `VehicleActionCubit` (AJ-3).
- `VehicleService` (Retrofit) usa `@DELETE('${ApiRoutes.myVehicles}/{id}')` apuntando al nuevo endpoint autenticado de Fase 1.
- Gate de entrada explícito: el endpoint debe estar disponible y respondiendo antes de iniciar.
- CTA deshabilitado durante loading (protección anti doble-tap).
- `ConfirmationDialog` ya soporta `DialogActionType.danger` (tono destructivo). Se usa con `confirmType: DialogActionType.danger` — no es necesario verificar ni usar `AppDialog` directamente.

**Claves `app_es.arb` NUEVAS requeridas en esta fase:**
```
vehicle_permanentDeleteTitle       → "Eliminar vehículo permanentemente"
vehicle_permanentDeleteMessage     → "Esta acción es irreversible. El vehículo {vehicleName} y su historial serán eliminados definitivamente."
vehicle_permanentDeleteAction      → "Eliminar permanentemente"
vehicle_permanentDeleteSuccess     → "Vehículo eliminado permanentemente"
vehicle_permanentDeleteError       → "No se pudo eliminar el vehículo"
```

**Gate de entrada:**
- El endpoint `DELETE /api/vehicles/my/:vehicleId` está disponible y respondiendo correctamente en el entorno de prueba (Fase 1 desplegada). Esta condición debe verificarse antes de iniciar la implementación de esta fase.

**Criterios de aceptación:**
- "Eliminar permanentemente" solo es visible en el menú de vehículos archivados (nunca en activos).
- El diálogo de confirmación muestra el nombre del vehículo y describe la acción como irreversible. Se usa `ConfirmationDialog` con `confirmType: DialogActionType.danger` (CTA en `colorScheme.error`, texto `onError`).
- **[plan]** El CTA de confirmar queda deshabilitado (no-op) mientras el cubit está en estado `loading` — protección contra doble-tap.
- Tras confirmar, el vehículo desaparece de la sección "Archivados" en la misma sesión sin navegar.
- `dart analyze` y `flutter test` pasan en verde.
- **[opus — tests mínimos verificables]** Existe widget test para el diálogo destructivo: (a) se muestra el nombre del vehículo, (b) el CTA queda deshabilitado mientras el cubit está en `loading`, (c) cancelar no dispara la eliminación.

---

### Fase 5 — Flutter: vehículo principal siempre coherente

**Goal:** `HomeGarageSection` lee siempre de `VehicleCubit` como única fuente de verdad, eliminando el estado stale de `HomeLoaded.mainVehicle`.

**Nivel:** lite

**Cambios clave vs propuesta original:**
- CA adicional para edge case de cubit en estado `Initial` o `Loading`.
- `HomeLoaded` es un **`sealed class` manual** (definido en `home_state.dart`, parte de `home_cubit.dart`). No es una clase `@freezed`. Eliminar el campo `mainVehicle` de `HomeLoaded` requiere solo editar `home_state.dart` y sus consumidores — no regenerar código con `build_runner`.
- Consumidores reales a actualizar: `home_cubit.dart` (líneas 32, 37, 52, 63) y `home_scaffold.dart` (línea 54). Verificar con `grep -rn 'mainVehicle\|HomeLoaded' lib/` antes de proceder.

**Criterios de aceptación:**
- Después de cambiar el vehículo principal en el garaje y regresar al inicio, la sección de inicio muestra el nuevo principal.
- Después de archivar el vehículo principal y regresar al inicio, la sección de inicio ya no muestra ese vehículo (o muestra el nuevo principal si fue promovido).
- **[plan]** Si `VehicleCubit` está en estado `Initial` o `Loading` cuando `HomeGarageSection` se renderiza, muestra un placeholder/skeleton sin crash.
- No se introducen llamadas HTTP adicionales (el fix es puramente de estado en memoria).
- `dart analyze` y `flutter test` pasan en verde.
- **[opus — tests mínimos verificables]** Existe widget test para `HomeGarageSection` que cubre: (a) `VehicleCubit` en `Initial` muestra placeholder sin crash, (b) `VehicleCubit` en `Loading` muestra skeleton sin crash, (c) tras cambiar el vehículo principal en `VehicleCubit`, `HomeGarageSection` refleja el cambio sin re-fetch HTTP.

---

## Supuestos y riesgos

### Supuestos

1. `PATCH /api/vehicles/:id` con `{ isArchived: true/false }` funciona correctamente en el backend y no requiere cambios en Fase 1.
2. `isDeleted` no viaja al cliente Flutter — los vehículos eliminados simplemente dejan de aparecer en `GET /api/vehicles/my`.
3. `maintenances-ms` ya tiene `softDeleteAllByVehicleId`; el api-gateway lo encadena al nuevo endpoint de soft-delete.
4. La Fase 2 (diseño) es bloqueante para la Fase 3 (implementación Flutter de archivado).
5. La Fase 1 (endpoint) es bloqueante para la Fase 4 (eliminación permanente Flutter).
6. Las Fases 3 y 5 son independientes entre sí — pueden ejecutarse en cualquier orden tras la Fase 2.
7. La promoción automática de main al archivar usa el mismo criterio en backend (`createdAt desc`) y en Flutter (`createdAt desc`, nulls al final, tie-break por `id` asc). Ambas implementaciones deben ser consistentes.
8. No se necesitan nuevas dependencias de pub para las fases Flutter.
9. `ConfirmationDialog` ya soporta `DialogActionType.danger` — confirmado. No se necesita un nuevo variant del shared widget para el diálogo destructivo.
10. `HomeLoaded` es `sealed class` manual (no freezed) — confirmado en `home_state.dart`. Eliminar `mainVehicle` no requiere `build_runner`.

### Riesgos

| # | Riesgo | Prob. | Impacto | Mitigación |
|---|--------|-------|---------|------------|
| R-1 | **Migración `isDeleted` en producción:** `prisma migrate dev` con filas existentes | Baja | Alto | Ejecutar localmente, revisar SQL, esperar verificación humana antes de desplegar (regla del proyecto). `DEFAULT false` es seguro. |
| R-2 | **Despliegue descoordinado backend/Flutter:** Fase 4 necesita endpoint de Fase 1 en producción | Media | Alto | Gate de entrada explícito en Fase 4. Alias `hard-delete/:id` temporal hasta confirmar Fase 4 en producción. |
| R-3 | **Promoción de main local no sincronizada con backend:** Flutter elige un sucesor distinto al backend cuando `createdAt` es null | Media | Medio | Tie-break determinista documentado: nulls al final, desempate por `id` asc. Implementación testeable con fixture de vehículos con `createdAt: null`. |
| R-4 | **`VehicleCard.onArchive`/`onUnarchive` mal wired:** lógica de negocio en el card en lugar del bottom-sheet | Baja | Medio | Los callbacks ya existen en `VehicleCard` (vehicle_card.dart:258-262). El cambio es solo pasarlos desde el parent. Regla: wiring solo en `GarageOptionsBottomSheet`/`GarageVehiclesContent`. |
| R-5 | **`findByIdOrNull` recibe filtro `isDeleted` por error:** rompe snapshots históricos de events-ms | Baja | Alto | Documentado en Fase 1: `findByIdOrNull` NO filtra `isDeleted`. Solo `findByOwnerId` y `findMainVehicleByOwnerId` filtran. |
| R-6 | **MCP Pencil caído bloquea Fase 2 y por tanto Fase 3** | Media | Medio | Regla del proyecto: no iniciar Fase 3 sin aprobación de diseño. Planificar Fase 2 al inicio del sprint. |
| R-7 | **`HomeLoaded.mainVehicle` con consumidores ocultos:** consumidores conocidos son home_cubit.dart:32,37,52,63 y home_scaffold.dart:54 | Baja | Medio | Pre-flight en Fase 5: `grep -rn 'mainVehicle\|HomeLoaded' lib/` para confirmar que no hay otros consumidores antes de modificar. |
| R-8 | **`VehicleActionCubit` scope incorrecto:** si se instancia como singleton en lugar de scoped al bottom-sheet, el estado de loading persiste entre sesiones | Baja | Bajo | `@injectable` (no `@singleton`); provisionar en el árbol de widgets del bottom-sheet, no en `main.dart`. |
| R-9 | **Clave `vehicle_unarchiveVehicle` actualizada rompe otros usos:** si la clave ya se usa en otro contexto con el label "Desarchivar", cambiarla a "Restaurar" introduce regresión | Baja | Bajo | Pre-flight en Fase 3: `grep -rn 'vehicle_unarchiveVehicle' lib/` para mapear todos los puntos de uso antes de cambiar el valor en el ARB. |
