# Architect handoff — Phase 02: Diseño Pencil — Garaje con sección de archivados

**Date:** 2026-06-16T18:30:07Z
**Status:** done

---

## Decisiones

### Flags

| Flag | Valor | Razón |
|------|-------|-------|
| uiChanges | true | 8 frames nuevos en rideglory.pen |
| backendChanges | false | Fase de diseño puro; ningún endpoint nuevo |
| frontendChanges | false | No se toca ningún archivo .dart en esta fase |
| dbChanges | false | Sin cambios de schema; isDeleted/isArchived son de Fase 1 |
| needsDesign | true | Esta fase ES el gate de diseño |

### Decisiones de diseño tomadas

**D-1 — Componentes existentes a reusar (no crear variantes nuevas)**
- `GarageOtherVehicleItem` es la card base para vehículos archivados: aplicar opacidad 0.6 + chip de estado "Archivado" en color neutro. No crear un `ArchivedVehicleItem` nuevo.
- `ConfirmationDialog.show()` cubre ambos diálogos (Frame 6 y Frame 7) con `DialogActionType` diferente. No crear un diálogo nuevo.
- `GarageOtherVehiclesSectionHeader` es la referencia de estilo para el header "Archivados (N)" — la paleta de color y tipografía son reutilizables; el header de archivados agrega el ícono de chevron colapsable.

**D-2 — Menú contextual bifurcado**
- Menú vehículo activo (Frame 4): "Establecer como principal", "Editar", "Agregar mantenimiento", "Archivar". Sin "Eliminar".
- Menú vehículo archivado (Frame 5): "Restaurar", "Eliminar permanentemente". Sin "Editar" ni "Agregar mantenimiento".
- Decisión PO debe quedar anotada visiblemente en Frame 5: _"Un vehículo archivado no debe recibir nuevos registros. Decisión PO: solo Restaurar y Eliminar permanentemente."_

