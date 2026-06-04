# Pencil Screen Sync — Implementar el diseño real de rideglory.pen en Flutter

## El problema

En iter-1, el Design agent no pudo acceder a Pencil (la app no estaba abierta) e **inventó diseños propios** en HTML. El Frontend agent implementó esos diseños inventados. El resultado: la app no tiene ninguna relación visual con lo que está en `rideglory.pen`.

## El objetivo

**La app Flutter debe ser visualmente idéntica al proyecto de Pencil.** Cada pantalla Flutter debe implementar exactamente lo que muestra el frame correspondiente en `rideglory.pen` — mismos colores, tipografía, espaciado, componentes, iconos y estados.

## Fuente de verdad

`rideglory.pen` es la única fuente de verdad de diseño. **No inventar nada.** Si un frame en Pencil no especifica algo, usar el sistema de diseño existente (AppColors, Space Grotesk, border-radius 8px).

## Frames en rideglory.pen (40 nodos top-level)

El Design agent DEBE leer y capturar screenshot de TODOS los frames antes de documentar nada.

Frame IDs conocidos (del editor state):
- `dyWWs` — Home Dashboard
- `Neipf` — Events List (lista de eventos)
- `kAubW` — Event Detail
- `PMuA4` — Create Event form (doble ancho 860px — posiblemente 2 estados)
- `zbCa0` — Create/Edit Event form (completo)
- `KCf6W` — Garage / Vehicle List
- `P1GSzZ` — Vehicle Detail
- `EqnMm` — Add/Edit Vehicle Form
- `aGqnv` — Document Slot Pill (molécula de sistema de diseño)
- `YCuIq`, `pQCmS` — por identificar (mantenimiento u otro)
- `v6RqaX` — Maintenance Filters bottom sheet
- `J5h6P` — Maintenance Step 1
- `ELB5u` — Registration Paso 2 (Programado)
- `eK2WW` — Registration Paso 2 (Completado)
- `heldR` — Registration Paso 2 (variante)
- `nxTub` — Event Tracking SOS Alert
- `AETwc` — SOS Confirmation
- `tt64n` — End Ride Confirmation
- `o1A6t4` — Event Tracking Map
- `Gv2Rr` — Event Tracking Riders Panel
- `XJtvl` — Mis Eventos
- `UqpLS` — por identificar
- `t7MYzR` — Forgot Password
- `UYeeY`, `o7KqgL` — por identificar
- `uVOQl`, `MrYmb`, `VrqVl` — por identificar (auth?)
- `LDsMT`, `b5YFuy`, `DJOZ2` — por identificar
- `IUxas`, `f0lXw`, `qs5o1`, `Q44tYx`, `VKLP4` — por identificar
- `A7qDd` — Profile
- `VMmN0` — Component/Tab Bar (reusable)
- `zKkmE` — Component/Event Badge (reusable)

## Alcance

### IN SCOPE — pantallas que tienen frame en Pencil y existe implementación Flutter
Solo tocar pantallas donde existe frame en Pencil. El Design agent determina la lista final después de leer todos los frames.

### OUT OF SCOPE
- Pantallas sin frame en Pencil
- Cambios de lógica de negocio, cubits, use cases, APIs
- Cambios en el backend (rideglory-api)
- Nuevas rutas o features no presentes en Pencil

## Approach para el Design agent

1. Abrir `rideglory.pen` con Pencil MCP
2. Para CADA frame top-level: tomar screenshot con `mcp__pencil__get_screenshot`
3. Para frames de componentes (`VMmN0`, `zKkmE`, `aGqnv`): leer estructura con `batch_get` depth 5
4. Para cada frame de pantalla: documentar:
   - Nombre del frame y Flutter screen equivalente (ruta del archivo)
   - Colores exactos con hex
   - Tipografía: familia, tamaño, peso, color
   - Spacing: padding, gaps, margins
   - Componentes: cuáles son instancias de componentes reutilizables
   - Estados: cuáles frames representan el mismo screen en distinto estado
5. Producir `analysis/pencil-frame-map.md` — tabla frame → archivo Flutter

## Approach para el Frontend agent

1. Leer `analysis/pencil-frame-map.md` del Design agent
2. Leer cada screenshot en `analysis/screenshots/`
3. Para cada pantalla, abrir el archivo Flutter correspondiente
4. Implementar los cambios para que la UI coincida exactamente con el screenshot
5. NO tocar domain/, data/, ni DI
6. Sí tocar: widgets, pages, colores, tipografía, espaciado, componentes
7. Reemplazar cualquier widget inventado en iter-1 por la implementación real de Pencil

## Acceptance Criteria

1. Cada pantalla Flutter que tiene frame en Pencil luce idéntica al frame (mismos colores, fuentes, spacing)
2. `dart analyze` pasa con 0 errores y 0 warnings
3. `flutter test` no introduce nuevas fallas (las 4 pre-existentes de .g.dart son aceptables)
4. No se tocan archivos de dominio, datos ni DI
5. Los componentes `AppEventBadge` y `DocumentSlotPill` creados en iter-1 se mantienen si coinciden con Pencil, o se actualizan si no coinciden

## Regression guardrails

- AI cover generation (iter-4): no tocar `EventCoverService`, `AICoverWidget`
- Mapbox route preview: no tocar `route_map_preview.dart`
- ManageAttendeesPage: no tocar (deferred iter-2)
- Live tracking: no tocar `live_map_widget.dart`, `live_map_page.dart`
