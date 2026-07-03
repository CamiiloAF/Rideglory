# UX Review — waiver-inscripcion-registro

**Fecha:** 2026-07-02T03:53:19Z (ronda 2 — re-evaluación tras fix pass de Design 2026-07-02T03:51:11Z)
**Reviewer:** ux-reviewer (nivel normal, rg-exec)
**Insumo:** `docs/exec-runs/waiver-inscripcion-registro/handoffs/design.md` (sección "Fix pass"), `docs/exec-runs/waiver-inscripcion-registro/PRD_NORMALIZED.md` (§5 AC), ronda 1 de este mismo archivo (histórico, sobrescrita)

## Verificación Pencil MCP

`get_editor_state(include_schema: true)` reintentado en esta ronda: mismo error `MCP error -32603: Failed to access file . A file needs to be open in the editor to perform this action.` Sin `.pen` abierto en este entorno headless. Consistente con la ronda 1 y con Design — no aplica porque esta fase no crea frames visuales nuevos (composición pura de widgets existentes, `needsDesign=false` verificado por Design contra el código real).

Esta ronda 2 verifica, contra el código fuente real (no solo contra la narrativa de `design.md`), que los 2 fixes que Design declara aplicados efectivamente están en el árbol de trabajo:

1. **Contraste `AppSwitchTile.subtitle`:** `lib/shared/widgets/form/app_switch_tile.dart:62` usa ahora `AppColors.textOnDarkSecondary`. Confirmado en `lib/design_system/foundation/theme/app_colors.dart:143` que `textOnDarkSecondary = #9CA3AF`. Contraste recalculado sobre `AppColors.darkBgPrimary` (`#0D0D0F`): ≈7.65:1 — cumple holgadamente el mínimo WCAG 2.1 AA de 4.5:1 para texto normal (12px). El cambio es real, de una línea, y no afecta la firma del widget ni otros usos existentes (ningún otro caller pasaba `subtitle` antes de esta fase, confirmado en ronda 1).
2. **Botón "Cancelar" del waiver:** `design.md` documenta el cambio de `AppTextButton` (variant `muted`) a `AppButton` (`style: outlined`, `shape: pill`, `isFullWidth: false`). Verificado contra `lib/features/event_registration/presentation/wizard/registration_wizard_navigation_bar.dart:51-55`, que el botón "Atrás" (`registration_previousStep`) de los otros 4 pasos usa exactamente `AppButton` con `style: AppButtonStyle.outlined` y `shape: AppButtonShape.pill`. El componente visual ahora es idéntico entre "Atrás" (pasos 2-4) y "Cancelar" (waiver) — mismo alto, forma, tratamiento de borde. Confirmado también que el fix no es un widget nuevo que crear en Frontend, solo una decisión de spec ya documentada para que Frontend la siga al implementar `RegistrationWaiverStep` (que aún no existe en el código — es NEW, no EXTEND).

## Frames revisados

| ID | Nombre | Tipo | Veredicto |
|---|---|---|---|
| N/A (sin Pencil) | `RegistrationMedicalStep` + sección Privacidad (2× `AppSwitchTile`) | EXTEND | Conforme |
| N/A (sin Pencil) | `RegistrationWaiverStep` (paso 5, nuevo) | NEW (composición) | Conforme (1 sugerencia residual) |
| N/A (sin Pencil) | `RegistrationStepIndicator` (5 puntos, sin cambios de widget) | UPDATE indirecto | Conforme |

## Hallazgos

