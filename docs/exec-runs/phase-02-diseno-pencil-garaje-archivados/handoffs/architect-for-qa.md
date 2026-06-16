> Slim handoff — lee esto antes de handoffs/architect.md

# Architect → QA — Phase 02

**Esta fase NO produce código testeable.** No hay tests unitarios, widget tests, ni integración que ejecutar.

## Verificaciones de esta fase (solo visuales)

| # | Criterio | Cómo verificar |
|---|----------|----------------|
| AC-1 | `rideglory.pen` contiene exactamente 8 frames nuevos | `batch_get` + contar frames con prefijo `[Garaje-Archivados]` |
| AC-2 | Frame 5 (menú archivado) tiene nota de decisión PO visible | Inspección visual / `get_screenshot` Frame 5 |
| AC-3 | Header "Archivados (N)" ≥ 44 px de alto | `snapshot_layout` Frame 2 |
| AC-4 | Celdas de menú en Frames 4 y 5 ≥ 48 px | `snapshot_layout` Frames 4 y 5 |
| AC-5 | CTA Frame 6 usa texto oscuro (#0D0D0F) sobre naranja — nunca blanco | Inspección visual Frame 6 |
| AC-6 | CTA Frame 7 usa `colorScheme.error` con texto claro (blanco) | Inspección visual Frame 7 |
| AC-7 | Frame 7 incluye nombre del vehículo en cuerpo + estado loading con CTA deshabilitado | Inspección visual Frame 7 |
| AC-8 | Frame 8 muestra loading inline (shimmer/overlay en card) y error como snackbar (no modal) | Inspección visual Frame 8 |
| AC-9 | Todos los frames tienen nombres descriptivos (no "Frame 1") | `get_editor_state` y listar frame names |
| AC-10 | PO ha dado aprobación explícita por escrito | Mensaje/comentario transcrito en resumen de ejecución |

## Comandos de código (no aplican en esta fase)

No hay `dart analyze`, `flutter test`, ni `dart run build_runner` que ejecutar. Esta fase es diseño puro.

## Gate de salida para Fase 3

Fase 3 (Flutter: archivar y restaurar vehículos) no puede iniciar sin:
1. Los 10 criterios de aceptación anteriores cumplidos
2. La aprobación explícita por escrito del PO

> Full detail: handoffs/architect.md
