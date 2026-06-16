# Frontend handoff — Phase 02: Diseño Pencil — Garaje con sección de archivados

**Date:** 2026-06-16T21:53:47Z
**Rol:** Frontend (Flutter lib/) — MODO FIX (Tech Lead)
**Veredicto:** BLOQUEADA — Esta fase es diseño puro; ningún archivo Flutter fue modificado ni debe ser modificado hasta obtener la aprobación del PO sobre los frames de Pencil.

---

## Resumen ejecutivo

La Fase 2 está bloqueada por un impedimento de proceso, no de código. El agente de Diseño no pudo crear los 8 frames en `rideglory.pen` porque Pencil MCP devolvió error `-32603: Failed to access file. A file needs to be open in the editor to perform this action.` (archivo no abierto en el editor de escritorio).

**El árbol de trabajo no contiene cambios de código Flutter.** `dart analyze` está limpio y los 951 flutter tests pasan sin cambios. No hay nada que corregir en `lib/` en esta fase.

---

## Bloqueo activo

| # | Hallazgo | Causa raíz | Acción requerida |
|---|----------|------------|-----------------|
| B-1 | Los 8 frames con prefijo `[Garaje-Archivados]` NO fueron creados en `rideglory.pen` | Pencil MCP devolvió error `-32603` — `rideglory.pen` no estaba abierto en el editor de escritorio de Pencil | Abrir `rideglory.pen` en Pencil desktop y re-ejecutar la fase de diseño |
| B-2 | Los 10 TCs de QA (TC-01 a TC-10) no pueden ejecutarse vía Pencil MCP | Dependencia directa de B-1 — sin frames, no hay ACs que verificar | Completar B-1 primero; luego QA ejecuta los 10 TCs |
| B-3 | El PO no puede dar aprobación explícita por escrito | Dependencia de B-2 — sin diseño verificado, no hay nada que aprobar | Completar B-1 y B-2 primero |

---

## Estado del código Flutter (`lib/`)

**Sin cambios.** Esta fase es diseño puro. El Frontend agent no ejecuta trabajo de código en esta fase.

Verificación:

```
dart analyze → No issues found! (0 violaciones)
flutter test → 951 pass / 0 fail (sin cambios de código)
git status   → Solo directorios untracked bajo docs/exec-runs/; cero archivos .dart/.arb/.yaml modificados
```

No hay regresiones. El árbol de trabajo queda limpio de cambios de código, conforme a las HARD RULES del modo FIX.

---

## Ruta de desbloqueo (4 pasos, en orden)

1. **Abrir `rideglory.pen` en Pencil desktop**
   Ruta: `/Users/cami/Developer/Personal/Rideglory/rideglory.pen`
   El MCP de Pencil solo funciona cuando el archivo está abierto en la aplicación de escritorio.

2. **Re-ejecutar la fase de diseño**
   El agente Design debe crear los 8 frames con nombres descriptivos y prefijo `[Garaje-Archivados]`:
   - Frame 1: `[Garaje-Archivados] Garaje — Sin Archivados` (estado base)
   - Frame 2: `[Garaje-Archivados] Garaje — Sección Colapsada`
   - Frame 3: `[Garaje-Archivados] Garaje — Sección Expandida`
   - Frame 4: `[Garaje-Archivados] Menú — Vehículo Activo`
   - Frame 5: `[Garaje-Archivados] Menú — Vehículo Archivado`
   - Frame 6: `[Garaje-Archivados] Diálogo — Confirmar Archivar`
   - Frame 7: `[Garaje-Archivados] Diálogo — Confirmar Eliminar Permanente`
   - Frame 8: `[Garaje-Archivados] Estados Loading/Error inline`

   Pre-flight obligatorio: `batch_get` para confirmar que no se solapan con frames existentes del garaje.

