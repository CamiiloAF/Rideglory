# Plan Review — archive-vehicle-soft-delete

_Generated: 2026-06-16T16:12:07Z_
_Reviewer: Plan Reviewer (UX móvil + Calidad/Clean Architecture)_

---

## Veredicto global

**ok_con_ajustes** — El plan está bien estructurado y cubre el ciclo de vida completo del archivado/eliminación. La secuencia de fases es lógica y los prerequisitos bloqueantes están correctamente identificados. Se requieren ajustes puntuales antes de ejecutar.

---

## UX por fase

### Fase 1 — Backend: soft-delete e integridad de datos

No hay UI que revisar. Sin embargo, hay implicaciones UX indirectas que el backend debe garantizar para que las fases Flutter no necesiten workarounds:

- El campo `isDeleted` debe estar correctamente excluido de `GET /api/vehicles/my` para que la UI nunca reciba vehículos eliminados. Si el filtro falla, el garaje podría mostrar fantasmas. El criterio de aceptación cubre esto.
- La promoción automática de vehículo principal al eliminar debe devolver el nuevo `mainVehicle` en el response (o el Flutter debe refrescar). El plan asume que Flutter detecta el cambio al re-fetch — confirmar que el response de `DELETE` indica si hubo promoción, o que el cubit hace re-fetch de la lista completa tras eliminar.
- **Gap:** no se especifica qué devuelve `DELETE /api/vehicles/:id` — un 204 vacío o un body con el nuevo estado. El Flutter necesita saber si hubo promoción de principal para actualizar el cubit correctamente. Agregar criterio de aceptación: "si el vehículo eliminado era principal, el response incluye el id del nuevo principal o 204 con header `X-New-Main-Vehicle-Id`". Alternativamente, el cubit hace re-fetch completo tras eliminar (más simple, recomendado).

### Fase 2 — Diseño Pencil: garaje con sección de archivados

Fase puramente de diseño. Verificaciones UX que el diseñador debe cumplir:

**Touch targets (375px, 44px mínimo):**
- La sección colapsable "Archivados (N)" necesita un header con al menos 44px de alto y área táctil completa en todo el ancho del encabezado (no solo el texto o el ícono de chevron).
- Las opciones del menú contextual (bottom sheet) — "Restaurar", "Eliminar permanentemente" — deben tener mínimo 48px de alto por celda.
- "Eliminar permanentemente" en el diálogo/bottom-sheet destructivo debe visualmente diferenciarse de acciones secundarias: color de texto en rojo semántico o con ícono de advertencia. El CTA de confirmación destructiva es el único caso donde se puede usar un color de peligro en lugar del primario naranja.

**Estados requeridos en diseño (todos deben aparecer en los frames de Pencil):**
1. Garaje sin archivados — sección "Archivados" oculta o con estado vacío.
2. Garaje con archivados, sección colapsada — solo el header visible con contador "(N)".
3. Garaje con archivados, sección expandida — lista de VehicleCards archivadas.
4. Menú contextual vehículo activo — "Establecer como principal" (condicional), "Editar", "Agregar mantenimiento", "Archivar" (sin "Eliminar").
5. Menú contextual vehículo archivado — "Restaurar", "Eliminar permanentemente" (sin "Editar", sin "Agregar mantenimiento" — los archivados no deberían editarse).
6. Diálogo confirmación archivado — tono informativo, no destructivo; resaltar conservación de historial.
7. Diálogo confirmación eliminación permanente — tono destructivo; nombrar el vehículo; CTA en color de peligro.
8. Estados loading/error para archivar y restaurar (inline en la card o como snackbar).

**Gap UX en la propuesta:** el menú de vehículo archivado no especifica si "Editar" y "Agregar mantenimiento" permanecen o desaparecen. Semánticamente, un vehículo archivado no debería recibir nuevos registros de mantenimiento. El diseñador debe decidir y documentar esto en la Fase 2.

