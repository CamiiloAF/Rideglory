# UX Review — remove-city-field

**Fecha:** 2026-06-11T22:12:18Z
**Veredicto:** APROBADO CON NOTAS

---

## Frames revisados

| Frame ID | Nombre | Estados revisados | Veredicto |
|----------|--------|-------------------|-----------|
| `Neipf` | Events List (EventCard × 3) | Estado normal con imagen | Aprobado con notas |
| `kAubW` | Event Detail (EventCardInfoPanel embebido) | Estado normal | Aprobado |
| `AybHb` | Crear Evento — V3 Step 1 (EventFormBasicInfoSection) | Estado idle sin campo ciudad | Aprobado |
| `FW3Hd` | Crear Evento — V3 Step 4 Revisar | Estado revisión | Aprobado |
| `f0lXw` | Mi Inscripción (contiene eventCard embebida con InscriptionCard) | Estado pendiente | Aprobado |
| N/A | EventFiltersBottomSheet | Sin frame Pencil — revisado desde código | Aprobado con notas |

> **Nota sobre frames sin representación en Pencil:** `EventFiltersBottomSheet` e `InscriptionCard` (como componente de lista) no tienen frame propio actualizado en `rideglory.pen`. La revisión de esos dos casos se hizo desde el código fuente y el handoff de diseño. Esto es aceptable dado que los cambios son solo eliminaciones sobre UI existente.

---

## Hallazgos por frame

| Frame | Heurística / Ley | Severidad | Descripción | Fix requerido |
|-------|-----------------|-----------|-------------|---------------|
| `Neipf` — `card1` (`XQyye`) | Nielsen 4 — Consistencia | Sugerencia | La fila de ubicación en `card1` muestra "Antioquia, Colombia" — texto genérico de nivel regional, no un punto de encuentro específico. En `card3` ("Autódromo de Tocancipá, Cund.") y `card2` ("Desierto de la Tatacoa, Huila") el texto ya comunica un lugar concreto. Con `meetingPoint` este patrón se vuelve consistente en datos reales, pero el dato de placeholder de `card1` sigue sonando como ciudad más que como punto de encuentro. | En los placeholders de Pencil usar textos de ejemplo más específicos y concretos (e.g. "Parque Central, Medellín") para que el diseño muestre claramente que el campo es un punto de encuentro, no una ciudad. No bloquea implementación. |
| `Neipf` — todas las cards | Ley de Postel / Legibilidad | Sugerencia | `meetingPoint` puede ser considerablemente más largo que `city` (ej. "Gasolinera Repsol Puerto de la Selva, km 12, Gerona"). El diseño usa `maxLines: 1` + ellipsis — correcto. Sin embargo, los datos de demo en Pencil no ejercen este caso con textos largos, por lo que el truncado no se validó visualmente en el frame de referencia. | Verificar en Pencil con un placeholder largo (>40 chars) para confirmar el ellipsis no rompe el layout. No bloquea implementación dado que el `maxLines: 1` ya existe en el código. |
| `kAubW` — Event Detail | Consistencia Nielsen 4 | Conforme | La sección "Punto de Encuentro" en el detail ya muestra `meetingPoint` ("Gasolinera Repsol, Portbou") con mapa embebido. La `EventCardInfoPanel` (panel de info expandible de la lista) en código actualmente usa `event.city` y en Pencil no hay un frame separado para ese componente — pero el handoff de diseño lo documenta correctamente. El Pencil del Event Detail (kAubW) confirma la jerarquía visual pretendida. | N/A |
| `AybHb` — Crear Evento Step 1 | Nielsen 8 — Minimalismo | Conforme | El formulario en Pencil no tiene campo "Ciudad". Muestra: Portada, Nombre, Fecha y Hora, Dificultad, Tipo. Correcto — la eliminación reduce carga cognitiva (paso de ~6 campos a ~5). | N/A |
| `FW3Hd` — Step 4 Revisar | Nielsen 6 — Reconocimiento | Conforme | La pantalla de revisión no tiene fila "Ciudad" en la card de "Información básica". Las filas mostradas son Nombre, Descripción, Portada. El campo nunca fue parte de la sección Configuración en este step, por lo que la eliminación es limpia. | N/A |
| `f0lXw` — Mi Inscripción | Nielsen 8 — Minimalismo | Conforme | La eventCard embebida en la pantalla muestra nombre del evento, fecha y ubicación ("Castellón, España") — esta ubicación forma parte del eventInfo del card interno de la pantalla de detalle, NO del `InscriptionCard` de lista. El `InscriptionCard` como widget de lista (que es el afectado por la eliminación del bloque `city`) no tiene frame Pencil separado. La eliminación de ese bloque deja la card de lista más compacta: nombre + badge + fecha. Sin impacto negativo de UX — la ciudad nunca fue información crítica para decidir "ver detalles" de una inscripción. | N/A |
| EventFiltersBottomSheet (código) | Nielsen 3 — Control y libertad | Sugerencia | Al eliminar la sección CIUDAD, el bottom sheet pasa de 5 a 4 secciones (TIPO · DIFICULTAD · RANGO DE FECHAS · OPCIONES). El código fuente (`_clearAll`) aún llama `form?.fields[EventFilterFormFields.city]?.didChange('')` — ese campo no existirá tras la eliminación. Aunque esto es un no-op en Dart (la referencia nula simplemente no hace nada), es ruido de código que podría confundir futuros mantenedores. | Frontend debe eliminar la línea `form?.fields[EventFilterFormFields.city]?.didChange('')` de `_clearAll()` junto con el resto del bloque CIUDAD. No afecta UX directamente pero es limpieza necesaria. |
| EventFiltersBottomSheet (código) | Consistencia — Design System | Sugerencia | El método `_activeCount` en el código suma `_selectedTypes.length + _selectedDifficulties.length` — no incluía ciudad. La eliminación de la sección CIUDAD no afecta el contador del badge (ciudad nunca sumaba). El badge naranja del botón de filtros en `Neipf` seguirá siendo preciso. Conforme. | N/A |

