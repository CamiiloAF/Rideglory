# Design handoff — flutter-permanent-delete-vehicle

**Date:** 2026-06-17T17:12:05Z
**Status:** done

---

## Resumen de alcance de diseño

Esta fase es principalmente una limpieza de código (eliminar `VehicleDeleteCubit` obsoleto, variante `VehicleActionState.success` huérfana, método `deleteVehicleLocally`). No requiere pantallas nuevas. El diseño de todas las pantallas involucradas ya existía en `rideglory.pen` desde Fase 2 (archive-vehicle-soft-delete).

**Una corrección aplicada:** El frame `EM0D6` (Menú — Vehículo Archivado) solo mostraba la opción "Restaurar", sin la fila "Eliminar permanentemente". Se añadió la fila destructiva al panel para que el diseño refleje la implementación real.

---

## Pantallas

| Frame ID | Nombre en Pencil | Tipo | Estado |
|----------|-----------------|------|--------|
| `EM0D6` | `[Garaje-Archivados] Menú — Vehículo Archivado` | UPDATE | Actualizado — se añadió fila "Eliminar permanentemente" |
| `SqWs1` | `[Garaje-Archivados] Diálogo — Eliminar Permanente` | existente | Sin cambios — ya correcto |
| `x7j5iJ` | `[Garaje-Archivados] Diálogo — Eliminar (cargando)` | existente | Sin cambios — ya correcto |
| `fOIJD` | `[Garaje-Archivados] Snackbar — Error de operación` | existente | Sin cambios |
| `HpUYE` | `[Garaje-Archivados] F3 — Garaje archivados expandidos` | existente | Sin cambios |

---

## Flujos UX

### Flujo principal: eliminación permanente desde garaje (vehículo archivado)

```
GarageOptionsBottomSheet (EM0D6)
  └─ Vehículo archivado visible
     ├─ Tap "Restaurar" → unarchiveVehicle (flujo Fase 3)
     └─ Tap "Eliminar permanentemente" →
           ConfirmationDialog (SqWs1) — confirmType: danger
           ├─ Cancelar → cierra diálogo, sin llamada al cubit
           └─ Confirmar →
                 Diálogo (x7j5iJ) — estado cargando (botones deshabilitados, opacidad 0.5)
                 ├─ Éxito → cierra bottom sheet → Snackbar verde "Vehículo eliminado"
                 │          → VehicleCubit.fetchMyVehicles() (re-fetch completo)
                 └─ Error  → Snackbar rojo con mensaje de error (fOIJD / gnCZx)
```

### Estado del menú según tipo de vehículo

| Estado vehículo | Opciones visibles |
|-----------------|------------------|
| Activo | Establecer como principal · Editar · Agregar mantenimiento · Archivar |
| Archivado | Restaurar · Eliminar permanentemente |

Los dos conjuntos de opciones son mutuamente excluyentes (`vehicle.isArchived`). Un vehículo archivado nunca muestra las opciones de activo y viceversa.

---

## Componentes

| Componente | Archivo Flutter | Uso en esta fase |
|-----------|-----------------|------------------|
| `GarageOptionsBottomSheet` | `garage_options_bottom_sheet.dart` | Ruta de entrada al flujo; ya implementado — solo limpieza de listener `success:` |
| `GarageOptionRow` | `garage_option_row.dart` | Cada fila del menú; el row de eliminar usa `iconColor: AppColors.error` |
| `ConfirmationDialog` | `lib/shared/widgets/modals/` | Modal destructivo; ya soporta `confirmType: DialogActionType.danger` |
| `VehicleActionCubit` | `vehicle_action_cubit.dart` | Cubit que orquesta la acción; ya implementado |

**Ningún componente nuevo es necesario.** Todo usa shared widgets existentes.

---

## Copy (español)

Todas las strings ya existen en `lib/l10n/app_es.arb` y en los archivos generados.

| Clave l10n | Texto | Contexto |
|-----------|-------|---------|
| `vehicle_unarchiveVehicle` | `"Restaurar"` | Label de la fila de restaurar en el menú archivado |
| `vehicle_permanentDeleteAction` | `"Eliminar permanentemente"` | Label de la fila destructiva y CTA del diálogo |
| `vehicle_permanentDeleteTitle` | `"Eliminar permanentemente"` | Título del `ConfirmationDialog` |
| `vehicle_permanentDeleteMessage(name)` | `"Esta acción es irreversible. El vehículo {name} y todo su historial de mantenimientos serán eliminados definitivamente."` | Cuerpo del diálogo — incluye nombre del vehículo |
| `vehicle_permanentDeleteCancel` | `"Cancelar"` | CTA secundario del diálogo |
| `vehicle_permanentDeleteSuccess` | `"Vehículo eliminado permanentemente"` | Snackbar de éxito (`backgroundColor: AppColors.success`) |

### Claves l10n huérfanas (no eliminar en esta fase)

Las siguientes claves existen en `app_es.arb` pero no tienen consumidores UI tras la migración. Se documentan aquí per PRD §3 (no entra). El equipo puede limpiarlas en una fase posterior.