3. **Ejecutar los 10 TCs de QA vía Pencil MCP**
   Ver catálogo completo en `handoffs/qa.md` (TC-01 a TC-10). Puntos clave:
   - TC-05: CTA Frame 6 → texto `#0D0D0F` sobre naranja `#f98c1f`. Nunca texto blanco sobre naranja.
   - TC-06: CTA Frame 7 → fondo `colorScheme.error` (#EF4444), texto `colorScheme.onError` (blanco). Correcto porque el relleno es error, no naranja.
   - TC-07: Frame 7 contiene el nombre del vehículo; Frame 7b muestra CTA deshabilitado + spinner.
   - TC-08: Frame 8 muestra loading inline (overlay en card); Frame 8b muestra snackbar — no modal.

4. **Obtener aprobación explícita del PO por escrito**
   Sin esta aprobación, la Fase 3 (implementación Flutter) permanece bloqueada.

---

## Anticipación para Fase 3 (cuando se desbloquee)

El handoff `handoffs/architect-for-frontend.md` contiene las decisiones técnicas completas. Resumen crítico para Frontend:

### Componentes a reusar (no crear nuevos)
- `GarageOtherVehicleItem` → variante archivado: opacidad 0.6 + chip estado neutro
- `ConfirmationDialog.show()` con `DialogActionType.danger` para diálogo destructivo
- `GarageOptionsBottomSheet` → bifurcar en activo vs. archivado (mismo widget, props distintas)

### Regla de color crítica (cero tolerancia)
- Diálogo de archivar (Frame 6) → `AppModalVariant.info` → `primaryLabelColor = AppColors.darkBgPrimary` (`#0D0D0F`). Nunca texto blanco sobre naranja.
- Diálogo de eliminar permanente (Frame 7) → `AppModalVariant.destructive` → `primaryLabelColor = AppColors.textOnDarkPrimary` (blanco es correcto aquí — el relleno es `AppColors.error`, no naranja).

### L10n — keys anticipadas para Fase 3
Las siguientes keys ya existen en `app_es.arb` y pueden reutilizarse directamente:
- `vehicle_archiveVehicle`
- `vehicle_unarchiveVehicle`
- `vehicle_archivedVehicle`

Keys nuevas que deberán añadirse en Fase 3:
- `vehicle_archiveConfirmTitle`
- `vehicle_archiveConfirmMessage`
- `vehicle_deleteVehiclePermanently`
- `vehicle_deleteVehiclePermanentlyConfirmContent` (con placeholder `{vehicleName}`)
- `vehicle_restoreVehicle`
- `garage_archivedVehiclesSection`

Evaluar si `vehicle_unarchiveVehicle` se renombra a `vehicle_restoreVehicle` para consistencia con la UX aprobada, o si se crea alias. Decisión no bloqueante para esta fase.

### Modelo y estado
- `isArchived` ya existe en `VehicleModel` (campo listo)
- `GarageVehiclesContent` ya filtra `!v.isArchived` para vehículos activos
- Fase 3 añadirá lista de archivados como segundo stream del mismo `VehicleCubit`
- Estado colapsado/expandido de la sección: local a la pantalla (`StatefulWidget`), no persiste en `VehicleCubit`

---

## Tests

| Suite | Resultado | Notas |
|-------|-----------|-------|
| `dart analyze` | `No issues found!` — 0 violaciones | Verificado 2026-06-16T21:53:47Z |
| `flutter test` | 951 pass / 0 fail | Sin cambios de código en esta fase |
| Pencil TC-01 a TC-10 | BLOQUEADOS (0/10) | MCP error -32603; frames no existen |
| Integration tests | No ejecutados | Fuera de alcance — fase de diseño puro |

---

## Archivos modificados

**Ninguno.** Esta fase no produce cambios de código Flutter. El único artefacto creado en este MODO FIX es este handoff.

| Archivo | Cambio |
|---------|--------|
| `docs/exec-runs/phase-02-diseno-pencil-garaje-archivados/handoffs/frontend.md` | Creado — este archivo |

---

## Change log

- 2026-06-16T21:53:47Z: Frontend handoff creado en MODO FIX. Hallazgos: B-1/B-2/B-3 (bloqueo de proceso — Pencil MCP / `rideglory.pen` no abierto). Sin cambios de código Flutter. Tests: 951 pass / 0 fail. `dart analyze`: limpio. Ruta de desbloqueo documentada (4 pasos).
