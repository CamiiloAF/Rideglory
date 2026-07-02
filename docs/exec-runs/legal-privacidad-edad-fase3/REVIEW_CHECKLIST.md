# Review Checklist — legal-privacidad-edad-fase3

Pasos manuales para el humano antes de commitear.

## 1. Diff review
- [ ] `git diff --stat` — confirmar que solo aparecen los 9 archivos de `lib/` listados en
      `SUMMARY.md` (más los 4 archivos de test nuevos bajo `test/`).
- [ ] `git status` — confirmar que **no** aparecen los `.g.dart` (están gitignorados; si aparecen,
      revisar `.gitignore`, no commitearlos).
- [ ] `git status` — confirmar que **no** aparecen cambios en `docs/PRD.md`, `docs/PLAN.md`,
      `docs/PRODUCT_STATUS.md`, `docs/handoffs/**`, `.claude/**`.

## 2. Build & lint
- [ ] `dart run build_runner build --delete-conflicting-outputs` — debe correr limpio (0
      conflictos). Si falla, correr `dart run build_runner clean` primero.
- [ ] `dart analyze` — 0 errores. Los 6 `info` preexistentes (curly braces en
      `custom_route_builder_section.dart`, underscores en dos test files de otro feature) son
      aceptables y no están relacionados con esta fase.

## 3. Tests
- [ ] `flutter test test/features/event_registration/data/dto/event_registration_dto_test.dart test/features/events/data/dto/event_dto_test.dart test/features/users/data/dto/user_dto_test.dart test/features/event_registration/constants/registration_form_fields_test.dart`
      → deben pasar 12/12.
- [ ] `flutter test` (suite completa) → debe pasar 100% (901 tests al momento de esta revisión).

## 4. Verificación de contrato (manual, opcional pero recomendado)
- [ ] Confirmar contra `rideglory-api` (Fase 1) que los nombres JSON exactos siguen siendo:
      `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion`,
      `organizerAcceptedResponsibilityAt`, `sosTriggeredAt`, `medicalConsentAcceptedAt` — sin
      cambios desde que el architect los verificó.
- [ ] Confirmar que `_BloodTypeConverter` sigue aplicado a nivel de clase en
      `event_registration_dto.dart` y que el `.g.dart` regenerado localmente usa
      `const _BloodTypeConverter().fromJson(...)` (no el enum decoder automático). Ver nota de
      desviación en `SUMMARY.md`.

## 5. Grep de regresión
- [ ] `grep -rn '\.bloodType\b' lib/ | grep -v '\.g\.dart'` — todos los call-sites deben usar
      `?.`/`!`/guard de null; único punto no-null-safe corregido:
      `registration_detail_page.dart:128` → `registration.bloodType?.label ?? ''`.
- [ ] `grep -n 'bloodTypeRaw' lib/` — no debe encontrar nada (guardrail: no se agrega respaldo
      `String?`).

## 6. Commit
- [ ] Una vez todo lo anterior en verde, commitear con el mensaje sugerido en `SUMMARY.md`
      (o uno equivalente que describa la extensión de modelos/DTOs legales).
- [ ] No incluir en el commit ningún `.g.dart` (deben permanecer gitignorados/locales).