- `vehicle_vehicleDeleted`
- `vehicle_deleteVehicle`
- `vehicle_deleteVehicleConfirmContent`
- `vehicle_form_delete_vehicle`

---

## Especificaciones visuales del diálogo destructivo

Basado en los frames `SqWs1` y `x7j5iJ` en `rideglory.pen`:

| Elemento | Especificación |
|---------|---------------|
| Icono | `LucideIcons.triangleAlert`, tamaño 28, color `$error` (`#EF4444`) |
| Fondo icono | Círculo 60×60, fill `#EF44441A`, sombra `#EF444430` blur 24 spread 4 |
| Título | "Eliminar permanentemente", Space Grotesk 18 700, `$text-primary`, centrado |
| Descripción | texto con nombre del vehículo interpolado, Space Grotesk 14, `$text-secondary`, centrado, lineHeight 1.5 |
| CTA destructivo | cornerRadius 24, height 50, fill `#ef4444`, texto "Eliminar permanentemente" blanco 15 600 |
| CTA cancelar | cornerRadius 24, height 50, fill `$bg-tertiary`, stroke `$border`, texto "Cancelar" `$text-primary` 15 500 |
| Estado cargando | CTA destructivo con `opacity: 0.5`, CTA cancelar con `opacity: 0.4` — ambos no interactivos |
| Gap entre botones | 8px |
| Overlay | `#0D0D0FD0` (oscuro semi-transparente) |

**Nota:** Blanco sobre rojo (`#ef4444`) es correcto y no viola la regla "texto oscuro sobre acento naranja" — esa regla aplica exclusivamente al acento primario `#f98c1f`.

---

## Especificaciones del menú archivado (EM0D6)

| Fila | Icono | Color icono | Color label | Divisor |
|------|-------|------------|-------------|---------|
| Restaurar | `rotate-ccw` | `$text-secondary` | `$text-primary` | bottom 1px `$border` |
| Eliminar permanentemente | `trash-2` | `$error` | `$error` | bottom 1px `$border` |

El header muestra el nombre del vehículo con sufijo "· Archivado" en color `$text-secondary` (distinto al menú activo que usa `$text-primary`).

---

## Accesibilidad

- Touch targets: ambas filas del menú tienen `height: 56` (> mínimo 44px). Ambos botones del diálogo tienen `height: 50` (> 44px). Correcto.
- Contraste: texto blanco sobre `#ef4444` — ratio 4.5:1 (cumple WCAG AA). Texto `$error` sobre `$bg-card` — ratio suficiente en dark theme.
- El estado "cargando" desactiva los botones visualmente con opacidad; el guard anti-doble-tap en el cubit previene invocaciones duplicadas sin necesidad de `IgnorePointer` explícito (el cubit retorna inmediatamente si ya está en `loading`).
- El diálogo es `isDismissible: true`, permitiendo descartar con tap fuera o botón back.
- Ningún elemento nuevo requiere `Semantics` adicionales — `ConfirmationDialog` y `GarageOptionRow` ya gestionan semántica correctamente.

---

## Notas para Frontend

1. **No hay trabajo de UI nuevo.** El código ya implementa el flujo completo (confirmado por Architect). El trabajo es limpieza: eliminar cubit obsoleto, variante huérfana y método sin callers.

2. **El branch `success:` en el listener de `GarageOptionsBottomSheet`** (líneas 56-65 del archivo actual) es código muerto — `VehicleActionCubit` nunca emite `.success()`. Eliminarlo no cambia el comportamiento visible.

3. **Snackbar de éxito para eliminación permanente** ya está implementado en el branch `permanentDeleteSuccess:` (línea 90-100 del archivo). Usa `vehicle_permanentDeleteSuccess` y `AppColors.success`. No tocar.

4. **Screenshots de referencia** disponibles en `docs/exec-runs/flutter-permanent-delete-vehicle/analysis/design/`:
   - `EM0D6.png` — Menú vehículo archivado (actualizado con fila de eliminar)
   - `SqWs1.png` — Diálogo de confirmación destructivo
   - `x7j5iJ.png` — Diálogo en estado cargando
   - `HpUYE.png` — Garaje con sección de archivados expandida
   - `fOIJD.png` / `gnCZx.png` — Snackbar de error

5. **Orden de implementación recomendado** (del handoff del Architect):
   1. Eliminar `vehicle_delete_cubit.dart`, `vehicle_delete_state.dart`, `vehicle_delete_cubit.freezed.dart`
   2. Eliminar variante `success` de `vehicle_action_state.dart`
   3. Eliminar branch `success:` del listener en `garage_options_bottom_sheet.dart`
   4. Eliminar método `deleteVehicleLocally` de `vehicle_cubit.dart`
   5. Eliminar grupo `deleteVehicleLocally` de `vehicle_cubit_test.dart`
   6. Correr `build_runner` (regenera DI y freezed)
   7. `dart analyze` — cero errores
   8. `flutter test` — verde