---

## Bloqueantes — deben resolverse antes de que Frontend empiece

Ninguno. No hay hallazgos Bloqueantes. El diseño es coherente y funcional para implementación.

---

## Sugerencias — backlog de UX (no bloquean)

1. **`Neipf` / `card1` — Placeholder de meetingPoint ambiguo:** El dato de demo "Antioquia, Colombia" sigue siendo regional y no ilustra bien el concepto de "punto de encuentro". Actualizar en Pencil el texto de `card1` a algo más específico como "Parque Principal de Barbosa, Ant." para que el diseño de referencia sea más educativo para futuros diseñadores.

2. **`Neipf` — Validar truncado con texto largo:** Añadir en Pencil un cuarto card de ejemplo con un `meetingPoint` largo (ej. "Entrada principal Autódromo de La Dorada, km 3 vía Honda") para confirmar visualmente el comportamiento del ellipsis. El código ya lo maneja, pero el diseño no lo ejercita.

3. **`EventFiltersBottomSheet` — Limpieza de `_clearAll()`:** Eliminar la línea `form?.fields[EventFilterFormFields.city]?.didChange('')` que quedará huérfana tras la eliminación de la sección CIUDAD. Es código muerto que puede crear confusión.

---

## Resumen ejecutivo

El diseño de esta tarea es un sweep de eliminación quirúrgico y bien ejecutado. Los frames de Pencil revisados (`Neipf`, `kAubW`, `AybHb`, `FW3Hd`, `f0lXw`) muestran consistencia: el campo ciudad desaparece de todos los layers sin dejar vacíos visuales ni espacios blancos. La fila de ubicación en `EventCard` ya muestra `meetingPoint` en los datos de demo de Pencil, lo que confirma la intención de diseño.

Los únicos puntos de fricción son menores: un placeholder de demo que sigue usando texto nivel-ciudad en vez de punto de encuentro concreto (no visible para usuarios reales), y una línea de código muerto en `_clearAll()` que quedará huérfana. Ninguno de estos puntos bloquea la implementación. No hay violaciones de WCAG AA, Fitts, touch targets, ni del design system Rideglory (no se añaden elementos nuevos, solo se eliminan).

La búsqueda de texto libre que pierde la capacidad de filtrar por ciudad (documentado en §Flujo 2b del handoff) es una regresión de funcionalidad aceptable dado que la app no tiene usuarios reales y está explícitamente marcada como mejora futura.

---

## Veredicto final

**APROBADO CON NOTAS** — sin bloqueantes. Frontend puede proceder con la implementación. Las 3 sugerencias van al backlog de UX y no requieren iteración de diseño antes de la implementación.