**Color en CTA destructivo:** el botón de "Eliminar permanentemente" en el diálogo de confirmación va en rojo (`colorScheme.error`), no en el primario naranja. El texto sobre error sigue siendo claro/blanco (no oscuro), porque `colorScheme.error` no es el primario. Esto es una excepción al regla de texto oscuro sobre naranja.

### Fase 3 — Flutter: archivar y restaurar vehículos

**Estados UI que deben implementarse (todos verificables en los criterios de aceptación):**

| Estado | Widget afectado | Notas |
|--------|----------------|-------|
| Idle con 0 archivados | `GarageVehiclesContent` | Sección archivados oculta o con mensaje vacío |
| Idle con N archivados | `GarageVehiclesContent` | Header "Archivados (N)" visible, colapsado por defecto |
| Expandido / colapsado | Header colapsable | `ExpansionTile` o widget custom — 44px mínimo en header |
| Loading al archivar | `VehicleCard` o cubit | Indicador inline (no bloquear toda la pantalla) |
| Loading al restaurar | `VehicleCard` o cubit | Indicador inline |
| Error al archivar | Feedback al usuario | Snackbar o `AppDialog` de error con mensaje en ES |
| Error al restaurar | Feedback al usuario | Snackbar o `AppDialog` de error |
| Vehículo principal archivado | Nuevo principal en lista | `VehicleCubit` actualiza main correctamente |

**Flujo de navegación del diálogo de confirmación:**
- El diálogo de confirmación de archivado debe abrirse desde `GarageOptionsBottomSheet`, no desde `VehicleCard`. El bottom-sheet se cierra tras confirmar (no queda colgado abierto).
- Usar `ConfirmationDialog` (shared widget existente) para consistencia — verificar que el shared widget soporte el tono "informativo" (no solo destructivo). Si no, se puede usar `AppDialog` directamente con los campos adecuados.

**Regla crítica — un widget por archivo:**
- `GarageArchivedSection` (el colapsable) → archivo propio.
- `GarageArchivedHeader` (el header clickeable) → archivo propio si tiene lógica visual.
- `GarageOptionsBottomSheet` ya existe: se modifica, no se crea nuevo archivo, pero no puede acumular métodos privados que retornen widgets.

**Regla crítica — wiring de callbacks:**
El scan detectó que `VehicleCard.onArchive`/`onUnarchive` existen pero no están wired. El wiring correcto es:
```
GarageVehiclesContent
  → pasa onArchive/onUnarchive a VehicleCard
  → VehicleCard los invoca al tap
  → GarageVehiclesContent los delega al GarageOptionsBottomSheet o al VehicleCubit directamente
```
No agregar lógica de negocio dentro de `VehicleCard`; solo invocar el callback.

### Fase 4 — Flutter: eliminación permanente desde archivados

**Estados UI:**

| Estado | Notas |
|--------|-------|
| Loading al eliminar permanentemente | Cubit estado loading; deshabilitar botones del diálogo para evitar doble-tap |
| Error al eliminar | `AppDialog` de error o snackbar con mensaje en ES |
| Éxito | Vehículo desaparece de "Archivados" en la misma sesión |

**Gap de coordinación de despliegue (riesgo bloqueante):** La Fase 4 depende del endpoint `DELETE /api/vehicles/:id` de Fase 1. Si Fase 1 no está desplegada en el backend al correr Fase 4, el `VehicleService` de Flutter apuntará a un endpoint que no existe y el botón retornará 404. El plan menciona esto como riesgo pero no propone un mecanismo de feature flag. Ajuste requerido: el criterio de aceptación de Fase 4 debe incluir "el endpoint `DELETE /api/vehicles/:id` de Fase 1 está desplegado y respondiendo correctamente en el entorno de prueba antes de iniciar esta fase".

**Doble-tap / race condition:** El diálogo de confirmación debe deshabilitar el CTA de confirmar mientras el cubit está en estado `loading`. Agregar criterio de aceptación explícito: "el botón de confirmar queda deshabilitado durante el request de eliminación".

