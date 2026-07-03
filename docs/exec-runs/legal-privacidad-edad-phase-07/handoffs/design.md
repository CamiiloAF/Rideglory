# Design handoff — legal-privacidad-edad-fase7-organizador

**Date:** 2026-07-03T16:43:34Z
**Status:** done

## Resumen

Esta fase es **retroactiva**: el Architect confirmó que ~95% del alcance del PRD
(`isOrganizerView`, `RegistrationContactActions`, navegación organizador, bottom
bar) ya está implementado y ya fue diseñado en un run previo. El único gap real
(AC10 — fallback de `bloodType` nullable) es una **corrección de valor de dato**,
no un cambio visual: la fila "Tipo de sangre" ya existe en Pencil con el estilo,
posición y layout correctos; lo único que cambia es qué string se inserta en el
slot `rowValue` cuando `bloodType` es `null` (hoy siempre `"••••"` hardcodeado en
código; con el fix, muestra el string crudo del backend o `"N/A"` según el caso).

**needsDesign = false** para esta fase — confirmado contra Pencil, no solo por
lectura de código. No se crearon ni modificaron frames.

## Pantallas

| Screen name | Story | Type | Frame Pencil | Estado |
|---|---|---|---|---|
| Detalle Inscripción — Vista Owner (Fase 7) | AC1–AC12 (isOrganizerView, contacto, bloodType) | UPDATE (ya existente, sin cambios) | `dJQM1` | Verificado, sin cambios requeridos |

Export de referencia: `docs/exec-runs/legal-privacidad-edad-fase7-organizador/analysis/design/dJQM1.png`

## Flujos UX

Sin cambios de flujo. El flujo organizador (abrir detalle desde `AttendeesList`
o `EventDetailParticipantsSection` → ver datos reales/ofuscados según
`allowOrganizerContact`/reglas de privacidad → botones Llamar/WhatsApp en la
`CTA Bar` cuando aplica) ya está representado en el frame `dJQM1` tal como lo
implementó el código:

- Card "Datos Personales": filas con valores reales u ofuscados (`"••••"`) fila
  por fila (Nombre, Identificación, Fecha de nacimiento, Teléfono, Correo,
  Ciudad).
- Card "Información Médica": incluye la fila **Tipo de sangre** — objeto de
  esta fase. En el mockup actual el valor mostrado es `"••••"` (ejemplo de dato
  ofuscado por privacidad); esto sigue siendo un estado válido y no requiere
  cambio de diseño. Lo que cambia es el código detrás del fallback cuando el
  valor es `null` sin ofuscación explícita (ver "Notas para Frontend").
- CTA Bar: botones "Llamar" (relleno naranja `#F98C1F`, texto e icono oscuros
  `#0D0D0F` — cumple la regla de texto oscuro sobre acento) y "WhatsApp"
  (outline verde `#25D366`, relleno translúcido `#25D3661A`) — ya construidos
  y coinciden con `RegistrationContactActions` implementado en código.

Ningún estado nuevo de carga/error/vacío aplica: la fila de tipo de sangre es
un valor de texto simple dentro de una card ya cargada, sin estado propio de
loading/error.

## Componentes

| Screen | Componentes usados | Componentes nuevos necesarios |
|---|---|---|
| `dJQM1` (fila "Tipo de sangre") | `rowLabel` / `rowValue` (par label-valor genérico ya usado en las 4 cards de la pantalla) | Ninguno |

No se requiere ningún átomo o molécula nuevo en `lib/design_system/` ni en
`lib/shared/widgets/`. El cambio de Frontend es puramente de lógica de
fallback en un `Text` ya existente dentro de `registration_detail_page.dart`
(no cambia estructura de widget, no cambia el árbol de layout).

## Copy

| Key | Texto | Contexto |
|---|---|---|
| `notAvailable` (ya existente en `app_es.arb`) | "N/A" | Fallback cuando `bloodType` es `null` y `bloodTypeRaw` también es `null` |
| — | (string crudo del backend, p. ej. `"••••"` o `"__NOT_SHARED__"`) | Cuando `bloodTypeRaw` no es `null`; se muestra tal cual, sin traducir ni formatear (fuera de alcance de esta fase, confirmado en PRD §"No entra") |

No se agrega ninguna clave nueva al ARB. `registration_maskedValue` (`"••••"`)
queda sin call-sites tras el fix pero no se elimina en esta fase (deuda menor,
documentada por Architect en R2 — decisión de Frontend/QA, no de Design).

## Accesibilidad

- Contraste: `rowValue` en estado ofuscado usa `#6B7280` sobre `$bg-tertiary`
  (fondo oscuro) — ya validado en el mockup existente, sin cambios.
- El nuevo fallback `"N/A"` usa el mismo estilo tipográfico (`$text-primary`,
  13px/600) que cualquier valor real — no hay diferenciación visual especial
  que requiera revisión de contraste adicional.
- No hay nuevos elementos interactivos (la fila es de solo lectura); no aplica
  tamaño mínimo de touch target 44×44px a este cambio.
- Botones de contacto (`Call Button` / `WhatsApp Button`) ya cumplen 50px de
  alto (> 44px mínimo) — sin cambios en esta fase.

## Notas para Frontend

- **No tocar el árbol de widgets** de la fila "Tipo de sangre" en
  `registration_detail_page.dart` — solo el valor del fallback:
  `registration.bloodType?.label ?? registration.bloodTypeRaw ?? context.l10n.notAvailable`
  reemplaza `registration.bloodType?.label ?? context.l10n.registration_maskedValue`.
- El frame Pencil `dJQM1` sigue siendo la referencia visual vigente para toda
  la pantalla (incluye `isOrganizerView`, cards, CTA Bar) — no se requiere
  releer otro frame ni crear uno nuevo para este fix.
- Confirmar en QA que el string crudo (p. ej. `"__NOT_SHARED__"` si el backend
  lo envía sin traducir) no rompe el layout `fill_container` de `rowValue`
  (texto largo) — es un riesgo de contenido, no de diseño, pero vale la pena
  una revisión visual rápida post-implementación si el backend puede devolver
  sentinels largos.
- Sin cambios pendientes de Pencil. Si en una fase futura se decide traducir
  los sentinels (`"••••"` / `"__NOT_SHARED__"`) a texto descriptivo, eso sí
  requeriría una nueva iteración de Design (fuera de alcance aquí, ver PRD
  §"No entra").

## Change log

- 2026-07-03T16:43:34Z: Design phase — verificado contra Pencil (`get_editor_state` +
  `batch_get` sobre frame `dJQM1`, export a `analysis/design/dJQM1.png`). Confirmado
  `needsDesign = false`: la fila "Tipo de sangre" ya existe con el estilo/layout
  correcto; el fix de AC10 es puramente de lógica de fallback en código, sin
  impacto visual. Cero cambios a `rideglory.pen`.
