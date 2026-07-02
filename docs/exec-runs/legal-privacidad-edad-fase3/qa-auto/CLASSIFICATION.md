# Clasificación QA-auto — legal-privacidad-edad-fase3

**Generado:** 2026-07-01T05:28:16Z
**Fuente:** QA_CHECKLIST.md + PRD_NORMALIZED.md + handoffs/frontend.md + handoffs/qa.md
**Root Flutter (worktree):** /Users/cami/Developer/Personal/Rideglory/.claude/worktrees/legal-privacidad-edad-fase1

Este documento solo CLASIFICA. No se escribieron tests todavía (eso es el siguiente paso del pipeline rg-auto).

## Notas de contexto relevantes para la clasificación

- Fase 3 ya está commiteada en el worktree (commit `6f61ba8`), sin UI nueva: solo domain/data/constants + 1 línea en `registration_detail_page.dart` + ajustes internos de `registration_form_cubit.dart`.
- `RegistrationDetailPage` es un `StatelessWidget` que recibe `params.registration` directamente (no cubit para los datos de la fila de tipo de sangre) → renderizable en widget test con mocks, sin backend.
- `_preloadFromExistingRegistration` / `_buildRegistration` en `RegistrationFormCubit` son lógica pura invocable sin UI → unit/bloc_test.
- No existe infraestructura Patrol para el flujo de inscripción (wizard completo) en `integration_test/` — solo `events_patrol_test.dart` para eventos, sin cobertura de registro/inscripción.
- Ya existen los 3 tests de DTO nuevos (`event_registration_dto_test.dart`, `event_dto_test.dart`, `user_dto_test.dart`) y `registration_form_fields_test.dart`, cubriendo AC#1-6 del PRD — la sección 6 técnica es en su mayoría `run-existing` (comandos explícitos en el checklist).

## Casos que NO se pueden clasificar como test automatizado nuevo (ya cubiertos por el propio checklist como comandos)

6.1, 6.2, 6.3, 6.4 son comandos explícitos → `run-existing`.
6.5, 6.6, 6.7, 6.8 son inspecciones de código/red → mezcla de `run-existing` (grep) y `manual`/`cannot` (inspección de .g.dart, inspección de payload de red real).

Ver detalle caso por caso en la salida estructurada del agente.
