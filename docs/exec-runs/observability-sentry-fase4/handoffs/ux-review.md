# UX Review — observability-sentry-fase4

**Fecha:** 2026-06-12T16:09:44Z
**Veredicto:** APROBADO

---

## Frames revisados

| Frame ID | Nombre | Estados revisados | Veredicto |
|----------|--------|-------------------|-----------|
| — | *(sin frames)* | Esta fase no produce cambios visuales; no se generaron mockups en Pencil. | N/A |

**Justificación de ausencia de frames:** El design.md confirma explícitamente: *"Esta fase es de instrumentación pura: no hay pantallas nuevas, no hay cambios de layout, ni alteraciones de copy visible al usuario. Todo el trabajo ocurre en capas invisibles."* `rideglory.pen` no fue modificado. No hay superficie visual que auditar.

---

## Hallazgos por frame

| Frame | Heurística / Ley | Severidad | Descripción | Fix requerido |
|-------|-----------------|-----------|-------------|---------------|
| `AppButton` (design system) | Nielsen #4 — Consistencia | Conforme | Los params `analyticsTapEvent` y `analyticsTapParams` son null por defecto. Comportamiento sin cambios cuando no se proveen. Sin breaking change en todos los call sites existentes. | Ninguno |
| `AppButton` / `AppTextButton` | Nielsen #1 — Visibilidad del estado | Conforme | El analytics call va en el `onTap` handler (fire-and-forget), nunca en `build()`. No introduce latencia perceptible ni bloquea el hilo de UI. | Ninguno |
| `AppButton` (touch target) | Ley de Fitts + WCAG 2.1 AA | Conforme | `height: 48` ya implementado en el componente existente (≥ 44px WCAG, ≥ 48px para acciones críticas). La adición de params no altera dimensiones. | Ninguno |
| `AppButton` / Semantics | WCAG 2.1 AA — Accesibilidad | Conforme | Los params de analytics son transparentes para VoiceOver/TalkBack. No producen texto adicional ni interacciones semánticas. Labels existentes sin cambios. | Ninguno |
| `EventFormCubit` — flag idempotente | Nielsen #5 — Prevención de errores | Conforme | `_terminalEventEmitted` previene doble emisión de `events_create_abandoned` en hot-reload o re-creación del cubit. La lógica es single-threaded por diseño de BLoC; sin race conditions. | Ninguno |
| `RegistrationFormCubit` — flag idempotente | Nielsen #5 — Prevención de errores | Conforme | Misma garantía idempotente que `EventFormCubit`. `registration_abandoned` no se emite si ya hubo envío exitoso. | Ninguno |
| `SentryNavigatorObserver` | Nielsen #8 — Estética minimalista | Conforme | Observer silencioso, sin UI, sin overlay, sin impacto perceptible en transiciones. Gating idéntico al de Fase 3 (`kReleaseMode || kSentryDevVerify`). | Ninguno |
| Catálogo de eventos | Regla Rideglory — Copy en español / sin PII | Conforme | Todos los event names son snake_case en inglés (convención de analytics, no UI). Ningún param contiene id de usuario, email, placa, VIN ni coordenadas. Longitud ≤ 40 chars verificada en design.md. | Ninguno |
| `HomeEmptyEventsCard` | Nielsen #7 — Flexibilidad y eficiencia | Conforme | Un solo param adicional al `AppButton` existente. Sin cambio de layout, sin nuevo widget, sin GestureDetector adicional. La regla anti-doble-conteo se respeta: el CTA de navegación pura usa el fallback del design system; no hay Cubit en ese call site. | Ninguno |

---

## Bloqueantes — deben resolverse antes de que Frontend empiece

*Ninguno.*

---

## Sugerencias — backlog de UX (no bloquean)

- **`AppButton` — orden de operaciones en handler:** El design.md especifica que el analytics call va *antes* de `onPressed?.call()`. Esta secuencia es correcta para capturar intención (incluso si el callback posterior falla). Asegurarse de que el test de `AppButton` valide este orden para evitar regresiones futuras (p.ej. si alguien invierte el orden creyendo que "el log va al final").

- **Documentar la convención del fallback en design system:** El comentario en `AppButton` debería aclarar que `analyticsTapEvent` se usa *solo* para CTAs de navegación pura sin Cubit. Los CTAs con Cubit emiten el evento directamente en el método del Cubit. Esto previene doble-conteo por parte de futuros desarrolladores que usen ambos mecanismos simultáneamente.

---

## Resumen ejecutivo

La Fase 4 de observabilidad es de instrumentación pura: cero cambios en la superficie visual, cero impacto en la experiencia perceptible del rider. El design agent tomó decisiones técnicas sólidas desde el punto de vista UX: params opcionales con null default que garantizan backward-compatibility total, analytics calls en handlers (no en `build`) que no introducen latencia de render, flags idempotentes que previenen eventos espurios en escenarios de hot-reload, y reutilización de componentes existentes sin wrappers adicionales.

No hay frames Pencil que auditar porque el diseño no produce artefactos visuales. La revisión se limitó a validar las decisiones de diseño técnico contra los criterios del playbook: ninguna heurística Nielsen resulta violada, las leyes de UX relevantes (Fitts en touch targets, Hick en carga cognitiva) se respetan por herencia de los componentes existentes, y las reglas Rideglory-específicas (texto oscuro sobre primario, switch unificado, no GestureDetector extra) están intactas. El riesgo UX de esta fase es mínimo.

---

## Veredicto final

**APROBADO** — Fase de instrumentación sin cambios visuales. Ninguna heurística violada, ningún touch target nuevo, sin impacto perceptible para el rider. Frontend puede iniciar implementación.
