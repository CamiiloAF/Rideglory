# REVIEW CHECKLIST — Phase 02: Diseño Pencil — Garaje con sección de archivados

_Tech Lead: 2026-06-16T21:55:33Z_

**Estado actual: BLOQUEADA** — Los 8 frames no existen en `rideglory.pen`. Los pasos siguientes son el camino de desbloqueo.

---

## Pasos obligatorios antes de commitear / desbloquear Fase 3

### 1. Desbloquear Pencil MCP

- [ ] Abrir la aplicación de escritorio de Pencil.
- [ ] Abrir el archivo `/Users/cami/Developer/Personal/Rideglory/rideglory.pen`.
- [ ] Verificar que `mcp__pencil__get_editor_state` responde sin error -32603.

### 2. Re-ejecutar la fase de diseño

- [ ] Re-ejecutar `phase-02-diseno-pencil-garaje-archivados` (agente Design) con Pencil disponible.
- [ ] Confirmar que el pre-flight `batch_get` no sobrescribe frames existentes del garaje.
- [ ] Confirmar que los 8 frames se crean con el prefijo `[Garaje-Archivados]` en `rideglory.pen` (no en un archivo `.pen` nuevo).

### 3. Verificaciones de QA via Pencil MCP

- [ ] TC-01: `batch_get` con patrón `[Garaje-Archivados]` → exactamente 8 frames con ese prefijo.
- [ ] TC-02: `get_screenshot` Frame 5 → nota PO visible: "Un vehículo archivado no debe recibir nuevos registros. Decisión PO: solo Restaurar y Eliminar permanentemente."
- [ ] TC-03: `snapshot_layout` Frame 2 → alto del header "Archivados (N)" ≥ 44 px, ancho completo.
- [ ] TC-04: `snapshot_layout` Frames 4 y 5 → alto de cada celda de menú ≥ 48 px.
- [ ] TC-05: `get_screenshot` Frame 6 → label CTA primario en `#0D0D0F` (oscuro), nunca blanco, sobre `#f98c1f`.
- [ ] TC-06: `get_screenshot` Frame 7 → CTA destructivo con fondo `#EF4444` y texto `colorScheme.onError` (blanco).
- [ ] TC-07: `get_screenshot` Frames 7 + 7b → cuerpo contiene nombre del vehículo; Frame 7b muestra CTA deshabilitado (gris) con spinner.
- [ ] TC-08: `get_screenshot` Frames 8 + 8b → Frame 8 overlay/shimmer sobre card (no modal); Frame 8b snackbar con "Reintentar" (no modal).
- [ ] TC-09: `get_editor_state` → ningún frame named "Frame 1", "Frame 2", etc.
- [ ] TC-10: Aprobación explícita por escrito del PO recibida (mensaje en conversación o comentario en PR).

### 4. Sugerencias UX Review a anotar en los frames (no bloqueantes)

- [ ] F3: Anotar en Pencil que el tap en cualquier punto de la card archivada abre `GarageArchivedOptionsBottomSheet`.
- [ ] F5: Anotar `padding-bottom = max(24px, safeAreaBottom + 8px)` para safe area iPhone.
- [ ] F6: Anotar que el orden de CTAs (acción primaria arriba) es consistente con `ConfirmationDialog` de la app — no invertir.
- [ ] F7: Evaluar/documentar si invertir orden CTAs para destructivo (Cancelar arriba, Eliminar abajo) siguiendo HIG.
- [ ] F8: Anotar: "CPI.adaptive es el patrón primario para overlay de acción; shimmer es alternativa. No mezclar ambos."
- [ ] F2/F3: Confirmar con PO el copy del label: "Archivados" (con badge separado del contador) vs. "Archivados (2)" integrado.
- [ ] F8b: Anotar que el hitbox de "Reintentar" debe ser ≥ 44 px de alto.

### 5. Commit

- [ ] Confirmar `git status` muestra solo `rideglory.pen` como modificado (o nuevo untracked).
- [ ] No hay archivos `.dart`, `.arb`, `.yaml` modificados.
- [ ] Hacer commit siguiendo el mensaje sugerido en SUMMARY.md.

---

**Gate de Fase 3:** La Fase 3 (implementación Flutter) solo puede iniciarse cuando todos los checkboxes de la sección 3 (TC-01 a TC-10) estén marcados.
