# REVIEW_CHECKLIST — waiver-inscripcion-registro

Pasos manuales antes de commitear (working tree queda sucio a propósito).

## 1. Decisiones abiertas — RESUELTAS en esta ronda (re-revisión)

- [x] **Copy del CTA del waiver.** Confirmado en `git diff` de `lib/l10n/app_es.arb`:
      `registration_waiverCtaButton` ahora es "Entiendo, inscribirme", cumpliendo el AC#4/#6
      literal del PRD.
- [x] **Botón "Cancelar" del waiver.** Confirmado en `registration_waiver_step.dart`: el botón
      "Cancelar" ahora usa `AppButton(style: AppButtonStyle.outlined, shape: AppButtonShape.pill)`
      — el mismo componente que "Atrás" en `RegistrationWizardNavigationBar`. El test
      `registration_waiver_step_test.dart` lo verifica explícitamente
      (`find.byType(AppButton), findsNWidgets(2)); find.byType(AppTextButton), findsNothing`).

Nota (no bloqueante): `design.md` (tabla "Copy", línea ~154) aún tiene una frase desactualizada
que describe "Cancelar" como `AppTextButton`, contradiciendo su propia sección "Fix pass" más
arriba en el mismo archivo. Es un desfase de documentación, no de código; conviene corregirlo la
próxima vez que se edite ese handoff.

## 2. Verificación técnica (re-ejecutada por Tech Lead en esta ronda)

- [x] `dart analyze` (repo completo) → No issues found!
- [x] `flutter test test/features/event_registration/` → **All tests passed!** (incluye los 3
      archivos nuevos y los 3 modificados de esta fase, y el test actualizado del botón
      "Cancelar").
- [ ] `flutter test` (suite completa del repo) — QA reportó 944/944 en la ronda anterior; no se
      re-corrió la suite completa en esta ronda (solo se tocó el ARB y
      `registration_waiver_step.dart`/su test desde entonces, ambos ya verificados arriba).
      Recomendable correrla una última vez antes de `git commit` si el tiempo lo permite.

## 3. Verificación manual en dispositivo/simulador (pendiente, según QA)

- [ ] Flujo feliz: completar los 5 pasos, aceptar el waiver, confirmar que la inscripción se
      envía con `shareMedicalInfo`/`allowOrganizerContact` según lo marcado.
- [ ] Rider menor de 18 años → al tocar el CTA del waiver debe verse "No cumples la edad mínima"
      + mensaje fijo, sin botón "Ir a mi perfil".
- [ ] Editar una inscripción existente → switches de privacidad precargados con su valor real.
- [ ] Confirmar que la barra de navegación inferior del wizard NO aparece en el paso waiver (ni
      duplicada ni superpuesta con los botones internos del waiver).
- [ ] `UNDERAGE_RIDER` real del backend (422, edge case de reloj/zona horaria) → debe verse el
      mismo bloque "No cumples la edad mínima" (ya cubierto por test automatizado, pero conviene
      confirmar visualmente).

## 4. Antes de `git commit`

- [ ] Confirmar que `git status` no incluye archivos fuera de lo esperado (`lib/`, `test/`,
      `docs/exec-runs/waiver-inscripcion-registro/`).
- [ ] Confirmar que las 2 decisiones abiertas de la sección 1 quedaron resueltas y, si implicaron
      cambios de código, re-correr `dart analyze` + `flutter test` antes de commitear.
- [ ] Revisar que ninguna clave ARB nueva quedó sin usar (14 claves `registration_*` nuevas, todas
      referenciadas — verificado por Tech Lead vía grep).