**Visibilidad de la opción:** criterio de aceptación dice "solo visible en vehículos archivados" — verificar que `GarageOptionsBottomSheet` bifurque por `vehicle.isArchived` para mostrar/ocultar "Eliminar permanentemente". El scan indica que la bifurcación aún no existe; la Fase 3 debe crearla y la Fase 4 la extiende.

### Fase 5 — Flutter: vehículo principal siempre coherente

Esta fase es esencialmente un refactor de estado, sin nueva UI. Verificaciones:

**No regresiones en `HomeGarageSection`:**
- Eliminar el prop `vehicle` de `HomeLoaded.mainVehicle` puede romper el contrato de `HomeScaffold → HomeGarageSection` si hay otros consumidores del prop. Verificar que el prop no se use en tests ni en otras rutas antes de eliminarlo.
- Estado `empty()` del cubit: si `VehicleCubit` está en `Initial` o `Loading` cuando se renderiza `HomeGarageSection`, debe mostrar un estado skeleton/loading, no un crash. El criterio de aceptación no cubre este edge case. Agregar: "si `VehicleCubit` está en estado `loading`, `HomeGarageSection` muestra un placeholder/skeleton".

**Sin llamadas HTTP extras:** el criterio de aceptación cubre esto correctamente. Verificar que la Fase 5 no introduzca un `fetchMyVehicles()` adicional en el `initState` de `HomeScreen` (eso violaría el criterio).

**Dimensionamiento:** Fase 5 es pequeña (1-2 archivos modificados). Bien dimensionada como fase independiente aunque podría incluirse en Fase 3 si el equipo prefiere. Mantenerla separada es defensivo y correcto.

---

## Gates de calidad

### Por fase

| Fase | Gate de entrada | Gate de salida |
|------|----------------|----------------|
| 1 | — | `prisma migrate dev` sin errores; filtros `isDeleted/isArchived` en `findVehiclesByOwnerId` verificados con prueba directa a Prisma; `DELETE /api/vehicles/:id` retorna 200/204 sin borrar fila física |
| 2 | Fase 1 no bloqueante para diseño (PATCH ya funciona) | Frames en `rideglory.pen` con todos los estados listados en esta revisión; aprobación explícita del PO por escrito |
| 3 | Diseño Pencil aprobado (Fase 2 completada) | `dart analyze` verde; sección archivados funcional; wiring de callbacks correcto; estados loading/error implementados |
| 4 | Endpoint `DELETE /api/vehicles/:id` desplegado (Fase 1) + Diseño aprobado (Fase 2) | `dart analyze` verde; doble-tap protegido; opción solo visible en archivados |
| 5 | `VehicleCubit` tiene datos cargados correctamente (Fase 3) | `dart analyze` verde; no regresiones en `HomeGarageSection`; sin HTTP extra |

### Reglas de codificación (Fases 3, 4, 5)

- Un widget por archivo — ningún widget auxiliar en el mismo archivo que otro widget.
- Ningún método privado que retorne `Widget` — extraer a clase.
- Strings de UI en `app_es.arb` con clave prefijada `vehicle_` — las claves faltantes del gap analysis deben agregarse antes de implementar.
- `AppButton`, `AppDialog`/`ConfirmationDialog`, `AppTextField` — no usar equivalentes Material directamente.
- `ResultState<T>` para estado async del archivado/eliminación — sin `bool isLoading`.
- Texto/iconos sobre naranja primario: oscuros (`darkBgPrimary`). Sobre `colorScheme.error`: claros (`onError`).
- `context.pushNamed()` para navegación de feature; no usar `goNamed()`.
- `@injectable` para cubits; acceso vía `context.read<VehicleCubit>()`, nunca `getIt<VehicleCubit>()` desde widgets.

### Pattern B — DTOs

Si Fase 4 requiere un response DTO para el soft-delete (p.ej. para obtener el nuevo vehículo principal), ese DTO debe extender el model de dominio correspondiente. No se permite `toModel()` ni construcción manual de `Map<String, dynamic>` para payloads HTTP.

---

## Riesgos de scope

