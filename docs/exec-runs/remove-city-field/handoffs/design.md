# Design handoff — remove-city-field

**Date:** 2026-06-11T22:02:12Z
**Status:** done

---

## Contexto

Esta tarea es un **sweep de eliminación**: el campo `city` desaparece de todos los layers. No se añaden pantallas nuevas ni flujos. El impacto de diseño se limita a:

1. **EventCard / EventCardInfoPanel** — la fila de ubicación pasa de mostrar `event.city` a `event.meetingPoint`.
2. **EventFiltersBottomSheet** — se elimina la sección entera de "CIUDAD".
3. **EventFormBasicInfoSection** — se elimina el campo `AppCityAutocomplete` del formulario de creación/edición.
4. **InscriptionCard** — se elimina el bloque condicional `if (event?.city != null)` con su fila de ubicación (sin reemplazo).

Ninguna pantalla es nueva (`NEW`). Todas son `UPDATE`.

---

## Pantallas

| Pantalla | Tipo | Cambio de diseño |
|----------|------|-----------------|
| `EventCard` (lista de eventos) | UPDATE | Fila de ubicación: `event.city` → `event.meetingPoint` |
| `EventCardInfoPanel` (panel info de evento) | UPDATE | Fila de ubicación: `event.city` → `event.meetingPoint` |
| `EventFiltersBottomSheet` | UPDATE | Eliminar sección "CIUDAD" (FilterSectionLabel + AppCityAutocomplete) |
| `EventFormBasicInfoSection` (form creación/edición) | UPDATE | Eliminar campo `AppCityAutocomplete` para ciudad |
| `InscriptionCard` (event_registration) | UPDATE | Eliminar fila de ubicación con city (sin reemplazo) |

---

## Flujos UX

### Flujo 1 — Lista de eventos (EventCard) e InscriptionCard

**Antes:** Fila de ubicación muestra el nombre de la ciudad (`event.city`), e.g. "Medellín".
**Después:** Fila de ubicación muestra el punto de encuentro (`event.meetingPoint`), e.g. "Parque Lleras, El Poblado". El punto de encuentro puede ser más largo que una ciudad; el texto ya tiene `maxLines: 1` + `overflow: TextOverflow.ellipsis`, por lo que no hay riesgo de overflow visual.

No hay estados intermedios ni empty states nuevos. La fila sigue siendo siempre visible porque `meetingPoint` es campo obligatorio del evento.

**Diferencia de nullabilidad — importante para Frontend:** Hay dos contextos distintos donde se elimina `city` y el patrón de acceso es diferente:

- **`EventCard` / `EventCardInfoPanel`:** aquí `event` es una instancia directa de `EventModel`. En `event_model.dart` (línea 54) `city` es declarada como `final String city` — no-nullable. El acceso es siempre `event.city` (sin `?`). El reemplazo por `event.meetingPoint` sigue el mismo patrón no-nullable: acceso directo sin guard de nulidad.

- **`InscriptionCard` (`event_registration`):** aquí el parámetro es `event` con tipo nullable (`EventModel?`). El bloque a eliminar usa el patrón `if (event?.city != null)` / `event!.city` porque la card puede recibir un evento nulo. La eliminación es del bloque condicional completo — no es un swap; `meetingPoint` no reemplaza a `city` en este widget (decisión D12 del architect). Frontend no debe asumir que el patrón de `InscriptionCard` es equivalente al patrón de `EventCard`.

### Flujo 2 — Filtros de eventos (EventFiltersBottomSheet)

**Antes:** El bottom sheet tiene 5 secciones: TIPO · DIFICULTAD · CIUDAD · RANGO DE FECHAS · OPCIONES.
**Después:** 4 secciones: TIPO · DIFICULTAD · RANGO DE FECHAS · OPCIONES.

La sección CIUDAD desaparece por completo (label + AppCityAutocomplete + FilterDivider previo). El contador `_activeCount` ya no incluye city (la ciudad nunca sumaba al contador visible). No hay impacto en el badge de filtros activos.

### Flujo 2b — Búsqueda de texto libre (EventsCubit)

**Cambio de comportamiento en búsqueda:** Este flujo documenta una consecuencia directa de eliminar `city`, que no es visible como UI independiente pero impacta la experiencia del usuario.

**Antes:** `EventsCubit._applyFiltersAndEmit()` (líneas 197-198) filtraba la lista local contra texto libre comparando tanto `e.name` como `e.city`:
```dart
e.name.toLowerCase().contains(_searchQuery) ||
e.city.toLowerCase().contains(_searchQuery),
```
Un usuario podía escribir "Medellín" en el buscador y obtener todos los eventos de esa ciudad.

**Después:** La búsqueda solo matchea contra `e.name`. El campo `meetingPoint` **no se añade como criterio de búsqueda** (decisión explícita del architect handoff — D5: "meetingPoint no necesita búsqueda por city; la búsqueda local puede hacerse por name + meetingPoint si se requiere en el futuro").

**Impacto UX:** El usuario ya no puede encontrar eventos escribiendo el nombre de una ciudad. Si el punto de encuentro está incluido en el nombre del evento (e.g. "Ruta Medellín - Santa Fe de Antioquia"), la búsqueda sigue funcionando indirectamente. Si no, el evento solo aparece al buscar por su nombre exacto.

Este comportamiento es intencional y aceptable dado que la app aún no tiene usuarios reales. La búsqueda por `meetingPoint` queda fuera del alcance de esta tarea como mejora futura.

### Flujo 3 — Formulario de creación/edición de evento

**Antes:** La sección de info básica incluye el campo "Ciudad" debajo de otros campos básicos.
**Después:** El campo "Ciudad" desaparece. El formulario es más corto por un campo. No se reordena ningún campo existente.

