# Resultados de automatización QA — eliminacion-cuenta-phase-03

_Generado por qa-automator: 2026-07-11T15:04:13Z_

Corrida de `qa-auto` sobre los 27 casos automatizables listados para esta fase. Ver
`QA_CHECKLIST.md` (columna ✅/❌ anotada con "✅ (auto)" en las filas cubiertas) para el
checklist tri-estado completo, incluyendo los casos que siguen pendientes de verificación
manual/BD real (3.2, 6A.1, 7.3-7.6, 7.8-7.10 — sin cambios, fuera del alcance de esta corrida).

## Resumen

- 27/27 casos evaluados. **26 auto-pass**, **1 no-auto** (7.2 — ver nota).
- 2 archivos de test **nuevos** (widget), reusando patrones existentes (mocktail, MaterialApp +
  AppLocalizations, sin helpers inventados).
- Todos los demás casos son `run-existing`: se re-ejecutó el test/comando real que ya cubría el
  caso (no se escribió test nuevo), tal como indica la regla del prompt.
- `flutter test` de los archivos tocados/reusados: **33 + 24 = 57 tests, 0 fallos** (dos corridas,
  ver `commandsRun`).
- `dart analyze` (proyecto completo): **0 errores**, 15 `info` preexistentes (mismo baseline
  documentado en `handoffs/frontend.md`/`handoffs/qa.md`, ninguno nuevo).
- `dart analyze` sobre los 3 archivos de test tocados: limpio.
- Backend: `account-deletion.service.spec.ts` 11/11 pass; `registrations.service.anonymization.spec.ts`
  7/7 pass.

## Archivos de test escritos/modificados

- `test/features/events/presentation/attendees/widgets/attendees_list_navigation_test.dart`
  — nuevo caso `AC9: renders a registration with fullName="Usuario eliminado" without crashing`
  (cubre 4.1).
- `test/features/event_registration/presentation/registration_detail_page_test.dart`
  — nuevo grupo `RegistrationDetailPage — masking regression (eliminacion-cuenta-phase-03,
  masking != anonymization)` con el caso `shareMedicalInfo=false con campos enmascarados
  ("••••") no muestra el placeholder de cuenta eliminada` (cubre 4.11).

Ningún archivo de `lib/` fue tocado. Ningún comando de git fue ejecutado.

## Nota sobre 7.2 (no-auto)

El caso 7.2 pide "consulta BD de vehicles-ms/events-ms/users-ms" tras el 409 de 7.1. El spec
`account-deletion.service.spec.ts` verifica a nivel de **mocks** que, tras el 409, cero llamadas
se hacen a los pasos de borrado (vehicles/events/users) — es una prueba indirecta y fuerte a
nivel de lógica de orquestación, pero **no** es una consulta real contra una base de datos. Este
agente QA no tiene acceso a una BD Postgres compartida en este entorno, así que no puede
ejecutar la verificación literal que pide el caso. Se marca `no-auto` (no se fuerza un
falso-verde); la cobertura por mocks ya existente se reporta como respaldo indirecto en
`caseResults`.

## Detalle por caso

Ver `caseResults` en la salida estructurada de esta corrida para el mapeo completo id → test →
estado → nota.