| Riesgo | Impacto | Mitigación propuesta |
|--------|---------|---------------------|
| Migración `isDeleted` en base de datos con filas existentes | Alto — puede dejar el backend sin servicio | Ejecutar `prisma migrate dev` localmente, revisar SQL generado, esperar verificación humana antes de desplegar (ver regla de memoria del proyecto) |
| Coordinación de despliegue Fase 1 → Fase 4 | Alto — Fase 4 necesita el endpoint en producción/staging | Agregar criterio de aceptación explícito de dependencia de despliegue en Fase 4 |
| Estado `Initial`/`Loading` de `VehicleCubit` en HomeGarageSection | Medio — puede causar crash o layout vacío | Agregar criterio de aceptación en Fase 5 para el edge case |
| Menú contextual archivado: opciones "Editar"/"Agregar mantenimiento" no definidas | Medio — ambigüedad de implementación en Fase 3 | El diseño (Fase 2) debe especificarlo explícitamente |
| `ConfirmationDialog` no soporta tono "informativo" | Bajo — podría requerir un nuevo variant del shared widget | Verificar en Fase 3 antes de implementar; si falta, usar `AppDialog` directamente |
| MCP Pencil caído en Fase 2 | Bajo-medio — bloquea Fase 3 | Regla del proyecto ya cubre esto; no iniciar Fase 3 hasta diseño aprobado |
| `VehicleDeleteCubit` vs `VehicleArchiveCubit` — ¿ampliar o crear nuevo? | Bajo — riesgo de lógica duplicada | Decidir en Fase 3: el cubit auxiliar se amplía para "archive" o se crea `VehicleArchiveCubit` independiente. Recomendado: ampliar `VehicleDeleteCubit` renombrándolo `VehicleActionCubit` si el scope lo justifica; de lo contrario, dos cubits pequeños y focused son preferibles |

---

## Ajustes

### Obligatorios (bloqueantes)

1. **Criterio de aceptación Fase 1 — response del DELETE:** especificar qué devuelve `DELETE /api/vehicles/:id` cuando el vehículo eliminado era el principal. Opción recomendada: el cubit hace re-fetch completo de la lista tras la operación. Documentar esta decisión en el archivo de Fase 1.

2. **Criterio de aceptación Fase 4 — dependencia de despliegue:** agregar "el endpoint `DELETE /api/vehicles/:id` está disponible en el entorno de prueba" como gate de entrada explícito en la Fase 4.

3. **Criterio de aceptación Fase 4 — doble-tap:** agregar "el CTA de confirmar eliminación queda deshabilitado mientras el request está en curso (`loading`)".

4. **Criterio de aceptación Fase 5 — edge case cubit vacío:** agregar "si `VehicleCubit` está en `Initial` o `Loading`, `HomeGarageSection` muestra un placeholder sin crash".

5. **Fase 2 — estados requeridos en Pencil:** el archivo de Fase 2 debe listar explícitamente los 8 estados de pantalla que el diseñador debe cubrir (listados en la sección UX de esta revisión), incluyendo la decisión sobre "Editar"/"Agregar mantenimiento" para vehículos archivados.

### Recomendados (no bloqueantes)

6. **Claves l10n faltantes:** antes de ejecutar Fase 3, listar en el archivo de fase las claves `app_es.arb` nuevas requeridas (confirmación archivado, sección archivados header, feedback restauración, confirmación eliminación permanente). No hardcodear strings a la espera de "agregarlas luego".

7. **Decisión sobre `VehicleDeleteCubit`:** documentar en Fase 3 si se amplía el cubit existente o se crea uno nuevo, antes de implementar.

8. **Fase 5 puede fusionarse con Fase 3:** si el equipo prefiere menos fases, el fix de `HomeGarageSection` es pequeño y podría incluirse al final de Fase 3. Mantenerlo separado es correcto pero opcional.

9. **Tests de integración:** los criterios de aceptación mencionan `dart analyze` y `flutter test` pero no especifican qué tests nuevos deben escribirse. Recomendar agregar widget tests para `GarageArchivedSection` (estados vacío/con-items/colapsado/expandido) y para el diálogo de confirmación destructiva.
