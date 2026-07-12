# REVIEW_CHECKLIST — eliminacion-cuenta-phase-04

_Generado: 2026-07-11T18:15:28Z_

Pasos manuales para el humano antes de commitear.

## 1. Separar commits (working tree mezclado)

Este working tree acumula cambios de varias corridas. Antes de commitear, dividir en commits
independientes:

- [ ] Commit A (Flutter, fase-04): `lib/core/http/firebase_auth_interceptor.dart`,
      `lib/l10n/app_es.arb`, `lib/l10n/app_localizations.dart`,
      `lib/l10n/app_localizations_es.dart`, `lib/features/users/data/repository/user_repository_impl.dart`,
      `test/core/http/firebase_auth_interceptor_test.dart`, `docs/architecture/DIAGRAMS.md`.
- [ ] Commit(s) en `rideglory-api` (por submódulo, fase-04): `api-gateway` (2 archivos + specs),
      `users-ms` (1 archivo + spec), `vehicles-ms` (spec-only), `events-ms` (spec-only).
- [ ] Commit B (fuera de fase-04, ya presente en el tree): fix de race de Mapbox
      (`lib/core/services/crash/crash_handler_setup.dart`, `lib/main.dart`,
      `test/core/services/crash/crash_handler_setup_test.dart`) — evaluar si ya fue commiteado en
      otra corrida antes de duplicar.
- [ ] Commit C (fuera de fase-04): ajuste de `integration_test/registration_patrol_test.dart`
      (`waitUntilVisible` → `waitUntilExists`) y los tests de regresión de
      `registration_detail_page_test.dart` / `attendees_list_navigation_test.dart`.
- [ ] Commit D (fuera de fase-04): actualizaciones de `QA_CHECKLIST.md` de fase-02/03 y sus
      artefactos QA nuevos (`PREFLIGHT.md`, `QA_AUDIT_OPUS.md`, `QA_AUTO_REPORT.md`,
      `QA_REGRESSION_*.md`, `QA_AUTOMATION_RESULTS.md`, `REGRESSION_*.md`).

## 2. Verificación local antes de commitear

- [ ] `dart run build_runner build --delete-conflicting-outputs` (o `flutter gen-l10n`) si se
      vuelve a tocar `app_es.arb`, para confirmar que `app_localizations*.dart` quedan sincronizados.
- [ ] `flutter test test/core/http/firebase_auth_interceptor_test.dart` → 5/5 verde.
- [ ] `flutter test` completo → sin regresiones (1406/1406 esperado).
- [ ] `dart analyze` → 0 issues nuevos en los archivos tocados de esta fase.
- [ ] Backend: `npx jest` en `api-gateway`, `users-ms`, `vehicles-ms`, `events-ms` → verde (los 8
      fallos preexistentes de `PlacesService` en `api-gateway` no están relacionados, confirmar que
      siguen siendo exactamente esos 8).

## 3. Pruebas manuales pendientes (staging) — bloquean el cierre COMPLETO de la fase, no el merge

- [ ] **AC1**: cerrar la app (o perder conexión) antes de que `DELETE /users/me` llegue al backend;
      reabrir; confirmar que el usuario sigue autenticado y puede reiniciar el borrado desde cero.
- [ ] **AC2**: iniciar `DELETE /users/me` y cortar el socket del cliente a mitad de la petición;
      confirmar en BD de staging que los 8 pasos de la orquestación se completaron igual.
- [ ] **AC3 end-to-end**: con `qa1@gmail.com` ya borrado por completo (incluido Firebase Auth),
      forzar una llamada autenticada desde una sesión vieja; confirmar snackbar exacto "Tu sesión
      terminó, inicia sesión de nuevo." + redirect automático a `/login`.
- [ ] **AC5 en BD real**: disparar dos `DELETE /users/me` superpuestas contra staging con el mismo
      `uid`; verificar en BD (no solo por la respuesta HTTP) que no quedan filas huérfanas ni
      duplicadas.
- [ ] Confirmar que `qa2@gmail.com` (organizador de "Mi Evento") sigue bloqueado por el `409` de
      precondición existente (guardrail de contrato, no se debe romper).

## 4. Higiene del repo backend

- [ ] Revisar y descartar (o `.gitignore`) los `.DS_Store` sin trackear en `rideglory-api`
      (raíz, `docs/`, `terraform/`) — no relacionados con esta fase.
- [ ] Confirmar que `rideglory-common-lib` y `rideglory-contracts` (marcados "untracked content"
      por git en el super-repo) no tienen cambios relevantes de esta fase antes de ignorarlos.
