# REVIEW_CHECKLIST — eliminacion-cuenta-phase-03

_Generado: 2026-07-10T20:22:30Z_

Pasos manuales que el humano debe correr antes de commitear. El working tree queda sucio a
proposito (Flutter en `Rideglory` + 3 submodulos en `rideglory-api`: `events-ms`, `api-gateway`,
`rideglory-contracts`).

## 1. Revision de diffs

- [ ] `git diff --stat` en `Rideglory` (10 archivos) y en cada submodulo de `rideglory-api`
      (`events-ms` 3, `api-gateway` 4, `rideglory-contracts` 1) — confirmar que coincide con la
      lista de "Archivos" en `SUMMARY.md`.
- [ ] Confirmar que **no** se tocaron `docs/PRD.md`, `docs/PLAN.md`, `docs/PRODUCT_STATUS.md`,
      `docs/handoffs/**` ni `.claude/**`.

## 2. Backend — build y contracts

- [ ] `rideglory-contracts`: `npm run build` (ya corrido por Backend; re-verificar si se editan
      DTOs despues de este punto).
- [ ] Tras cualquier edicion adicional de `rideglory-contracts`, `npm install` en la raiz del
      monorepo para relinkear `@rideglory/contracts` en `events-ms`/`api-gateway` (gotcha
      conocido — ver `project_contracts_rebuild_gotcha.md`).
- [ ] `events-ms`: `npm run build` (tsc) sin errores.
- [ ] `api-gateway`: `npm run build` (tsc) sin errores.
- [ ] `events-ms`: `npm test` completo -> verde (verificado: 7 suites / 55 tests).
- [ ] `api-gateway`: `npm test` completo -> confirmar que sigue en **16/17 suites, 143/151
      tests** con la unica suite roja preexistente y no relacionada (`places.service.iter3.spec.ts`,
      falta `MAPBOX_ACCESS_TOKEN` en Jest) — no debe haber suites rojas nuevas.
- [ ] `users-ms` y `vehicles-ms`: `npm test` -> verde tras el relink de contracts (reportado 6/6
      y 50/50 por Backend; no re-verificado por Tech Lead — correr antes de commitear).

## 3. Backend — migracion Prisma (CRITICO, no automatizable con seguridad)

- [ ] Revisar a mano `events-ms/prisma/migrations/20260710194244_registration_nullable_pii/migration.sql`
      — confirmar que **solo** contiene `ALTER TABLE ... DROP NOT NULL` para las 8 columnas
      listadas (no debe haber `DROP COLUMN`, `DROP TABLE`, ni cambios sobre `bloodType`/`fullName`).
- [ ] Fue escrita a mano (no generada por `prisma migrate dev`) por un drift preexistente en 2
      migraciones ajenas a esta fase — confirmar que ese drift sigue siendo ajeno antes de aplicar
      en cualquier entorno compartido.
- [ ] **No desplegar a produccion sin verificacion humana explicita** (flujo de deploy ya
      establecido del proyecto — correr y verificar localmente primero).
- [ ] Si se aplica en un entorno compartido (staging), verificar contra datos reales que ninguna
      fila existente se corrompe (`SELECT count(*) WHERE <campo> IS NULL` antes/despues).

## 4. Frontend — Flutter

- [ ] `dart run build_runner build --delete-conflicting-outputs` (regenerar `.g.dart` de
      `EventRegistrationDto` si se toca de nuevo tras este review).
- [ ] `dart analyze` completo del proyecto (Tech Lead solo corrio el analizador sobre las
      carpetas tocadas: `lib/features/event_registration`, `lib/features/profile`, `lib/l10n` — 0
      issues nuevos, 1 preexistente y ajeno en `profile_page.dart`).
- [ ] `flutter test` completo del proyecto (Tech Lead solo corrio los 4 archivos tocados/nuevos —
      24/24 pass).
- [ ] Confirmar visualmente en el simulador/emulador: tap en "Eliminar cuenta" con un usuario
      organizador de un evento `DRAFT`/`SCHEDULED`/`IN_PROGRESS` (usuario de prueba
      `qa2@gmail.com`, dueño de "Mi Evento" — ver `project_qa_test_users.md`) muestra el bottom
      sheet de bloqueo, no la pantalla de confirmacion de fase 1.

## 5. QA end-to-end (recomendado antes de desplegar)

- [ ] AC5: `DELETE /users/me` para un organizador con eventos activos responde 409 con
      `activeEvents` no vacio y **ningun** paso de borrado se ejecuto (verificar en BD que
      vehiculos/EventRegistration/usuario no cambiaron).
- [ ] AC6-AC8: tras un borrado exitoso de un rider con inscripciones, verificar directamente en
      la BD de `events-ms` (no solo UI) que los 8 campos PII son `null`, `fullName = 'Usuario
      eliminado'`, y que `riskAcceptedAt`/`riskAcceptanceVersion`/`medicalConsentAcceptedAt`/
      `medicalConsentVersion` **no cambiaron**.
- [ ] AC9: en `AttendeesList` de un evento con un inscrito de cuenta eliminada, el nombre muestra
      "Usuario eliminado" sin crash.
- [ ] AC10: en `RegistrationDetailPage` de esa misma inscripcion, los 8 campos muestran "Cuenta
      eliminada", incluyendo `birthDate`.

## 6. Commit

- [ ] Confirmar que ningun archivo con secretos/credenciales quedo en el stage (`.env`,
      `google-services.json`, etc. — no deberian aparecer en este diff).
- [ ] Commitear por separado en cada repo (`Rideglory` y cada submodulo de `rideglory-api` que
      tenga cambios: `events-ms`, `api-gateway`, `rideglory-contracts`) siguiendo el flujo normal
      de submodulos (commit en el submodulo primero, luego actualizar el puntero en el super-repo
      si aplica).
