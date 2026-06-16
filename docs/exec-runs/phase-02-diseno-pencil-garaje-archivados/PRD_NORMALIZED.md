# PRD Normalizado — Fase 2: Diseño Pencil — Garaje con sección de archivados

_Normalizado: 2026-06-16T18:28:34Z_
_Fuente: docs/plans/archive-vehicle-soft-delete/phases/phase-02-diseno-pencil-garaje-con-seccion-de-archivados.md_
_Slug: phase-02-diseno-pencil-garaje-archivados_
_Nivel rg-exec: lite_

---

## 1 Objetivo

Diseñar en `rideglory.pen` la UX completa del flujo de archivado de vehículos — incluyendo la sección colapsable de archivados en el garaje, los menús contextuales bifurcados (vehículo activo vs. archivado) y los diálogos de confirmación — y obtener la aprobación explícita por escrito del PO antes de que se escriba una sola línea de código Flutter.

---

## 2 Por qué

Las reglas del proyecto exigen que toda UI nueva esté aprobada en Pencil antes de implementar. La sección colapsable de archivados y los menús contextuales bifurcados son UI nueva que desbloqueará la Fase 3 (implementación Flutter). Sin este gate de diseño aprobado, ningún widget puede escribirse.

---

## 3 Alcance

### Entra
- 8 frames nuevos en `rideglory.pen` que cubren todos los estados de la pantalla de garaje y sus flujos modales relacionados con el archivado:
  1. Garaje sin archivados (línea base)
  2. Garaje — sección "Archivados (N)" colapsada
  3. Garaje — sección "Archivados (N)" expandida con cards diferenciadas
  4. Menú contextual — vehículo activo (sin opción Eliminar)
  5. Menú contextual — vehículo archivado (sin Editar ni Agregar mantenimiento)
  6. Diálogo de confirmación de archivado (informativo, CTA naranja)
  7. Diálogo de confirmación de eliminación permanente (destructivo, CTA error)
  8. Estado loading/error inline (shimmer/overlay + snackbar)
- Decisión PO documentada en Frame 5: "Editar" y "Agregar mantenimiento" no aparecen en menús de vehículos archivados.
- Touch targets verificados: mínimo 44 px header "Archivados (N)", mínimo 48 px por celda de menú.
- Anotaciones de tokens de color correctos en los frames.
- Aprobación explícita por escrito del PO antes de cerrar la fase.

### No entra
- Código Flutter (widgets, cubits, use cases, DTOs, l10n).
- Cambios en `rideglory-api` o contratos backend.
- Migraciones de base de datos o Firebase.
- Diseño de pantallas fuera del flujo garaje → archivado → restaurar/eliminar.
- Creación de un archivo `.pen` nuevo (todos los frames van en `rideglory.pen`).

---

## 4 Áreas afectadas

| Área | Detalle |
|------|---------|
| `rideglory.pen` | Se añaden 8 frames nuevos con nombres descriptivos |
| Proceso | Aprobación PO necesaria como prerequisito para Fase 3 |
| Flutter (indirecto) | Fase 3 queda bloqueada hasta aprobación de esta fase |
| Backend (indirecto) | Ningún cambio; la Fase 1 de backend puede avanzar en paralelo |

---

## 5 Criterios de aceptación

1. El archivo `rideglory.pen` contiene exactamente 8 frames nuevos correspondientes a los estados definidos en el alcance: (1) garaje sin archivados, (2) sección colapsada con contador, (3) sección expandida con cards diferenciadas, (4) menú activo sin "Eliminar", (5) menú archivado sin "Editar"/"Agregar mantenimiento", (6) diálogo de archivado informativo, (7) diálogo de eliminación permanente destructivo, (8) loading/error inline.
2. El Frame 5 (menú archivado) contiene una nota de diseño visible que documenta la decisión del PO: "Editar" y "Agregar mantenimiento" no aparecen en vehículos archivados.
3. El header "Archivados (N)" en Frame 2 tiene un alto verificable de mínimo 44 px y el área táctil ocupa el ancho completo.
4. Cada celda de menú en Frames 4 y 5 tiene un alto verificable de mínimo 48 px.
5. El CTA del Frame 6 (archivar) usa el color naranja de acento (`AppColors.primary`) con texto oscuro (`darkBgPrimary`) — nunca blanco sobre naranja.
6. El CTA del Frame 7 (eliminar permanentemente) usa `colorScheme.error` con texto `colorScheme.onError` (claro).
7. El Frame 7 incluye el nombre del vehículo en el cuerpo del diálogo y el estado secundario con el CTA deshabilitado durante loading.
8. El Frame 8 muestra estado de loading inline (shimmer o overlay en card) y estado de error como snackbar (no modal).
9. Todos los frames tienen nombres descriptivos en Pencil (no "Frame 1", "Frame 2").
10. El PO ha dado aprobación explícita por escrito antes de que la Fase 3 se inicie.

---

## 6 Guardrails de regresión

- No sobrescribir ni renombrar frames existentes del garaje activo — verificar con `batch_get` antes de crear nuevos frames.
- No crear un archivo `.pen` alternativo; el único diseño fuente es `rideglory.pen`.
- Si el MCP de Pencil está caído, detener la fase — no diseñar en herramientas alternativas (Figma, mockup HTML, etc.).
- No tocar ningún archivo `.dart`, `.arb`, `.yaml`, de backend ni de migraciones en esta fase.
- El CTA naranja (Frame 6) debe usar texto oscuro (`darkBgPrimary`), nunca blanco — violación cero tolerancia de la regla de texto sobre el acento.
- El CTA de error (Frame 7) usa `colorScheme.error` / `colorScheme.onError`; no usar color naranja ni hardcodear rojo.

---

## 7 Constraints heredados

- **Design-first obligatorio:** toda UI nueva requiere aprobación en Pencil antes de implementar (regla del proyecto, `feedback_ui_design_first.md`).
- **Único archivo de diseño:** `rideglory.pen` es la única fuente de verdad; nunca crear un `.pen` nuevo (`feedback_design_pencil.md`).
- **MCP bloqueante:** si el MCP de Pencil está caído, no continuar; registrar y reprogramar (`feedback_redesign_workflow.md`).
- **Texto oscuro sobre naranja:** texto/iconos sobre `AppColors.primary` siempre `darkBgPrimary`; nunca blanco (`feedback_dark_text_on_primary.md`).
- **Export límites Pencil:** `export_nodes` acepta un nodo por llamada; frames altos (≥ 1445 px) no exportan bien a 1x — usar secciones o `get_screenshot` (`reference_pencil_export_limits.md`).
- **Sin commits en rg-exec:** el árbol de trabajo queda sucio; el humano commitea tras revisar.
- **Strings en l10n:** aunque esta fase no produce código, los textos de diálogos definidos aquí (`vehicle_archiveConfirmMessage`, etc.) deberán entrar en `app_es.arb` en la Fase 3.