| Frame | Heurística/Ley | Severidad | Descripción específica | Fix requerido |
|---|---|---|---|---|
| `RegistrationMedicalStep` (sección Privacidad) | WCAG 2.1 AA — contraste 1.4.3 | Conforme (resuelto) | El bloqueante de ronda 1 (~4.02:1 con `textOnDarkTertiary`) está resuelto: `app_switch_tile.dart` usa `textOnDarkSecondary` (≈7.65:1), verificado en código real (no solo en `design.md`). | — |
| `RegistrationWaiverStep` | Nielsen #4 Consistencia y estándares / Jakob's Law | Sugerencia (downgrade desde Bloqueante) | El componente del botón "Cancelar" ahora es idéntico al de "Atrás" (`AppButton` outlined pill) en los 4 pasos restantes del wizard — el riesgo de "se ve como un botón distinto" que motivó el bloqueante de ronda 1 queda resuelto. Persiste un riesgo menor y explícitamente aceptado: la **palabra** sigue siendo "Cancelar" en vez de "Atrás", pese a que la acción (`onBack` → paso anterior, nunca cierra el flujo) es la misma que "Atrás" en el resto del wizard. Design documentó la decisión explícitamente citando el AC 4/5 del PRD, que nombra "Cancelar" en el texto literal del criterio. No es una inconsistencia accidental sino una tensión declarada entre el copy del PRD y la heurística de consistencia — no bloquea porque Design ya la documentó, justificó y escaló correctamente (no hay PO disponible en este entorno automatizado para resolverla de otra forma). | No bloquea la ronda 2. Antes de que el equipo cierre esta fase con humano en el loop: confirmar con PO/QA si el AC 4/5 del PRD permite leer "Cancelar" como sinónimo aceptable de "retroceder un paso" en este contexto, o si vale la pena una excepción de copy (reusar `registration_previousStep` = "Atrás") pese a la letra literal del PRD. Si el PO confirma "Cancelar", queda cerrado definitivamente; si prefiere "Atrás", es un cambio de una clave ARB sin impacto de layout. |
| `RegistrationWaiverStep` | Nielsen #9 Ayudar a reconocer/diagnosticar/recuperarse de errores | Sugerencia (persiste de ronda 1) | El bloque de error inline no tiene componente compartido dedicado (`design.md` lo reconoce). Riesgo de inconsistencia visual entre los 3 casos de error si se implementan en momentos distintos. | No bloquea. Backlog: extraer `InlineErrorBlock` compartido la próxima vez que se repita el patrón. |
| `RegistrationWaiverStep` | Objetivo del PRD (cumplimiento legal) / Nielsen #1 | Sugerencia (persiste de ronda 1) | Sin scroll-to-accept: el CTA está habilitado sin relación con si el rider leyó el texto legal placeholder. Documentado como decisión intencional de v0. | No bloquea. Backlog: evaluar scroll-to-accept cuando el texto legal definitivo del abogado esté listo. |
| `RegistrationMedicalStep` / `RegistrationWaiverStep` | Nielsen #4 Consistencia y estándares (trazabilidad de copy) | Sugerencia (persiste de ronda 1) | Decisión abierta sobre compartir o separar las claves ARB de edad (14 vs 16). Design recomienda compartir (14, cuadra con el PRD). | No bloquea. Confirmar con QA/Build antes de cerrar el ARB. |

## Bloqueantes — deben resolverse antes de que Frontend empiece

Ninguno. Los 2 bloqueantes de ronda 1 quedaron resueltos y verificados contra el código real:
1. Contraste WCAG AA del subtítulo de `AppSwitchTile` — corregido en `lib/shared/widgets/form/app_switch_tile.dart`.
2. Inconsistencia visual del botón "Cancelar" vs "Atrás" — resuelta a nivel de componente (mismo `AppButton` outlined pill); la palabra "Cancelar" se mantiene por mandato literal del PRD (AC 4/5), decisión documentada explícitamente por Design ante ausencia de PO en este entorno.

## Sugerencias — backlog de UX (no bloquean)

1. Confirmar con PO/QA si "Cancelar" (en vez de "Atrás") es la palabra final deseada para el botón de retroceso del waiver, dado que la acción es idéntica a "Atrás" en el resto del wizard — riesgo residual bajo, ya mitigado a nivel de componente visual.
2. Extraer un widget compartido `InlineErrorBlock` para los bloques de error inline (hoy ad hoc en cada feature) — no urgente para esta fase.
3. Evaluar scroll-to-accept (o tracking de scroll) para el texto legal cuando el copy final del abogado esté listo — v0 actual es intencionalmente permisivo.
4. Confirmar con QA/Build el conteo final de claves ARB para los errores de edad (14 vs 16) antes de cerrar el ARB.

## Veredicto final

**approved_with_notes** — los 2 hallazgos Bloqueantes de la ronda 1 fueron corregidos y verificados directamente contra el código fuente (no solo contra la narrativa de `design.md`): el contraste del subtítulo de `AppSwitchTile` cumple WCAG 2.1 AA (≈7.65:1) y el botón "Cancelar" del waiver ahora usa el mismo componente visual (`AppButton` outlined pill) que "Atrás" en el resto del wizard. Queda 1 sugerencia de seguimiento no bloqueante (confirmar con PO la palabra "Cancelar" vs "Atrás") más 3 sugerencias de backlog ya identificadas en ronda 1 sin cambios. Frontend puede proceder.