**D-3 — Colores en diálogos**
- Frame 6 (Archivar): `AppModalVariant.info` → relleno `AppColors.primary` (naranja), texto botón `AppColors.darkBgPrimary` (#0D0D0F). El sistema `AppModalVariant.info` ya maneja esto correctamente via `primaryLabelColor = AppColors.darkBgPrimary`.
- Frame 7 (Eliminar permanentemente): `AppModalVariant.destructive` → relleno `AppColors.error`, texto botón `AppColors.textOnDarkPrimary` (blanco). Confirmado en `AppModalVariant.primaryLabelColor`.

**D-4 — Estado loading / error (Frame 8)**
- Loading inline sobre la card: overlay semitransparente con CircularProgressIndicator.adaptive sobre la `GarageOtherVehicleItem` afectada. Shimmer es aceptable como alternativa.
- Error: snackbar al pie (nunca modal), color `colorScheme.error`. Consistente con el patrón de `GarageOptionsBottomSheet` existente.
- Eliminación permanente: CTA deshabilitado (grayed out) durante el request — Frame 7 incluye estado secundario con botón gris.

**D-5 — Sección colapsable "Archivados (N)"**
- Header con chevron (Icons.keyboard_arrow_down / Icons.keyboard_arrow_up).
- Alto mínimo 44 px — validar con snapshot_layout tras diseñar.
- Área táctil = ancho completo del contenedor (no solo el label).
- Se muestra solo cuando hay ≥1 vehículo archivado (no aparecer si lista está vacía).

**D-6 — L10n anticipada para Fase 3**
- Los textos de diálogos definidos en esta fase DEBEN entrar en `app_es.arb` en Fase 3, no en Fase 2.
- Claves identificadas para Fase 3 (no crear en esta fase):
  - `vehicle_archiveConfirmTitle` → "Archivar vehículo"
  - `vehicle_archiveConfirmMessage` → "El vehículo se ocultará de tu garaje activo. Tu historial de mantenimientos e inscripciones se conserva."
  - `vehicle_deleteVehiclePermanently` → "Eliminar permanentemente"
  - `vehicle_deleteVehiclePermanentlyConfirmContent` → "Esta acción es irreversible. El vehículo {vehicleName} y su historial serán eliminados definitivamente."
  - `vehicle_restoreVehicle` → "Restaurar"
  - `garage_archivedVehiclesSection` → "Archivados"
- Nota: `vehicle_archiveVehicle`, `vehicle_unarchiveVehicle`, y `vehicle_archivedVehicle` ya existen en `app_es.arb` (líneas 334–348). Fase 3 debe reusar y posiblemente renombrar `vehicle_unarchiveVehicle` → `vehicle_restoreVehicle` para consistencia UX.

---

## Change map

| Archivo | Acción | Razón | Riesgo |
|---------|--------|-------|--------|
| `rideglory.pen` | modify | Añadir 8 frames nuevos del flujo garaje-archivados | low |

No se toca ningún archivo de código fuente, backend, ni migraciones en esta fase.

---

## Contratos rideglory-api

**Ninguno.** Esta fase no genera ni modifica contratos de API. Los endpoints de archivado (`PATCH /api/vehicles/my/:vehicleId/archive`) y eliminación permanente (`DELETE /api/vehicles/my/:vehicleId`) serán diseñados en Fase 1 (backend). El contrato de Fase 1 debe estar aprobado antes de que Fase 3 (Flutter) comience — pero no antes de que esta Fase 2 termine.

---

## Datos / migraciones

**Ninguno.** Sin cambios en Prisma, Firebase, SharedPreferences ni datos de seeding.

---

## Env

**Ninguno.** Sin variables de entorno nuevas en esta fase.

---

## Riesgos

| # | Riesgo | Prob. | Impacto | Mitigación |
|---|--------|-------|---------|------------|
| R-1 | MCP Pencil caído bloquea toda la fase | Media | Alto | Regla de proyecto: no continuar si MCP está caído; no diseñar en alternativas; registrar y reprogramar |
| R-2 | Frames altos (≥1445px) no exportan correctamente a 1x | Media | Bajo | Usar `export_nodes` a 1x; fallback a `get_screenshot` para revisión |
| R-3 | Solapamiento de nombres con frames existentes del garaje | Baja | Bajo | Pre-flight: listar frames con `batch_get` antes de crear; usar prefijo `[Garaje-Archivados]` |
| R-4 | CTA del Frame 6 usa texto blanco sobre naranja (violación cero-tolerancia) | Baja | Alto | `AppModalVariant.info` → `primaryLabelColor = AppColors.darkBgPrimary` (ya resuelto en código); replicar en Pencil |
| R-5 | PO no disponible para aprobación | Baja | Alto | Sin aprobación no cierra la fase; Fases 1 y 5 pueden avanzar en paralelo |
| R-6 | Diseñador propone `VehicleCard` nueva para archivados (en vez de reusar `GarageOtherVehicleItem` + opacidad) | Media | Medio | PO evalúa impacto en Fase 3; decisión documentada en aprobación; preferencia: reusar existente |

---

## Orden de implementación

Esta fase tiene un solo ejecutor: el agente de Diseño Pencil (Design).

1. Pre-flight MCP: `get_editor_state(include_schema: true)` → `get_guidelines()` → `batch_get` de frames existentes del garaje
2. Frame 1 — Garaje sin archivados (línea base)
3. Frame 2 — Garaje sección "Archivados (N)" colapsada; verificar con `snapshot_layout` (alto header ≥44px)
4. Frame 3 — Garaje sección expandida con cards diferenciadas
5. Frame 4 — Menú contextual vehículo activo; verificar celdas ≥48px
6. Frame 5 — Menú contextual vehículo archivado + nota decisión PO; verificar celdas ≥48px
7. Frame 6 — Diálogo de confirmación de archivado (informativo, CTA naranja + texto oscuro)
8. Frame 7 — Diálogo de eliminación permanente (destructivo, CTA error + estado secundario loading)
9. Frame 8 — Estados loading/error inline
10. Revisión interna con `get_screenshot` / `snapshot_layout` de todos los frames
11. Exportar con `export_nodes` (1 nodo por llamada, 1x) y presentar al PO para aprobación

---

## Superficie de regresión

**Mínima — solo Pencil.** No hay riesgo de regresión en código Flutter ni backend. Los únicos riesgos son:
- Sobrescribir o renombrar frames existentes del garaje (mitigado con pre-flight `batch_get`)
- Crear un archivo `.pen` alternativo (prohibido — verificar que `batch_design` escribe en `rideglory.pen`)

---

## Fuera de alcance

- Código Flutter (widgets, cubits, use cases, DTOs, l10n)
- Cambios en `rideglory-api` o contratos backend
- Migraciones de base de datos o Firebase
- Pantallas fuera del flujo garaje → archivado → restaurar/eliminar
- Creación de archivo `.pen` nuevo
- Definición de l10n keys en `app_es.arb` (se hace en Fase 3)

---

## Change log

- 2026-06-16T18:30:07Z: Architect handoff escrito. Fase de diseño puro. Confirmado: 0 cambios de código, 0 contratos API, 0 migraciones. Un único artefacto: 8 frames en `rideglory.pen`. Aprobación PO es el único gate de salida que desbloquea Fase 3.