El punto de encuentro (`meetingPointName`) ya existe como campo independiente en otra sección del formulario — no es necesario añadirlo aquí.

### Flujo 4 — Card de inscripción (InscriptionCard)

**Antes:** La card muestra condicionalmente una fila con icono de ubicación + nombre de ciudad si `event.city != null`.
**Después:** Esa fila no existe. La card se ve ligeramente más corta cuando el campo era visible. Sin reemplazo.

---

## Componentes

| Pantalla | Componente eliminado | Componente retenido / nuevo |
|----------|---------------------|----------------------------|
| `EventCard` | `event.city` (campo) | `event.meetingPoint` (mismo diseño de fila: `Icons.location_on_outlined` + texto 13px secundario) |
| `EventCardInfoPanel` | `event.city` (campo) | `event.meetingPoint` (misma estructura de fila) |
| `EventFiltersBottomSheet` | `FilterSectionLabel(event_filterByCity)` + `AppCityAutocomplete(name: city)` + `FilterDivider` | Sin reemplazo. Las otras secciones permanecen inalteradas. |
| `EventFormBasicInfoSection` | `AppCityAutocomplete(name: EventFormFields.city)` + variable local `city` | Sin reemplazo. |
| `InscriptionCard` | Bloque `if (event?.city != null)` con `Icons.location_on_outlined` + `event!.city` | Sin reemplazo. |
| `EventCardDateAndCity` (`event_card_date_and_city.dart`) | Widget completo — **eliminado** (código muerto) | N/A — ver nota abajo |

**Nota sobre AppCityAutocomplete:** El widget compartido en `lib/shared/widgets/form/app_city_autocomplete.dart` NO se elimina — sigue siendo usado en el flujo de registro de eventos (feature `event_registration`). Solo se elimina su uso en los dos puntos indicados arriba.

**Nota sobre `EventCardDateAndCity`:** El widget `lib/features/events/presentation/list/widgets/event_card_date_and_city.dart` tiene un parámetro `city` en su constructor. Sin embargo, el archivo no tiene call-sites en ningún punto de `lib/` (confirmado con grep — solo aparece en su propia definición). Por ello la decisión de diseño (D3/D11 del architect handoff) es **eliminar el archivo completo** en lugar de renombrar el parámetro a `meetingPoint`. El cambio de fila de ubicación en `EventCard` y `EventCardInfoPanel` se aplica directamente en esos widgets — no a través de `EventCardDateAndCity`, que nunca fue instanciado.

---

## Copy

Los cambios de copy son eliminaciones. No se añaden claves nuevas.

| Clave l10n eliminada | Texto actual | Ubicación de uso |
|---------------------|-------------|-----------------|
| `event_eventCity` | "Ciudad" | Label del campo en form de evento |
| `event_eventCityHint` | Placeholder del campo ciudad | `AppCityAutocomplete` en form |
| `event_cityRequired` | Mensaje de validación de ciudad requerida | Validador del campo en form |
| `event_filterByCity` | "CIUDAD" | `FilterSectionLabel` en bottom sheet |

---

## Accesibilidad

- La fila de ubicación en `EventCard` / `EventCardInfoPanel` mantiene su estructura y semántica (icono + texto). Cambiar `city` por `meetingPoint` no afecta el contraste ni el tamaño de fuente (13px, color secundario `#8E8E93`-equivalente). Sin cambios de accesibilidad.
- La eliminación del campo "Ciudad" del formulario reduce la carga cognitiva — impacto positivo.
- El bottom sheet de filtros con 4 secciones en lugar de 5 es más corto y requiere menos scroll — impacto positivo.
- Sin cambios en touch targets (44px mínimo) ni en contraste de colores.

---

## Notas para Frontend

1. **`EventCard` y `EventCardInfoPanel`:** reemplazar `event.city` por `event.meetingPoint` en el `Text(...)` de la fila de ubicación. El label de la fila (icono + estilo) permanece idéntico — solo cambia la fuente de datos. `maxLines: 1` + `overflow: TextOverflow.ellipsis` ya están presentes; no modificar. Notar que el archivo `event_card_date_and_city.dart` (`EventCardDateAndCity`) que tiene un parámetro `city` en su constructor **se elimina por completo** — es código muerto sin call-sites; el swap `city → meetingPoint` en `EventCard` y `EventCardInfoPanel` se hace directamente en esos widgets, no a través de `EventCardDateAndCity`.

2. **`EventFiltersBottomSheet`:** eliminar el bloque entero:
   ```dart
   const FilterDivider(),
   Padding(
     padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
     child: Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         FilterSectionLabel(context.l10n.event_filterByCity),
         const SizedBox(height: 12),
         const AppCityAutocomplete(
           name: EventFilterFormFields.city,
           labelText: '',
           isRequired: false,
         ),
       ],
     ),
   ),
   ```
   El `FilterDivider` que precede a la sección de fechas debe permanecer.

3. **`EventFormBasicInfoSection`:** eliminar el `AppCityAutocomplete` widget, la variable local `city` extraída de `formValues`, y el argumento `city: city` en `_buildEventContext()`. Sin reordenar los campos restantes.

4. **`InscriptionCard`:** eliminar el bloque `if (event?.city != null) ...` completo (líneas ~190-212). Sin agregar `meetingPoint` en su lugar — la card no es el lugar para ese dato.

5. **Sin maquetas HTML necesarias:** los cambios son eliminaciones sobre UI existente que ya tiene su diseño aprobado en Pencil. No hay pantallas nuevas ni layouts alterados que requieran maqueta de referencia. Frontend puede trabajar directo sobre el código existente siguiendo las instrucciones de cada punto.
